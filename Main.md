pipeline { agent any

environment { SOURCE_URL = 'Env A' TARGET_URL = 'Enn B' APP_UUID = 'Application UUID'

SOURCE_API_KEY = credentials('APPIAN_API_KEY')
TARGET_API_KEY = credentials('TARGET_API_KEY')
}
stages {
    {ExportApplication.md}
    {pollExportStatus.md}
    {
        downloadArtifacts.md
    }
    {
        inspectPackage.md
    }
    {
        validateInspection.md
    }
    {
        importToEnvB.md
    }
    {
        importStatus.md
    }

    
}