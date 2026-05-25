// 🟢 DOWNLOAD ARTIFACT
stage('Download Package') { steps { sh ''' DEPLOYMENT_UUID=$(cat dep_uuid.txt)

echo "Fetching deployment details..."

RESPONSE=$(curl -s "$SOURCE_URL/suite/deployment-management/v2/deployments/$DEPLOYMENT_UUID" \
-H "appian-api-key: $SOURCE_API_KEY")

echo $RESPONSE > deployment_details.json

DOWNLOAD_URL=$(echo $RESPONSE | jq -r '.packageZip')

if [ "$DOWNLOAD_URL" = "null" ] || [ -z "$DOWNLOAD_URL" ]; then
  echo "❌ packageZip URL not available"
  cat deployment_details.json
  exit 1
fi

echo "Download URL: $DOWNLOAD_URL"

curl -L -o artifact.zip "$DOWNLOAD_URL" \
-H "appian-api-key: $SOURCE_API_KEY"

echo "File size:"
ls -lh artifact.zip
'''
} }
