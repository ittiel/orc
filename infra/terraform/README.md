# Orca app on AWS

Terraform module to deploy orca application on AWS. This will deploy
across multiple Availability Zones (AZ) with the following components:

- Postgres RDS deployed in multiple AZ
- Orca app in [Fargate](https://aws.amazon.com/fargate/) across multiple AZ
  - ALB for load balancing between the orca tasks

To run this example you need to execute:

```bash
$ terraform init
$ terraform plan
$ terraform apply
```

## Usage
Need to provide DB username and password