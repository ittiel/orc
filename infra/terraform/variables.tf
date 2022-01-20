# -----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# Define these secrets as environment variables
# -----------------------------------------------------------------------------

# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY

# -----------------------------------------------------------------------------
# PARAMETERS
# -----------------------------------------------------------------------------

variable "region" {
  description = "Region to deploy"
  default     = "eu-west-1" # Asia Pacific Tokyo
}

variable "orca_version_tag" {
  description = "The orca app version tag"
  default     = "latest"
}

variable "rds_username" {
  description = "The username for RDS"
  sensitive   = true
}

variable "rds_password" {
  description = "The password for RDS"
  sensitive   = true
}

variable "rds_db_name" {
  description = "The DB name in the RDS instance"
  default = "orcaApp"
}

variable "rds_instance" {
  description = "The size of RDS instance, eg db.t2.micro"
  default = "db.t2.micro"
}

variable "rds_storage_encrypted" {
  description = "Whether the data on the PostgreSQL instance should be encrpyted."
  default     = false
}

variable "az_count" {
  description = "How many AZ's to create in the VPC"
  default     = 2
}

variable "multi_az" {
  description = "Whether to deploy RDS and ECS in multi AZ mode or not"
  default     = true
}

variable "vpc_enable_dns_hostnames" {
  description = "A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false."
  default     = false
}

variable "environment" {
  description = "Environment variables for ECS task: [ { name = \"foo\", value = \"bar\" }, ..]"
  default     = []
}

variable "additional_db_security_groups" {
  description = "List of Security Group IDs to have access to the RDS instance"
  default     = []
}

variable "create_iam_service_linked_role" {
  description = "Whether to create IAM service linked role for AWS ElasticSearch service. Can be only one per AWS account."
  default     = false
}

variable "ecs_cluster_name" {
  description = "The name to assign to the ECS cluster"
  default     = "orca-cluster"
}
