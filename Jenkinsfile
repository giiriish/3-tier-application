pipeline {
    agent any

    stages {

        stage('Terraform Init') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir('terraform') {
                        sh 'terraform init'
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
                    dir('terraform') {
                        sh 'terraform plan'
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
                    dir('terraform') {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        
        stage('Fetch IPs') {
            steps {
                script {
                    env.WEB_IP = sh(
                        script: "cd terraform && terraform output -raw web_public_ip",
                        returnStdout: true
                    ).trim()

                    env.APP_IP = sh(
                        script: "cd terraform && terraform output -raw app_private_ip",
                        returnStdout: true
                    ).trim()

                    echo "Web IP: ${WEB_IP}"
                    echo "App IP: ${APP_IP}"
                }
            }
        }

       
        stage('Create Inventory') {
            steps {
                script {
                    writeFile file: 'ansible/inventory.ini', text: """
[web]
${WEB_IP} ansible_user=ec2-user

[app]
${APP_IP} ansible_user=ec2-user ansible_ssh_common_args='-o ProxyJump=ec2-user@${WEB_IP}'
"""
                }
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
