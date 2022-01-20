
output "lb_instance_endpoint" {
  description = "The application alb  DNS name "
  value       = aws_alb.orca.*.dns_name
}
#output "db_instance_username" {
#  description = "The db username"
#  value       = aws_db_instance.orca.*.username
#}


#output "db_instance_password" {
#  description = "The db password"
#  value       = aws_db_instance.orca.*.password
#}


