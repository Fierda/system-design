# TASK 2
## EC2 Template on modules

```bash
terraform init
terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"
```

## Helm Chart

```bash
helm install ecommerce ./helm_microservice -n mynamespace
```

# TASK 3

```bash
# Install boto3 for AWS Integration
pip install boto3

# Analyze local log file
python nginx_analyzer.py /var/log/nginx/access.log 
  
# Analyze CloudWatch logs
python nginx_analyzer.py my-log-group --cloudwatch --region ap-southeast-3
  
# Export results to JSON
python nginx_analyzer.py /var/log/nginx/access.log --output report.json
```

# TASK 4

```bash
1. git push origin main

2. git push origin develop

3. git checkout -b feature/my-new-feature
    git add .
    git commit -m "Add new feature"
    git push origin feature/my-new-feature
    gh pr create --base main --head feature/my-new-feature --title "Add new feature" --body "Please accept and deploy it, its Friday"
```