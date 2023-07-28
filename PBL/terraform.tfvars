#--- root/terrafom.tfvars ---

aws_region = "us-west-2"

vpc_cidr = "10.0.0.0/16"

enable_dns_hostnames = true

enable_dns_support = true

preferred_number_of_pub_subnets = 2

preferred_number_of_priv_subnets = 4

tags = {
  Environment     = "production"
  Department      = "Operations"
  Owner-Email     = "mayorfaj.io@gmail.com"
  Managed-By      = "Terraform"
  Billing-Account = "953523290929"
}

ami = "ami-03bbed970551ca055"

account_no = "953523290929"

master-password = "Ashabi_123"

master-username = "mayor"

public_key_path = "/Users/mozart/.ssh/terraform-pbl.pub"


