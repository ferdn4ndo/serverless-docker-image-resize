# variables
stage=${STAGE}
region=${REGION}
bucket=${BUCKET}
secrets='/deploy/secrets/secrets.json'

echo "------------------"
echo 'Configuring SLS and Default profile...'
echo "------------------"
# Configure your Serverless installation to talk to your AWS account
sls config credentials \
  --overwrite \
  --provider aws \
  --key ${SLS_KEY} \
  --secret ${SLS_SECRET} \
  --profile serverless-admin

# Add the credentials to the Default profile
echo "
[default]
aws_access_key_id=${SLS_KEY}
aws_secret_access_key=${SLS_SECRET}
" >> ~/.aws/credentials

# cd into functions dir
cd /deploy/functions

# Deploy functions
echo "------------------"
echo 'Deploying function...'
echo "------------------"
sls deploy

# find and replace the service endpoint
if [ -z ${stage+dev} ]; then echo "Stage is unset."; else echo "Stage is set to '$stage'."; fi

sls info -v | grep ServiceEndpoint > domain.txt
sed -i 's@ServiceEndpoint:\ https:\/\/@@g' domain.txt
sed -i "s@/$stage@@g" domain.txt
domain=$(cat domain.txt)
sed "s@.execute-api.$region.amazonaws.com@@g" domain.txt > id.txt
id=$(cat id.txt)

echo "------------------"
echo "Domain:"
echo "  $domain"
echo "------------------"
echo "API ID:"
echo "  $id"

rm domain.txt
rm id.txt

if [ ! "$domain" ];then
  echo "Domain is empty!"
  echo "{}" > $secrets
else
  echo "Domain is not empty!"
  echo "{\"DOMAIN\":\"$domain\"}" > $secrets
fi

cd /deploy/bucket

# Deploy bucket config
echo "------------------"
echo 'Deploying bucket...'
sls deploy

echo "------------------"
echo 'Bucket endpoint:'
echo "  http://$bucket.s3-website.$region.amazonaws.com/"

echo "------------------"
echo "Service deployed. Press CTRL+C to exit."
