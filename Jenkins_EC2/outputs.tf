output "_1-Jenkins-project" {
  description = "Print out to screen"
  value       = "Hello from your Jenkins-Terraform-AWS project"
}
output "_2-Public_url" {
  description = "Public URL for our Web Server"
  value       = "http://${aws_instance.Jenkins_EC2_Instance.public_ip}:8080/"
}
output "_3-SSH_ec2_instance" {
  description = "Public IP for SSH-EC2-Instance login"
  value       = "ssh -i JenkinsCICD.pem ec2-user@${aws_instance.Jenkins_EC2_Instance.public_ip}"
}
output "_4-Initial_Command" {
  description = "Run this inital command to retrieve default password"
  value       = "sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
}