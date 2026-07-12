variable "name" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_id" {
  type = string
}
variable "database_name" {
  type    = string
  default = "appdb"
}
variable "username" {
  type    = string
  default = "appadmin"
}
variable "password" {
  type      = string
  sensitive = true
}
variable "engine_version" {
  type    = string
  default = "16.4"
}
variable "instance_class" {
  type    = string
  default = "db.t3.micro"
}
variable "allocated_storage" {
  type    = number
  default = 20
}
variable "multi_az" {
  type    = bool
  default = false
}
variable "skip_final_snapshot" {
  type    = bool
  default = true
}
variable "deletion_protection" {
  type    = bool
  default = false
}
variable "tags" {
  type    = map(string)
  default = {}
}
