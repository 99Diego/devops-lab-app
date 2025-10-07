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
                git branch: 'main', url: 'https://github.com/99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99Diego99DiegoDeploy to EKS') {
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

