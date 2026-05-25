// 🔵 EXPORT FULL APPLICATION
stage('Export Application') {
  steps {
    sh '''
    curl -s -X POST "$SOURCE_URL/suite/deployment-management/v2/deployments" \
    -H "appian-api-key: $SOURCE_API_KEY" \
    -H "Action-Type: export" \
    -F 'json={
      "name":"CI-CD Export",
      "description":"First full application deployment",
      "uuids":["'$APP_UUID'"],
      "exportType":"application"
    }' \
    > export_response.json

    echo "Export Response:"
    cat export_response.json
    '''
  }
}