// 🔍 INSPECT PACKAGE
stage('Inspect Package') { steps { sh ''' curl -s -X POST "$TARGET_URL/suite/deployment-management/v2/inspections"
-H "appian-api-key: $TARGET_API_KEY"
-F "zipFile=@artifact.zip"
-F 'json={"packageFileName":"artifact.zip"}'
> inspection.json

echo "Inspection Result:"
cat inspection.json
'''
} }