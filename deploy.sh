#!/bin/bash
set -e
# Tested on AlmaLinux

# Define color variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Get current IP address
current_ip=$(curl -s https://ipinfo.io/ip)
echo -e "Current IP address: ${GREEN}$current_ip${NC}"

# Check requirements
echo -e "Please make sure you have met the following requirements before running this script:"
echo "1. You have a domain name and it is pointing to the current IP address ($current_ip)."
echo "2. You have a valid email address for SSL certificate."
echo "3. You have a valid chatGPT API key."

echo -n "Type 'yes', 'Y', or 'y' to confirm that you have met all the requirements and continue the script, or type anything else to exit: "
read confirmation

# Convert the input to lowercase for easier comparison
confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')

if [ "$confirmation" != "yes" ] && [ "$confirmation" != "y" ]; then
  echo "Exiting the script."
  exit 1
fi

# Get chatGPT API key
validate_api_key=true

while $validate_api_key; do
  read -p "Enter your chatGPT API key (If you don't have any API keys, generate one in https://platform.openai.com/account/api-keys. The API key looks like sk-xxxxxx): " chatgpt_api_key

  if [ -z "$chatgpt_api_key" ]; then
    echo -e "${RED}API key cannot be empty.${NC} Please enter a valid API key:"
  elif [[ $chatgpt_api_key =~ ^sk-[a-zA-Z0-9]{48}$ ]]; then
    validate_api_key=false
  else
    echo -e "${RED}Invalid API key format.${NC} Please enter a valid API key (should look like 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):"
  fi
done

# Get domain name
read -p "Enter the domain name (e.g., example.com): " domain_name

# validate domain name
while [[ ! $domain_name =~ ^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
  echo -e "${RED}Invalid domain name format.${NC} Please enter a valid domain name (e.g., example.com):"
  read domain_name
done
# Check if domain is pointing to the current IP address
domain_ip=$(dig +short $domain_name)
while [[ $current_ip != $domain_ip ]]; do
  echo -e "${RED}The domain is not pointing to the current IP address.${NC} Please update your domain DNS settings and press Enter to try again."
  read
  domain_ip=$(dig +short $domain_name)
done
echo -e "Domain name: ${GREEN}$domain_name${NC}"

# Get port number
read -p "Enter the port number you want to use (e.g., 3000): " port

# Validate port number
while lsof -i :$port | grep LISTEN; do
  echo -e "${RED}Port $port is already in use.${NC} Please enter a different port number:"
  read port
done
echo -e "Port number: ${GREEN}$port${NC}"

# Get nginx auth user and password
read -p "Enter the nginx auth user (e.g., user): " auth_user

auth_password=""
auth_password_confirm=""

while true; do
  echo "Enter the nginx auth password:"
  read -s auth_password
  if [ -z "$auth_password" ]; then
    echo -e "${RED}Password cannot be empty.${NC} Please try again."
    continue
  fi

  echo "Confirm the nginx auth password:"
  read -s auth_password_confirm
  if [ "$auth_password" != "$auth_password_confirm" ]; then
    echo -e "${RED}Passwords do not match.${NC} Please try again."
  else
    break
  fi
done

# Get email for SSL certificate
read -p "Enter your email for SSL certificate: " email

while [[ ! $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; do
  echo -e "${GREEN}Invalid email format.${NC} Please enter a valid email address:"
  read email
done

echo -e "Valid email address: ${GREEN}$email${NC}"

# Generate SSL certificate
sudo certbot --nginx -d $domain_name --non-interactive --agree-tos --email $email

# Create htpasswd file
sudo htpasswd -c -b /etc/nginx/.htpasswd $auth_user $auth_password

if nginx -t; then
  echo "Nginx configuration is valid"
else
  echo "Nginx configuration is invalid"
fi

# Create Nginx configuration
nginx_config="server {
    listen 80;
    server_name $domain_name;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain_name;

    ssl_certificate /etc/letsencrypt/live/$domain_name/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain_name/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$domain_name/chain.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    auth_basic \"Restricted Content\";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {

        proxy_pass http://localhost:$port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"

echo "$nginx_config" | sudo tee /etc/nginx/conf.d/$domain_name.conf

# Restart Nginx and reload firewall rules
sudo systemctl restart nginx

echo "SSL certificate installed, and Nginx configured with authentication for domain $domain_name."

echo "Choose the open-source project you want to deploy (If you want to deploy both, you can try to run this script again later):"
options=("https://github.com/Yidadaa/ChatGPT-Next-Web" "https://github.com/ourongxing/chatgpt-vercel")

PS3="Enter 1 or 2 (default is 1): "
select option in "${options[@]}"; do
  case $REPLY in
  1 | "")
    option=${options[0]}
    echo "You have chosen: $option"
    docker pull yidadaa/chatgpt-next-web

    docker run -d -p $port:3000 -e OPENAI_API_KEY="$chatgpt_api_key" yidadaa/chatgpt-next-web
    if [ $? -eq 0 ]; then
      echo "All done! You can now access your website at https://$domain_name."
    else
      echo "yidadaa/chatgpt-next-web failed to start."
    fi
    break
    ;;
  2)
    option=${options[1]}
    echo "You have chosen: $option . Cloning the repository... Please wait."
    # Clone the repository
    git clone $option
    cd chatgpt-vercel
    # Install pm2 to manage the Node.js process
    sudo npm install pm2@latest -g
    # Install dependencies
    npm install
    # Create .env file
    env_config="CLIENT_GLOBAL_SETTINGS={"APIKey":"","password":"","enterToSend":true}
CLIENT_SESSION_SETTINGS={"title":"","saveSession":true,"APITemperature":0.6,"continuousDialogue":true,"APIModel":"gpt-3.5-turbo"}
CLIENT_DEFAULT_MESSAGE='Powered by OpenAI Vercel
- 如果本项目对你有所帮助，可以给小猫 [买点零食](https://cdn.jsdelivr.net/gh/ourongxing/chatgpt-vercel/assets/reward.gif)，但不接受任何付费功能请求。
- 本网站仅作为项目演示，不提供服务，请填入自己的 Key，长期使用请 [自行部署](https://github.com/ourongxing/chatgpt-vercel#%E9%83%A8%E7%BD%B2%E4%B8%80%E4%B8%AA%E4%BD%A0%E8%87%AA%E5%B7%B1%E7%9A%84-chatgpt-%E7%BD%91%E7%AB%99%E5%85%8D%E8%B4%B9)，简单成本低。
- 点击每条消息前的头像，可以锁定对话，作为角色设定。[查看更多使用技巧](https://github.com/ourongxing/chatgpt-vercel#使用技巧)。
- 现在支持多个对话，打开对话设置，点击新建对话。在输入框里输入 [[/]][[/]] 或者 [[空格]][[空格]] 可以切换对话，搜索历史消息。
- [[Shift]] + [[Enter]] 换行。开头输入 [[/]] 或者 [[空格]] 搜索 Prompt 预设。[[↑]] 可编辑最近一次提问。点击顶部名称滚动到顶部，点击输入框滚动到底部。
'
CLIENT_MAX_INPUT_TOKENS={"gpt-3.5-turbo":4096,"gpt-4":8192,"gpt-4-32k":32768}
OPENAI_API_BASE_URL=api.openai.com
OPENAI_API_KEY=$chatgpt_api_key
TIMEOUT=30000
PASSWORD=
SEND_KEY=
SEND_CHANNEL=9
NO_GFW=false
      "
    echo "$env_config" | sudo tee .env
    npm run build:vps
    pm2_config="
      module.exports = {
  apps: [
    {
      name: 'chatgpt-vercel',
      script: 'npm',
      args: 'run start --port $port',
      watch: false,
      autorestart: true,
      restart_delay: 5000, // 重启延迟 5 秒，可根据需要调整
    },
  ],
};"
    echo "$pm2_config" | sudo tee ecosystem.config.cjs

    pm2 start ecosystem.config.cjs

    if [ $? -eq 0 ]; then
      echo "All done! You can now access your website at https://$domain_name."
      pm2 list
    else
      echo "Failed to start PM2 application"

    fi

    break
    ;;
  *)
    echo "Invalid option. Please choose a valid number (1 or 2) or press Enter for the default."
    ;;
  esac
done
