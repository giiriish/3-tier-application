pipeline {
    agent any

    environment {
        TF_DIR      = 'terraform'
        ANSIBLE_DIR = 'ansible'
        AWS_DEFAULT_REGION = 'ap-south-1'
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
                dir("${TF_DIR}") {
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
                    ]) {
                        sh '''
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
                    withCredentials([
                        [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
                    ]) {
                        script {
                            env.WEB_ID = sh(
                                script: "terraform output -raw web_instance_id",
                                returnStdout: true
                            ).trim()

                            env.APP_ID = sh(
                                script: "terraform output -raw app_instance_id",
                                returnStdout: true
                            ).trim()
                        }
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
ansible_user=ec2-user
ansible_aws_ssm_region=ap-south-1
ansible_remote_tmp=/tmp
ansible_shell_type=sh
ansible_aws_ssm_bucket_name=guru-3-tier
"""
                }
            }
        }

        stage('Run Ansible') {
            steps {
                withCredentials([
                    [$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']
                ]) {
                    sh '''
                    ansible-playbook -i ${WORKSPACE}/ansible/inventory.ini ${WORKSPACE}/ansible/web.yml
                    ansible-playbook -i ${WORKSPACE}/ansible/inventory.ini ${WORKSPACE}/ansible/app.yml
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                dir("${TF_DIR}") {
                    script {
                        def WEB_IP = sh(
                            script: "terraform output -raw web_public_ip",
                            returnStdout: true
                        ).trim()

                        sh """
                        echo "Checking Web Server..."
                        curl -I http://${WEB_IP} || true
                        """
                    }
                }
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
