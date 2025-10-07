pipeline {
    agent any

    environment {
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '152735632105'
        REPO_NAME = 'devops-lab-app'
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "📥 Cloning repository..."
                git branch: 'main', credentialsId: 'github-creds', url: 'https://github.com/99Diego/devops-lab-app.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh 'docker build -t $REPO_NAME .'
            }
        }

        stage('Login to AWS ECR') {
            steps {
                echo '🔐 Logging into AWS ECR...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | \
                        docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                echo "📦 Pushing image to ECR..."
                sh '''
                    docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                echo '🚀 Deploying to EKS...'
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        aws eks update-kubeconfig --name devopslab-cluster --region $AWS_REGION
                        kubectl apply -f k8s/
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline completed (success or fail)."
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
        success {
            echo "🎉 Deployment successful!"
        }
    }
}

