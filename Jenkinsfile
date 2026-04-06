pipeline {
agent any

```
environment {
    TF_DIR      = 'terraform'
    ANSIBLE_DIR = 'ansible'
    AWS_DEFAULT_REGION = 'us-east-1'
}

options {
    disableConcurrentBuilds()
    timestamps()
}

stages {

    stage('Clean Workspace') {
        steps {
            cleanWs()
        }
    }

    stage('Checkout Code') {
        steps {
            checkout scm
        }
    }

    stage('Terraform Deploy') {
        steps {
            withCredentials([usernamePassword(
                credentialsId: 'aws-creds',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )]) {
                dir("${TF_DIR}") {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

                    terraform init -reconfigure
                    terraform validate
                    terraform apply -auto-approve -var-file="terraform.tfvars"
                    '''
                }
            }
        }
    }

    stage('Fetch Instance IDs') {
        steps {
            withCredentials([usernamePassword(
                credentialsId: 'aws-creds',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )]) {
                dir("${TF_DIR}") {
                    script {
                        env.WEB_ID = sh(
                            script: '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform output -raw web_instance_id
                            ''',
                            returnStdout: true
                        ).trim()

                        env.APP_ID = sh(
                            script: '''
                            export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                            export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                            terraform output -raw app_instance_id
                            ''',
                            returnStdout: true
                        ).trim()

                        echo "WEB_ID=${env.WEB_ID}"
                        echo "APP_ID=${env.APP_ID}"
                    }
                }
            }
        }
    }

    stage('Create Inventory (SSM)') {
        steps {
            script {
                writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
```

[web]
${env.WEB_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=${AWS_DEFAULT_REGION}

[app]
${env.APP_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=${AWS_DEFAULT_REGION}
"""
}
}
}

```
    stage('Debug Inventory') {
        steps {
            sh "cat ${ANSIBLE_DIR}/inventory.ini"
        }
    }

    stage('Wait for EC2 (SSM Ready)') {
        steps {
            echo "Waiting for EC2 instances to register with SSM..."
            sleep 90
        }
    }

    stage('Run Ansible (SSM)') {
        steps {
            withCredentials([usernamePassword(
                credentialsId: 'aws-creds',
                usernameVariable: 'AWS_ACCESS_KEY_ID',
                passwordVariable: 'AWS_SECRET_ACCESS_KEY'
            )]) {

                sh '''
```

C:\Windows\System32\wsl.exe bash -c "
cd /mnt/c/ProgramData/Jenkins/.jenkins/workspace/$JOB_NAME &&

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID &&
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY &&
export AWS_DEFAULT_REGION=us-east-1 &&

/home/girish/ansible-venv/bin/ansible-playbook -vvv 
-i ansible/inventory.ini ansible/web.yml &&

/home/girish/ansible-venv/bin/ansible-playbook -vvv 
-i ansible/inventory.ini ansible/app.yml
"
'''
}
}
}

```
    stage('Health Check') {
        steps {
            echo "✅ Deployment Completed Successfully"
        }
    }
}

post {
    success {
        echo '✅ Deployment Successful'
    }
    failure {
        echo '❌ Deployment Failed'
    }
    always {
        cleanWs()
    }
}
```

}
