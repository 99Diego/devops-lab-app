# DevOps Lab App - Terraform + Flask + Docker + Jenkins + AWS EKS

## Project Overview
This project demonstrates a complete DevOps workflow — **from Infrastructure as Code (IaC) with Terraform to Continuous Integration and Delivery (CI/CD) with Jenkins, deploying a Flask application on AWS Elastic Kubernetes Service(EKS).**

It automates everything:
1. Infrastructure provisioning (ECR, VPC, EKS Cluster, Node Group)
2. Docker image build and push
3. Kubernetes deployment
4. Public access via AWS Load Balancer
---

## Architecture
```
scss
   ┌────────────────────────────┐
   │      Terraform (IaC)       │
   │  • VPC + Subnets           │
   │  • EKS Cluster + Nodes     │
   │  • ECR Repository          │
   └────────────┬───────────────┘
                │
                ▼
   ┌───────────────┐         ┌──────────────┐         ┌───────────────┐
   │   GitHub Repo │  push   │   Jenkins CI │  build  │   Docker Image │
   │  (Flask App)  │────────▶│ (Pipeline)   │────────▶│   (ECR AWS)    │
   └───────────────┘         └──────────────┘         └───────────────┘
                                                          │
                                                          ▼
                                                ┌────────────────────┐
                                                │   AWS EKS Cluster  │
                                                │ (Pods + Service LB)│
                                                └────────────────────┘
                                                          │
                                                          ▼
                                             🌐 http://<ELB_DNS>
```

---

## Tech Stack
| Layer                            | Tool                 |
| -------------------------------- | -------------------- |
| **Infrastructure as Code (IaC)** | Terraform            |
| **Containerization**             | Docker               |
| **Continuous Integration**       | Jenkins              |
| **Container Registry**           | AWS ECR              |
| **Orchestration / Deployment**   | AWS EKS (Kubernetes) |
| **Application Framework**        | Flask (Python)       |
| **Cloud Provider**               | AWS                  |

---

## Project Structure
```
bash
devops-lab-app/
│
├── app.py                    # Flask web app
├── Dockerfile                # Defines Docker image
├── requirements.txt          # Python dependencies
├── Jenkinsfile               # CI/CD pipeline definition
├── k8s/
│   ├── deployment.yaml       # Kubernetes deployment
│   └── service.yaml          # Kubernetes service (LoadBalancer)
│
└── devopslab-terraform/      # Terraform infrastructure code
    ├── main.tf
    ├── variables.tf
    ├── provider.tf
    ├── outputs.tf
    ├── role.json
    └── trust-policy.json
```

---

## 1. Infrastructure Deployment - Terraform
Terraform provisions the required AWS resources for the project.

***main.tf (Highlights)***
```
hcl
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "devopslab-cluster"
  cluster_version = "1.30"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    default = {
      desired_capacity = 1
      max_capacity     = 2
      min_capacity     = 1
      instance_types   = ["t3.medium"]
    }
  }
}

resource "aws_ecr_repository" "app_repo" {
  name = "devops-lab-app"
}
```
***Commands used:***
```
bash
cd devopslab-terraform
terraform init
terraform plan
terraform apply -auto-approve
```
***Output:***
```
yaml
Apply complete! Resources: 12 added, 0 changed, 0 destroyed.

EKS cluster name: devopslab-cluster
ECR repository URL: 152735632105.dkr.ecr.us-east-1.amazonaws.com/devops-lab-app
```

---

## 2. Docker Image - Flask Application 
The application is fully containerized using **Docker** for portability and consistency accross environments.

***Dockerfile:***
```
dockerfile
# Base image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Flask port
EXPOSE 5000

# Start the application
CMD ["python", "app.py"]

# Base image
FROM python:3.10-slim

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Expose Flask port
EXPOSE 5000

# Start the application
CMD ["python", "app.py"]
```
How it works:
- Base image: Official lightweight Python 3.10.

