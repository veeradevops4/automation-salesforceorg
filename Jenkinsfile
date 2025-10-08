pipeline {
    agent any


//     withCredentials([
//         file(credentialsId: 'SFDX_JWT_KEY', variable: 'JWT_KEY_FILE'),
//         string(credentialsId: 'SFDX_CLIENT_ID', variable: 'SFDX_CLIENT_ID'),
//         string(credentialsId: 'SFDX_HUB_ORG_DH', variable: 'SFDX_HUB_ORG_DH'),
//         string(credentialsId: 'SFDC_HOST_DH', variable: 'SFDC_HOST_DH')
// ])

    environment {
        // Salesforce environment variables
        SFDX_CLIENT_ID     = credentials('SFDX_CLIENT_ID')
        SFDX_HUB_ORG_DH    = credentials('SFDX_HUB_ORG_DH') // can be alias or username
        SFDX_JWT_KEY       = credentials('SFDX_JWT_KEY') // private key for JWT auth
        SFDC_HOST_DH       = credentials('SFDC_HOST_DH')
    //     Your JFrog Artifactory base URL
    //     ARTIFACTORY_URL = 'http://localhost:8082'

    //   // The repo in Artifactory where you want to upload
    //     ARTIFACTORY_REPO = 'salesforce-generic-local' // e.g., generic-local for generic repos
    //   // Jenkins credentials IDs for Artifactory username and password/API key
    //     // SALESFORCE_GENERIC_TOKEN = credentials('salesforce-generic-token')
    //    // Name of the Salesforce metadata ZIP file to upload
    //     REPORT_FILE = 'reports/output-report.html'  
        // Target path inside Artifactory repo (can be empty or a folder path)
        // TARGET_PATH = 'salesforce/'
        // NEXUS_URL = 'http://54.234.105.54:8081/repository/sfdx/'
        // NEXUS_CREDENTIALS = credentials('nexus-creads') // Jenkins credentials ID


        // SFDX_ORG_ALIAS     = 'myOrg' // You can use any alias
    }

    stages {
        stage('Checkout Source') {
            steps {
                checkout scm
            }
        }

        stage('Install Salesforce CLI') {
            steps {
                // sh 'npm install sfdx-cli --global'
                sh 'sf --version'
                // sh 'sfdx plugins:update'
                // sh 'sfdx plugins:install @salesforce/sfdx-scanner'
                // sh 'jfrog --version'
                  
            }
        }
        

        stage('Authenticate with Salesforce org') {
            steps {
                withCredentials([file(credentialsId: 'SFDX_JWT_KEY', variable: 'JWT_KEY_FILE')]) {
                    sh '''
                        echo "Authenticating to Salesforce..."
                        sfdx auth:jwt:grant \
                            --client-id $SFDX_CLIENT_ID \
                            --jwt-key-file $SFDX_JWT_KEY \
                            --username $SFDX_HUB_ORG_DH \
                            --instance-url $SFDC_HOST_DH
                    '''
                }
            }
        }

        stage('deploy to salesforce org'){
            steps {
                 sh '''
                    sf project deploy start \
                        --source-dir force-app/main/default/settings \
                        --target-org $SFDX_HUB_ORG_DH \
                        --wait 10 \
                        --verbose
                '''
            }
        }
    }
}
        
