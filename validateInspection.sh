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