- Dependencies: Installed from requirements.txt.

- Execution: Runs Flask app on port 5000.

- Port mapping: Kubernetes exposes it via AWS Load Balancer (port 80 → 5000).

***Local Test (optional)***
```
bash
docker build -t devops-lab-app .
docker run -p 5000:5000 devops-lab-app
```
then open:
```
arduino
http://localhost:5000
```
Output:
```
csharp
🚀 Hello from DevOps Lab on AWS EKS!
```

---

## 3. Jenkins Pipeline - CI/CD Flow
Once the infrastructure is ready, Jenkins automates the build and deployment pipeline.
| Stage                  | Description                                  |
| ---------------------- | -------------------------------------------- |
| **Checkout Code**      | Clones the source from GitHub.               |
| **Build Docker Image** | Builds Flask app image.                      |
| **Login to AWS ECR**   | Authenticates Jenkins to ECR.                |
| **Push to ECR**        | Uploads the image to the registry.           |
| **Deploy to EKS**      | Applies Kubernetes manifests to the cluster. |



***Jenkins File:***
```
groovy
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
                git branch: 'main', credentialsId: 'github-creds', url: 'https://github.com/99Diego/devops-lab-app.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $REPO_NAME .'
            }
        }

        stage('Login to AWS ECR') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        aws ecr get-login-password --region us-east-1 | \
                        docker login --username AWS --password-stdin 152735632105.dkr.ecr.us-east-1.amazonaws.com
                    '''
                }
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    docker tag $REPO_NAME:latest $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
                    docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:latest
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                        aws eks update-kubeconfig --name devopslab-cluster --region us-east-1
                        kubectl apply -f k8s/
                    '''
                }
            }
        }
    }

    post {
        always {
            echo "✅ Pipeline completed."
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
    }
}
```

---

## 4. Kubernetes Manifests
***deployment.yaml***
```
yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-lab-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: devops-lab-app
  template:
    metadata:
      labels:
        app: devops-lab-app
    spec:
      containers:
      - name: devops-lab-app
        image: 152735632105.dkr.ecr.us-east-1.amazonaws.com/devops-lab-app:latest
        ports:
        - containerPort: 5000
```
***service.yaml***
```
yaml
apiVersion: v1
kind: Service
metadata:
  name: devops-lab-service
spec:
  type: LoadBalancer
  selector:
    app: devops-lab-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
```

---

## Deployment Result
After the Jenkins pipeline complements successfully, check your Kubernetes resources:
```
bash
kubectl get pods
kubectl get svc
```
***Example Output:***
```
pgsql
NAME                             READY   STATUS    RESTARTS   AGE
devops-lab-app-6b7b94c5b-grd5t   1/1     Running   0          19h
devops-lab-app-6b7b94c5b-zx6jl   1/1     Running   0          19h

NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP                                                              PORT(S)        AGE
devops-lab-service   LoadBalancer   172.20.209.148   a9cf07d7e115141458daf3823efe1c9b-279280957.us-east-1.elb.amazonaws.com   80:31788/TCP   20h
```
Acces your app through the Load Balancer:
```
Arduino
http://a9cf07d7e115141458daf3823efe1c9b-279280957.us-east-1.elb.amazonaws.com
```
***Output:***
```
csharp
🚀 Hello from DevOps Lab on AWS EKS!
```

--- 

## Key Learnings
- Infrastructure as Code (Terraform) — reproducible AWS environments

- Containerization — Docker images managed in ECR

- CI/CD Automation — Jenkins pipelines for build and deploy

- Kubernetes Deployment — scalable Flask app on AWS EKS

- Load Balancing — AWS ELB exposes the app publicly

--- 

## Tools & Technologies
Terraform

AWS EKS / ECR

Docker

Kubernetes

Jenkins

Python (Flask)

GitHub

---

## Author
Diego López Arango
DevOps Engineer | Electronics Engineer 
Colombia
🔗 GitHub: 99Diego
