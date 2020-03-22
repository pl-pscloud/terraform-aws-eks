variable "pscloud_env" {}
variable "pscloud_company" {}
variable "pscloud_project" {}
variable "pscloud_aws_profile" {}

variable "pscloud_subnets_ids" {}
variable "pscloud_security_groups_ids" { default = []}

variable "pscloud_ssh_key_name" { default = "" }
variable "pscloud_subnets_ids_for_node_group" {}

variable "pscloud_node_group_min" {}
variable "pscloud_node_group_max" {}
variable "pscloud_node_group_desired" {}


variable "pscloud_ami_type" { default = "AL2_x86_64"}
variable "pscloud_disk_size" { default = 20 }
variable "pscloud_instance_types" { default = [ "t3.micro" ] }