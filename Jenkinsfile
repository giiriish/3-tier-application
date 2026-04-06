pipeline {
    agent any

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
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${TF_DIR}") {
                        sh '''
                        export AWS_DEFAULT_REGION=us-east-1

                        terraform init -reconfigure
                        terraform validate
                        terraform apply -auto-approve -var-file=terraform.tfvars
                        '''
                    }
                }
            }
        }

        stage('Fetch Instance IDs') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        env.WEB_ID = sh(
                            script: "terraform output -raw web_instance_id",
                            returnStdout: true
                        ).trim()

                        env.APP_ID = sh(
                            script: "terraform output -raw app_instance_id",
                            returnStdout: true
                        ).trim()

                        echo "WEB_ID=${env.WEB_ID}"
                        echo "APP_ID=${env.APP_ID}"
                    }
                }
            }
        }

        stage('Create Inventory (SSM)') {
            steps {
                script {
                    writeFile file: "${WORKSPACE}/${ANSIBLE_DIR}/inventory.ini", text: """
[web]
${env.WEB_ID}

[app]
${env.APP_ID}

[all:vars]
ansible_connection=amazon.aws.aws_ssm
ansible_region=us-east-1
ansible_aws_ssm_bucket_name=my-ssm-ansible-bucket
ansible_user=ec2-user
"""
                }
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                    export AWS_DEFAULT_REGION=us-east-1

                    ansible-playbook -vvv \
                    -i ${WORKSPACE}/ansible/inventory.ini \
                    ${WORKSPACE}/ansible/web.yml

                    ansible-playbook -vvv \
                    -i ${WORKSPACE}/ansible/inventory.ini \
                    ${WORKSPACE}/ansible/app.yml
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                echo "Checking web server..."
                curl -I http://localhost || true
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Deployment Successful"
        }
        failure {
            echo "❌ Deployment Failed"
        }
        always {
            cleanWs()
        }
    }
}
