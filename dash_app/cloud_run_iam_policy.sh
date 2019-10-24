export GCLOUD_PROJECT_NAME="iconic-range-220603"
export BIGTABLE_CLUSTER="iot-stream-database"
export TABLE_NAME="iot-stream-table"
export CLOUD_REGION="global"
export IOT_REGISTRY="iot-registry"
export ROW_FILTER=2
export KEY_RING_ID="cloud-run-keyring"
export CRYPTO_KEY_ID="test-ring"
export GOOGLE_APPLICATION_CREDENTIALS="/Users/sungwon.chung/Desktop/repos/serverless-dash-webapp/service_account.json"
export GOOGLE_APP_CREDENTIALS="CiQA50Ad3WaKLGR3xlIgKzNz7caas4ceMEtfnote43POiHAQkV8SQACvmJFehfFm/gdai0gBG5HsVXdOyz+h13UtdIHMLS0LzP/atcZnsdtSKyBP2qV2mgZwnqzOs8EM7GID09p3YB4="


# steps to encrypt private key for cloud run
# https://stackoverflow.com/questions/48602546/google-cloud-functions-how-to-securely-store-service-account-private-key-when

# https://cloud.google.com/kms/docs/secret-management#choosing_a_secret_management_solution
# TODO: can add the below scripts to a single script with file argument

# delete the bucket as needed
gsutil rm -r gs://secure-bucket-cloud-run

# create a keyring
gcloud kms keyrings create cloud-run-keyring \
--location=global

#create a key
gcloud kms keys create iot-python-webapp-key \
--purpose=encryption \
--location=global \
--keyring=cloud-run-keyring \
--protection-level=software

#encrypt file using KMS
# https://cloud.google.com/sdk/gcloud/reference/kms/encrypt
gcloud kms encrypt \
--key=iot-python-webapp-key \
--keyring=cloud-run-keyring \
--location=global \
--plaintext-file=/Users/sungwon.chung/Desktop/repos/serverless-dash-webapp/tf_modules/service_account.json \
--ciphertext-file=ciphertext_file.enc

# Copy encrypted file to cloud storage bucket
gsutil cp ciphertext_file.enc gs://secure-bucket-cloud-run

# list objects in bucket
gsutil ls -r gs://secure-bucket-cloud-run

#decrypt file using KMS
gcloud kms decrypt \
--key=iot-python-webapp-key \
--keyring=cloud-run-keyring \
--location=global \
--plaintext-file=testFile.json \
--ciphertext-file=gs://secure-bucket-cloud-run/ciphertext_file

#tag image for google container registry
# docker tag <image-id> gcr.io/<project-id>/<image-name>
# docker tag 5427d9091df4 gcr.io/iconic-range-220603/dash-cloudrun-demo

#push image to google container registry
# docker push gcr.io/<project-id>/<image-name>
# docker push gcr.io/iconic-range-220603/dash-cloudrun-demo

#add parameters as part of deployment
# startup_script.sh for your_username="realsww123" and projectid=iot-python-webapp-demo
# variables.tf for project_id and service_account_email for terraform deployment
# backend.tf for bucket name
# use a random number generator similar to the startup script to create dynamic crypto key rings
# shell script for project id and service account
# cloud run image name

# download locally
# gcloud iam service-accounts keys create ~/Desktop/repos/serverless-dash-webapp/service_account.json \
# --iam-account demo-service-account@iot-python-webapp-demo.iam.gserviceaccount.com

# move the service account key to the repo
# note: it'll be ignored
# mv service_account.json ~/iot-python-webapp

# terraform deployment
terraform init
terraform plan
terraform apply

#######################
# ad hoc push to container registry from dockerfile at root directory
gcloud builds submit --tag gcr.io/iot-python-webapp-demo/dash-cloudrun-demo

# deploy infrastructure
terraform apply

# https://cloud.google.com/run/docs/authenticating/public
# make cloud run public
gcloud beta run services add-iam-policy-binding tf-dash-cloud-run-demo \
--member="allUsers" \
--role="roles/run.invoker" \
--region="us-central1"

#adjust memory limit
gcloud beta run services update tf-dash-cloud-run-demo --memory 1Gi --platform managed --region us-central1


# destroy iot devices
for i in {1..3}
do
    device_id=$(gcloud iot devices list --registry=iot-registry --region=us-central1 | grep -v "^ID"  | shuf -n 1 | awk '{print $2}')
    gcloud iot devices delete "$device_id" --registry=iot-registry --region=us-central1 --quiet
done

#destroy everything else
terraform destroy

#adjust key ring name to another version name


# terraform destroy -target google_cloud_run_service.tf-dash-cloud-run-demo

# cloud run example
gcloud beta run deploy iot-python-webapp --platform managed --image gcr.io/iconic-range-220603/dash-demo-v2:latest --region us-central1 --allow-unauthenticated --set-env-vars=GCLOUD_PROJECT_NAME="iconic-range-220603",BIGTABLE_CLUSTER="iot-stream-database",TABLE_NAME="iot-stream-table",CLOUD_REGION="us-central1",IOT_REGISTRY="iot-registry",ROW_FILTER=2

