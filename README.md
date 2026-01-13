# 🛡️ Security Pipeline Prototype

CI/CD Pipeline tích hợp bảo mật với **Trivy**, **Terraform**, và **Prowler**.

## 📁 Cấu trúc dự án

```
prototype-repo/
├── app/                           # Ứng dụng Flask
│   ├── app.py                     # Source code
│   └── requirements.txt           # Python dependencies
├── terraform/                     # Infrastructure as Code
│   ├── main.tf                    # Provider & backend config
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── vpc.tf                     # VPC, Subnets, NAT
│   ├── ecr.tf                     # Container Registry
│   └── ecs.tf                     # ECS Cluster, Service, ALB
├── .github/workflows/
│   └── security-pipeline.yml      # CI/CD Pipeline
├── Dockerfile                     # Container build
└── README.md
```

## 🔄 Pipeline Flow

```
┌──────────────┐    ┌─────────────────────┐    ┌───────────────────┐    ┌────────────────┐
│   Git Push   │───▶│  Stage 1: Trivy     │───▶│  Stage 2: Deploy  │───▶│ Stage 3: Audit │
│              │    │  (IaC + SCA + Docker)│    │  (Terraform + ECR)│    │   (Prowler)    │
└──────────────┘    └─────────────────────┘    └───────────────────┘    └────────────────┘
                              │                         │                        │
                              ▼                         ▼                        ▼
                    ❌ FAIL: Block Pipeline    ✅ PASS: Continue         📊 Security Report
```

### Stage 1: Trivy Security Scan
- **IaC Scan**: Kiểm tra Terraform files (Security Groups, S3 policies)
- **SCA Scan**: Kiểm tra dependencies (CVE vulnerabilities)
- **Docker Scan**: Kiểm tra Dockerfile (OS vulnerabilities)

### Stage 2: Terraform Deploy
- Tạo VPC, Subnets, NAT Gateway
- Tạo ECR Repository
- Tạo ECS Cluster, Service, ALB
- Build & Push Docker Image

### Stage 3: Prowler Audit
- Kiểm tra AWS compliance (CIS Benchmark)
- Audit IAM policies, MFA, CloudTrail
- Tạo báo cáo chi tiết

## 🚀 Quick Start

### Prerequisites
- AWS Account với IAM credentials
- Terraform >= 1.0.0
- Docker

### Local Development

```bash
# Chạy app local
cd app
pip install -r requirements.txt
python app.py
# Access: http://localhost:5000
```

### Deploy thủ công

```bash
# 1. Terraform
cd terraform
terraform init
terraform plan
terraform apply

# 2. Docker Build & Push
aws ecr get-login-password --region ap-southeast-1 | docker login --username AWS --password-stdin <ECR_URL>
docker build -t security-pipeline-app .
docker tag security-pipeline-app:latest <ECR_URL>:latest
docker push <ECR_URL>:latest

# 3. Update ECS
aws ecs update-service --cluster security-pipeline-cluster --service security-pipeline-service --force-new-deployment
```

## ⚙️ GitHub Secrets cần thiết

| Secret | Mô tả |
|--------|-------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key |

## 📊 Reports

Pipeline tạo ra 2 loại báo cáo:

1. **Trivy Reports** - Code & Image security
2. **Prowler Reports** - Cloud infrastructure compliance

Reports được lưu dưới dạng GitHub Artifacts.

## 🔧 Customization

### Thay đổi region
Edit `terraform/variables.tf`:
```hcl
variable "aws_region" {
  default = "ap-southeast-1"  # Change to your region
}
```

### Thay đổi resource sizing
Edit `terraform/variables.tf`:
```hcl
variable "container_cpu" {
  default = 256  # 256, 512, 1024, 2048, 4096
}

variable "container_memory" {
  default = 512  # Min 512 for Fargate
}
```

## 📝 License

MIT License

