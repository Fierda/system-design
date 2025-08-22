#!/bin/bash
set -e

# Install updates & dependencies
apt-get update -y
apt-get upgrade -y
apt-get install -y curl unzip amazon-cloudwatch-agent

# === CloudWatch Agent setup ===
cat <<EOF >/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
{
  "metrics": {
    "append_dimensions": {
      "AutoScalingGroupName": "\${aws:AutoScalingGroupName}",
      "InstanceId": "\${aws:InstanceId}"
    },
    "metrics_collected": {
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MemoryUtilization", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": [
          {"name": "disk_used_percent", "rename": "DiskUtilization", "unit": "Percent"}
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"]
      }
    }
  }
}
EOF

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# === Install Node.js (for frontend) ===
if [[ "$(hostname)" == *"fe"* ]]; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs

  mkdir -p /var/www/frontend
  cd /var/www/frontend
  # Example: fetch FE code from S3 or Git (you’d replace this)
  # aws s3 cp s3://mybucket/frontend.zip .
  # unzip frontend.zip && npm install && npm run build
  npm install pm2 -g
  pm2 start npm --name "frontend" -- start
  pm2 startup systemd
  pm2 save
fi

# === Install Go (for backend) ===
if [[ "$(hostname)" == *"be"* ]]; then
  wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
  tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
  echo "export PATH=$PATH:/usr/local/go/bin" >> /etc/profile
  export PATH=$PATH:/usr/local/go/bin

  mkdir -p /var/www/backend
  cd /var/www/backend
  # Example: fetch BE code from S3 or Git (replace with your pipeline)
  # aws s3 cp s3://mybucket/backend.tar.gz .
  # tar -xvzf backend.tar.gz && go build -o app .
  ./app &
fi
