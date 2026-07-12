variable "name" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_ids" {
  type = list(string)
}
variable "web_subnet_ids" {
  type = list(string)
}
variable "app_subnet_ids" {
  type = list(string)
}
variable "public_alb_sg_id" {
  type = string
}
variable "web_sg_id" {
  type = string
}
variable "internal_alb_sg_id" {
  type = string
}
variable "app_sg_id" {
  type = string
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
variable "tags" {
  type    = map(string)
  default = {}
}
