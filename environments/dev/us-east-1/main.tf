terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = local.tags
  }
}

locals {
  name = "${var.project}-${var.environment}"
  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

module "network" {
  source   = "../../../modules/network"
  name     = local.name
  vpc_cidr = var.vpc_cidr
  tags     = local.tags
}

module "security" {
  source = "../../../modules/security"
  name   = local.name
  vpc_id = module.network.vpc_id
  tags   = local.tags
}

module "compute" {
  source             = "../../../modules/compute"
  name               = local.name
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  web_subnet_ids     = module.network.web_subnet_ids
  app_subnet_ids     = module.network.app_subnet_ids
  public_alb_sg_id   = module.security.public_alb_sg_id
  web_sg_id          = module.security.web_sg_id
  internal_alb_sg_id = module.security.internal_alb_sg_id
  app_sg_id          = module.security.app_sg_id
  key_name           = var.key_name
  web_instance_type  = var.web_instance_type
  app_instance_type  = var.app_instance_type
  web_min_size       = var.web_min_size
  web_max_size       = var.web_max_size
  app_min_size       = var.app_min_size
  app_max_size       = var.app_max_size
  tags               = local.tags
}

module "database" {
  source              = "../../../modules/database"
  name                = local.name
  subnet_ids          = module.network.database_subnet_ids
  security_group_id   = module.security.database_sg_id
  database_name       = var.database_name
  username            = var.database_username
  password            = var.db_password
  instance_class      = var.db_instance_class
  multi_az            = var.db_multi_az
  skip_final_snapshot = var.db_skip_final_snapshot
  deletion_protection = var.db_deletion_protection
  tags                = local.tags
}
