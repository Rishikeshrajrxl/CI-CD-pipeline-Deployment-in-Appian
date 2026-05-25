pipeline {
  agent any

  environment {
    SOURCE_URL = 'Env A'
    TARGET_URL = 'Enn B'
    APP_UUID   = 'Application UUID'

    SOURCE_API_KEY = credentials('APPIAN_API_KEY')
    TARGET_API_KEY = credentials('TARGET_API_KEY')
  }

  stages {

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

    // 🟢 DOWNLOAD ARTIFACT
stage('Download Package') {
  steps {
    sh '''
    DEPLOYMENT_UUID=$(cat dep_uuid.txt)

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
  }
}

    // 🔍 INSPECT PACKAGE
 stage('Inspect Package') {
  steps {
    sh '''
    curl -s -X POST "$TARGET_URL/suite/deployment-management/v2/inspections" \
    -H "appian-api-key: $TARGET_API_KEY" \
    -F "zipFile=@artifact.zip" \
    -F 'json={"packageFileName":"artifact.zip"}' \
    > inspection.json

    echo "Inspection Result:"
    cat inspection.json
    '''
  }
}

    // 🚨 VALIDATE INSPECTION
    stage('Validate Inspection') {
      steps {
        script {
          def result = readFile('inspection.json')

          if (result.contains('"error"')) {
            error("❌ Inspection FAILED. Fix issues in Env B.")
          } else {
            echo "✅ Inspection Passed"
          }
        }
      }
    }

    // 🚀 IMPORT TO ENV B
   stage('Deploy to Env B') {
  steps {
    sh '''
    curl -s -X POST "$TARGET_URL/suite/deployment-management/v2/deployments" \
    -H "appian-api-key: $TARGET_API_KEY" \
    -H "Action-Type: import" \
    -F "zipFile=@artifact.zip" \
    -F 'json={
      "name":"CI-CD Import",
      "description":"First deployment to Env B",
      "packageFileName":"artifact.zip"
    }' \
    > import_response.json

    echo "Import Response:"
    cat import_response.json
    '''
  }
}

    // 🔁 POLL IMPORT STATUS
  stage('Poll Import Status') {
  steps {
    sh '''
    IMPORT_UUID=$(jq -r '.uuid' import_response.json)

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
  }
}
  }
}
