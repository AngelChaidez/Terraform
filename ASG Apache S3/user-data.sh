#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo chmod 777 /var/www/html
cd /var/www/html
sudo echo "<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
</head>
<body>
<h1>Produced by Angel!</h1>
<p><em>Thank you for stopping by.</em></p>
</body>
</html>" > index.html
echo "Instance ID" >> index.html
curl http://169.254.169.254/latest/meta-data/instance-id >> index.html
echo "Public IP" >> index.html
curl http://169.254.169.254/latest/meta-data/local-ipv4 >> index.html
echo "Public IP" >> index.html
curl http://169.254.169.254/latest/meta-data/subnet-id >> index.html