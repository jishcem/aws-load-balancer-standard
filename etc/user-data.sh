#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs

apt update
apt install ruby-full -y
apt install wget -y
wget https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install
chmod +x ./install
./install auto > /tmp/logfile
service codedeploy-agent restart

echo "Create Code directory"
mkdir -p /home/ubuntu/Code/express-codedeploy-3

touch /etc/systemd/system/node-api.service
bash -c 'cat <<EOT > /etc/systemd/system/node-api.service
[Unit]
Description=Nodejs hello world App
Documentation=https://example.com
After=network.target

[Service]
Type=simple
User=ubuntu
ExecStart=/usr/bin/node /home/ubuntu/Code/express-codedeploy-3/dist/index.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOT'

systemctl enable node-api.service
systemctl start node-api.service

echo "Installing nginx server"
apt install nginx -y

tee /etc/nginx/sites-enabled/default >/dev/null <<'EOF'
upstream backend {
        server 127.0.0.1:3000;
}

server {
        listen 80 default_server;
        listen [::]:80 default_server;        
        server_name _;
        location / {
                proxy_pass         http://backend;
                proxy_http_version 1.1;
                proxy_set_header   Upgrade $http_upgrade;
                proxy_set_header   Connection keep-alive;
                proxy_set_header   Host $host;
                proxy_cache_bypass $http_upgrade;
                proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header   X-Forwarded-Proto $scheme;
        }
}
EOF

nginx -t
systemctl start nginx

# Install AWS CLI 
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


aws deploy create-deployment --application-name node-app --deployment-group-name ec2-app --s3-location bucket=typescript-express-artifact-2,key=classic-loadbalancer/project.zip,bundleType=zip