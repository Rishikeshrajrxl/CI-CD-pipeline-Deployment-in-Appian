// 🔁 POLL IMPORT STATUS
stage('Poll Import Status') { steps { sh ''' IMPORT_UUID=$(jq -r '.uuid' import_response.json)

if [ "$IMPORT_UUID" = "null" ] || [ -z "$IMPORT_UUID" ]; then
  echo "❌ Import failed"
  cat import_response.json
  exit 1
fi

echo "Import UUID: $IMPORT_UUID"

STATUS="IN_PROGRESS"
MAX_RETRIES=60
COUNT=0

while true; do
  sleep 10

  RESPONSE=$(curl -s "$TARGET_URL/suite/deployment-management/v2/deployments/$IMPORT_UUID" \
  -H "appian-api-key: $TARGET_API_KEY")

  STATUS=$(echo $RESPONSE | jq -r '.status')

  echo "Import Status: $STATUS"

  # ✅ SUCCESS CASE
  if [ "$STATUS" = "COMPLETED" ]; then
    echo "🎉 DEPLOYMENT SUCCESSFUL"
    break
  fi

  # ❌ FAIL CASES (STRICT)
  if [ "$STATUS" = "FAILED" ] || \
     [ "$STATUS" = "COMPLETED_WITH_WARNINGS" ] || \
     [ "$STATUS" = "COMPLETED_WITH_ERRORS" ]; then
    echo "❌ Deployment NOT successful: $STATUS"
    echo $RESPONSE
    exit 1
  fi

  # ⏳ TIMEOUT SAFETY
  COUNT=$((COUNT+1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "❌ Timeout waiting for deployment"
    exit 1
  fi
done
'''
} } }