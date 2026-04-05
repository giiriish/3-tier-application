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
                    def web_ip = sh(
                        script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    def app_id = sh(
                        script: "cd ${TF_DIR} && terraform output -raw app_instance_id",
                        returnStdout: true
                    ).trim()

                    env.WEB_IP = web_ip
                    env.APP_ID = app_id

                    echo "Web IP: ${WEB_IP}"
                    echo "App Instance ID: ${APP_ID}"
                }
            }
        }

        stage('Create Inventory') {
            steps {
                script {
                    writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
[web]
${WEB_IP} ansible_user=ec2-user

[app]
${APP_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=${AWS_DEFAULT_REGION} ansible_aws_ssm_bucket_name=last-one-1 ansible_python_interpreter=/usr/bin/python3
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
                    sh """
                    cd ${ANSIBLE_DIR}

                    chmod 400 \$KEY_FILE
                    export ANSIBLE_HOST_KEY_CHECKING=False

                    echo "===== Web Tier (SSH) ====="
                    ansible-playbook -i inventory.ini web.yml --private-key \$KEY_FILE

                    echo "===== App Tier (SSM) ====="
                    export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
                    export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
                    export AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}

                    ansible-playbook -i inventory.ini app.yml
                    """
                }
            }
        }

    } 
} 
