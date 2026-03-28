pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
    }

    stages {

        // -------------------------------
        // Terraform Init
        // -------------------------------
        stage('Terraform Init') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform init'
                }
            }
        }

        // -------------------------------
        // Terraform Plan
        // -------------------------------
        stage('Terraform Plan') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform plan'
                }
            }
        }

        // -------------------------------
        // Terraform Apply
        // -------------------------------
        stage('Terraform Apply') {
            steps {
                dir("${TF_DIR}") {
                    sh 'terraform apply -auto-approve'
                }
            }
        }

        // -------------------------------
        // Fetch IPs from Terraform
        // -------------------------------
        stage('Fetch IPs') {
            steps {
                script {
                    def web_ip = sh(
                        script: "cd ${TF_DIR} && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    def app_ip = sh(
                        script: "cd ${TF_DIR} && terraform output -raw app_private_ip",
                        returnStdout: true
                    ).trim()

                    env.WEB_IP = web_ip
                    env.APP_IP = app_ip

                    echo "Web IP: ${WEB_IP}"
                    echo "App IP: ${APP_IP}"
                }
            }
        }

        // -------------------------------
        // Create Ansible Inventory
        // -------------------------------
        stage('Create Inventory') {
            steps {
                script {
                    writeFile file: "${ANSIBLE_DIR}/inventory.ini", text: """
[web]
${WEB_IP} ansible_user=ec2-user

[app]
${APP_IP} ansible_user=ec2-user
"""
                }
            }
        }

        // -------------------------------
        // Wait for EC2 to be ready
        // -------------------------------
        stage('Wait for EC2') {
            steps {
                echo "Waiting for EC2 instances to be ready..."
                sh 'sleep 60'
            }
        }

        // -------------------------------
        // Run Ansible
        // -------------------------------
        stage('Run Ansible') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY_FILE')
                ]) {
                    sh """
                    cd ${ANSIBLE_DIR}

                    chmod 400 \$KEY_FILE

                    ansible-playbook -i inventory.ini web.yml --private-key \$KEY_FILE
                    ansible-playbook -i inventory.ini app.yml --private-key \$KEY_FILE
                    """
                }
            }
        }
    }
}
