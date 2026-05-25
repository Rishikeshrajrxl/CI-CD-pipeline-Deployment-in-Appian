// 🟡 POLL EXPORT STATUS
stage('Poll Export Status') {
  steps {
    sh '''
    DEPLOYMENT_UUID=$(jq -r '.uuid' export_response.json)

    if [ "$DEPLOYMENT_UUID" = "null" ] || [ -z "$DEPLOYMENT_UUID" ]; then
      echo "❌ Export failed"
      cat export_response.json
      exit 1
    fi

    echo "Export UUID: $DEPLOYMENT_UUID"

    STATUS="IN_PROGRESS"

    while [ "$STATUS" != "COMPLETED" ]; do
      sleep 10

      RESPONSE=$(curl -s "$SOURCE_URL/suite/deployment-management/v2/deployments/$DEPLOYMENT_UUID" \
      -H "appian-api-key: $SOURCE_API_KEY")

      STATUS=$(echo $RESPONSE | jq -r '.status')

      echo "Export Status: $STATUS"

      if [ "$STATUS" = "FAILED" ]; then
        echo "❌ Export FAILED"
        echo $RESPONSE
        exit 1
      fi
    done

    echo $DEPLOYMENT_UUID > dep_uuid.txt
    '''
  }
}