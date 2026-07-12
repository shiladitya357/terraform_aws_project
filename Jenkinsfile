pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  parameters {
    choice(name: 'ENVIRONMENT', choices: ['dev', 'stage', 'prod'], description: 'Environment to manage.')
    string(name: 'AWS_REGION', defaultValue: 'us-east-1', description: 'AWS region for this stack.')
    choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'], description: 'Terraform operation.')
    string(name: 'STATE_BUCKET', defaultValue: '', description: 'Existing S3 bucket that stores Terraform state.')
    string(name: 'LOCK_TABLE', defaultValue: 'terraform-state-locks', description: 'Existing DynamoDB table used for state locking.')
    string(name: 'AWS_CREDENTIALS_ID', defaultValue: 'aws-terraform', description: 'Jenkins AWS credentials ID.')
    string(name: 'DB_PASSWORD_CREDENTIAL_ID', defaultValue: 'terraform-db-password', description: 'Jenkins Secret Text credential ID for the RDS password.')
  }

  environment {
    TF_IN_AUTOMATION = 'true'
    TF_INPUT         = 'false'
    TF_WORKING_DIR   = "environments/${params.ENVIRONMENT}/${params.AWS_REGION}"
    TF_STATE_KEY     = "three-tier/${params.ENVIRONMENT}/${params.AWS_REGION}/terraform.tfstate"
  }

  stages {
    stage('Check inputs') {
      steps {
        script {
          if (!params.STATE_BUCKET?.trim()) {
            error('STATE_BUCKET is required. Create it first with bootstrap-state or use an existing state bucket.')
          }
        }
        sh 'test -d "$TF_WORKING_DIR"'
        sh 'terraform version'
      }
    }

    stage('Terraform init and validate') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID]]) {
          dir("${env.TF_WORKING_DIR}") {
            sh '''
              terraform init -reconfigure \
                -backend-config="bucket=${STATE_BUCKET}" \
                -backend-config="key=${TF_STATE_KEY}" \
                -backend-config="region=${AWS_REGION}" \
                -backend-config="dynamodb_table=${LOCK_TABLE}" \
                -backend-config="encrypt=true"
              terraform fmt -check -recursive
              terraform validate
            '''
          }
        }
      }
    }

    stage('Terraform plan') {
      steps {
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID],
          string(credentialsId: params.DB_PASSWORD_CREDENTIAL_ID, variable: 'TF_VAR_db_password')
        ]) {
          dir("${env.TF_WORKING_DIR}") {
            script {
              def destroyOption = params.ACTION == 'destroy' ? '-destroy' : ''
              sh "terraform plan ${destroyOption} -out=tfplan"
            }
          }
        }
        stash includes: "${env.TF_WORKING_DIR}/tfplan", name: 'terraform-plan'
      }
    }

    stage('Approval') {
      when {
        expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
      }
      steps {
        input message: "Approve Terraform ${params.ACTION} for ${params.ENVIRONMENT}/${params.AWS_REGION}?", ok: 'Approve'
      }
    }

    stage('Terraform apply') {
      when {
        expression { params.ACTION == 'apply' || params.ACTION == 'destroy' }
      }
      steps {
        unstash 'terraform-plan'
        withCredentials([
          [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: params.AWS_CREDENTIALS_ID],
          string(credentialsId: params.DB_PASSWORD_CREDENTIAL_ID, variable: 'TF_VAR_db_password')
        ]) {
          dir("${env.TF_WORKING_DIR}") {
            sh 'terraform apply -auto-approve tfplan'
          }
        }
      }
    }
  }

  post {
    always {
      archiveArtifacts artifacts: '**/tfplan', allowEmptyArchive: true
      cleanWs(deleteDirs: true, notFailBuild: true)
    }
  }
}
