pipeline {
    agent any

    environment {
        TF_DIR = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'us-east-1'
        TF_PLUGIN_CACHE_DIR = 'C:\\terraform-cache'
    }

    stages {

        
        // Terraform Init
        
        stage('Terraform Init') {
            steps {
                withCredentials([
    usernamePassword(
        credentialsId: 'aws-creds',
        usernameVariable: 'AWS_ACCESS_KEY_ID',
        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
    )
]) {
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform init'
                    }
                }
            }
        }

       
        // Terraform Plan
        
        stage('Terraform Plan') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform plan'
                    }
                }
            }
        }

       
        // Terraform Apply
        
        stage('Terraform Apply') {
            steps {
                withCredentials([
                    string(credentialsId: 'AWS_ACCESS_KEY_ID', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'AWS_SECRET_ACCESS_KEY', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh 'terraform apply -auto-approve'
                    }
                }
            }
        }

        stage('Fetch Instance IDs') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
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

[web]
${env.WEB_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=us-east-1 ansible_aws_ssm_bucket_name=guru-3-tier

[app]
${env.APP_ID} ansible_connection=amazon.aws.aws_ssm ansible_user=ec2-user ansible_aws_ssm_region=us-east-1 ansible_aws_ssm_bucket_name=guru-3-tier
"""
                }
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'aws-creds',
                        usernameVariable: 'AWS_ACCESS_KEY_ID',
                        passwordVariable: 'AWS_SECRET_ACCESS_KEY'
                    )
                ]) {
                    sh '''
                    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                    export AWS_DEFAULT_REGION=us-east-1

                    /var/lib/jenkins/ansible-venv/bin/ansible-playbook -vvv \
                    -i ansible/inventory.ini ansible/web.yml

                    /var/lib/jenkins/ansible-venv/bin/ansible-playbook -vvv \
                    -i ansible/inventory.ini ansible/app.yml
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                echo "Deployment Completed Successfully"
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
    }
}
