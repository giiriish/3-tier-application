pipeline {
    agent any

    stages {

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Fetch IPs') {
            steps {
                script {
                    def web_ip = sh(script: "cd terraform && terraform output -raw web_public_ip", returnStdout: true).trim()
                    def app_ip = sh(script: "cd terraform && terraform output -raw app_private_ip", returnStdout: true).trim()

                    echo "Web IP: ${web_ip}"
                    echo "App IP: ${app_ip}"

                    writeFile file: 'ansible/inventory.ini', text: """
[web]
${web_ip} ansible_user=ec2-user

[app]
${app_ip} ansible_user=ec2-user
"""
                }
            }
        }

        
        stage('Wait for EC2') {
            steps {
                sh 'sleep 60'
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([sshUserPrivateKey(credentialsId: 'ec2-key', keyFileVariable: 'KEY_FILE')]) {
                    sh '''
                    cd ansible

                    chmod 400 $KEY_FILE

                    ansible-playbook -i inventory.ini web.yml --private-key $KEY_FILE
                    ansible-playbook -i inventory.ini app.yml --private-key $KEY_FILE
                    '''
                }
            }
        }
    }
}
