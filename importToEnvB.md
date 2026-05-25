// 🚀 IMPORT TO ENV B
stage('Deploy to Env B') { steps { sh ''' curl -s -X POST "$TARGET_URL/suite/deployment-management/v2/deployments"
-H "appian-api-key: $TARGET_API_KEY"
-H "Action-Type: import"
-F "zipFile=@artifact.zip"
-F 'json={ "name":"CI-CD Import", "description":"First deployment to Env B", "packageFileName":"artifact.zip" }'
> import_response.json

echo "Import Response:"
cat import_response.json
'''
} }