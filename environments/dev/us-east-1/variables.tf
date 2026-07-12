variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "shop"
}
variable "environment" {
  type    = string
  default = "dev"
}
variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}
variable "key_name" {
  type    = string
  default = null
}
variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}
variable "web_min_size" {
  type    = number
  default = 1
}
variable "web_max_size" {
  type    = number
  default = 2
}
variable "app_min_size" {
  type    = number
  default = 1
}
variable "app_max_size" {
  type    = number
  default = 2
}
variable "database_name" {
  type    = string
  default = "appdb"
}
variable "database_username" {
  type    = string
  default = "appadmin"
}
variable "db_password" {
  type      = string
  sensitive = true
}
variable "db_instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "db_multi_az" {
  type    = bool
  default = false
}
variable "db_skip_final_snapshot" {
  type    = bool
  default = true
}
variable "db_deletion_protection" {
  type    = bool
  default = false
}
