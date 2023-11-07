output "rds_master_username" {
  value     = aws_db_instance.cicd-rds-instance.username
  sensitive = true

}

output "rds_master_password" {
  value     = aws_db_instance.cicd-rds-instance.password
  sensitive = true
}

output "ec2_instance" {
  value = {
    for index, instance in module.ec2_instance :
    index => "ssh -i EastCoastKP.pem -A ec2-user@${instance.public_ip}"
  }
}

output "rds_connection" {
  value = "mysql -h ${aws_db_instance.cicd-rds-instance.address} -P 3306 -u user -p"
}