echo "Welcome to the chatGPT deployment script!"
echo "We are going to install dependencies and configure the server. This may take a few minutes."
# Install dependencies
sudo yum update -y
sudo yum install -y epel-release
sudo yum install -y curl
sudo yum remove -y nodejs npm
curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum module enable -y nodejs
sudo yum install -y nodejs
sudo yum install -y nginx git python3 npm zsh vim bind-utils docker wget gcc-c++ certbot util-linux-user httpd-tools
sudo yum groupinstall -y "Development Tools"
sudo dnf install -y python3-certbot-nginx
sudo firewall-cmd --permanent --add-service=http
sudo firewall-cmd --permanent --add-service=https
sudo firewall-cmd --reload
