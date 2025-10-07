pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPO = '152735632105.dkr.ecr.us-east-1.amazonaws.com/devops-lab-app'
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: 'https://github.com/diego0419/devops-lab-app.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    echo '🚧 Building Docker image...'
                    docker build -t ${ECR_REPO}:${IMAGE_TAG} .
                    """
                }
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh 'aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_REPO'
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh """
                echo '🚀 Pushing image to ECR...'
                docker push ${ECR_REPO}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh """
                    echo '🧩 Deploying to EKS...'
                    aws eks update-kubeconfig --region $AWS_REGION --name devopslab-cluster
                    kubectl set image deployment/devops-lab-app devops-lab-app=${ECR_REPO}:${IMAGE_TAG} --record
                    kubectl rollout status deployment/devops-lab-app
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Deployment successful!'
        }
        failure {
            echo '❌ Pipeline failed. Check logs.'
        }
    }
}

