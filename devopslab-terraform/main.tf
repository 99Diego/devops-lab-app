# Create a basic EKS cluster with official module of AWS

module "eks" {
  source 	  = "terraform-aws-modules/eks/aws"
  version	  = "20.8.4"

  cluster_name	  = "devopslab-cluster"
  cluster_version = "1.30"
  cluster_endpoint_public_access = true

  # VPC & Subnetworks configuration
  vpc_id	= module.vpc.vpc_id
  subnet_ids 	= module.vpc.private_subnets

  # EC2 nodes
  eks_managed_node_groups = {
    default = {
      desired_size = 2
      max_size = 3
      min_size = 1

      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Environment = "dev"
    Project     = "DevOps-Lab"
  }
}

# VPC module
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "devopslab-vpc"
  cidr = "10.0.0.0/16"

  azs		    = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = false

  tags = {
    Terraform	  = true
    Environment = "dev"
  } 
}

# Agregar acceso administrativo al usuario terraform-user (versión AWS provider 5.100)
resource "aws_eks_access_entry" "terraform_user_access" {
  cluster_name  = module.eks.cluster_name
  principal_arn = "arn:aws:iam::152735632105:user/terraform-user"
  type          = "STANDARD"
}

# Asociar política de administrador al usuario terraform-user
resource "aws_eks_access_policy_association" "terraform_user_admin" {
  cluster_name  = module.eks.cluster_name
  principal_arn = aws_eks_access_entry.terraform_user_access.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

