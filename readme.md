# Deploy chatgpt on your own server and bind a domain to it with one script

## Notice

This script is merely tested on Almalinux8. It may not work on other Linux distributions.

## Prerequisites

1. A server
2. A domain name
3. An email address
4. A ChatGPT api key
5. Install dependencies with `bash install-dependencies.sh`

## Deploy

1. Add a A record for your domain pointing to your server's IP address, after which you can ping your domain to check if it works. If you are using cloudflare, don't forget to turn off the proxy to make it direct to your server.
2. Login to your server and install git with `sudo yum install git -y`
3. Clone this repository with `git clone https://github.com/Likenttt/deploy-chatgpt-on-your-server.git`
4. Change directory to the repository with `cd deploy-chatgpt-on-your-server`
5. Run `bash deploy.sh` and follow the instructions. You will be asked to input your domain name and email address. The email address is used to apply for a SSL certificate from Let's Encrypt.
6. After the script finishes, you can visit your domain to check if it works. If it doesn't work, you can check the log file in the repository to see what's wrong.

## Credits

- [ChatGPT-Next-Web](https://github.com/Yidadaa/ChatGPT-Next-Web)
- [chatgpt-vercel](https://github.com/ourongxing/chatgpt-vercel)
- [certbot](https://certbot.eff.org/)
- GPT-4

## License

MIT License

## Buy me a coffee

<a href="https://www.buymeacoffee.com/lichuanyi" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
