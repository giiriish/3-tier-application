pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'
    }

    options {
        timestamps()
    }

    stages {

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        terraform init
                        '''
                    }
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        terraform plan
                        '''
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        terraform apply -auto-approve
                        '''
                    }
                }
            }
        }

        stage('Fetch Details') {
            steps {
                script {
                    env.WEB_IP = sh(
                        script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    env.APP_ID = sh(
                        script: "cd ${TF_DIR} && terraform output -raw app_instance_id",
                        returnStdout: true
                    ).trim()

                    echo "Web IP: ${env.WEB_IP}"
                    echo "App Instance ID: ${env.APP_ID}"
                }
            }
        }

        stage('Create Inventory') {
            steps {
                script {
                    writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
[web]
${env.WEB_IP} ansible_user=ec2-user

[app]
${env.APP_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=${env.AWS_DEFAULT_REGION} ansible_aws_ssm_bucket_name=last-one-1 ansible_python_interpreter=/usr/bin/python3
"""
                }
            }
        }

        stage('Wait for EC2') {
            steps {
                echo "Waiting for EC2 instances..."
                sh 'sleep 60'
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY_FILE'),
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                   sh '''
cd ansible

export PATH=/usr/bin:/usr/local/bin:${env.PATH}

chmod 400 $KEY_FILE
export ANSIBLE_HOST_KEY_CHECKING=False

echo "===== Web Tier (SSH) ====="
ansible-playbook -i inventory.ini web.yml --private-key $KEY_FILE

echo "===== App Tier (SSM) ====="
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

ansible-playbook -i inventory.ini app.yml
'''
                }
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful!"
        }
        failure {
            echo "❌ Deployment Failed!"
        }
    }
}
