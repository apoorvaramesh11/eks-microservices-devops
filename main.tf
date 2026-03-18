
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
     kubernetes = {
       source = "hashicorp/kubernetes"
       version = "~> 3.0"
   }
  }

  backend "s3" {
    bucket         = "demo-terraform-eks-apoorva-state-bucket-1"
    key            = "terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-eks-state-locks"
    encrypt        = true
  }
}



provider "aws" {
  region = var.region
}

data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = var.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.cluster.certificate_authority[0].data
  )
  token = data.aws_eks_cluster_auth.cluster.token
}


module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
  cluster_name         = var.cluster_name
}

module "eks" {
  source = "./modules/eks"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  vpc_id          = module.vpc.vpc_id
  subnet_ids      = module.vpc.private_subnet_ids
  node_groups     = var.node_groups


  
}

resource "kubernetes_config_map" "aws_auth" {
  metadata {
    name      = "aws-auth1"
    namespace = "kube-system"
  }

  data = {
    mapUsers = yamlencode(var.aws_auth_users)
  }
}
