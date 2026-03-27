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

        stage('Run Ansible') {
            steps {
                script {

                    // Get both EC2 IPs from Terraform outputs
                    def WEB_IP = sh(
                        script: "cd terraform && terraform output -raw web_tier_ip",
                        returnStdout: true
                    ).trim()

                    def APP_IP = sh(
                        script: "cd terraform && terraform output -raw app_tier_ip",
                        returnStdout: true
                    ).trim()

                    sh """
                    cd ansible
                    chmod 400 ../guru-key.pem

                    # Create inventory file
                    echo "[web]" > inventory
                    echo "$WEB_IP ansible_user=ec2-user ansible_ssh_private_key_file=../guru-key.pem" >> inventory

                    echo "[app]" >> inventory
                    echo "$APP_IP ansible_user=ec2-user ansible_ssh_private_key_file=../guru-key.pem" >> inventory

                    # Run Ansible
                    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbook.yml
                    """
                }
            }
        }
    }
}
