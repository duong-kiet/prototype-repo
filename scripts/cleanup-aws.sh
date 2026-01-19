#!/bin/bash
# ===================================================
# AWS Cleanup Script - Xóa tất cả resources của project
# ===================================================
# Usage: ./cleanup-aws.sh [project-name] [region]
# Example: ./cleanup-aws.sh security-pipeline ap-southeast-1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME="${1:-security-pipeline}"
AWS_REGION="${2:-ap-southeast-1}"

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}   AWS Cleanup Script                   ${NC}"
echo -e "${YELLOW}=========================================${NC}"
echo ""
echo -e "Project: ${GREEN}${PROJECT_NAME}${NC}"
echo -e "Region:  ${GREEN}${AWS_REGION}${NC}"
echo ""

# Check AWS credentials
echo -e "${YELLOW}[0/10] Checking AWS credentials...${NC}"
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ AWS credentials OK${NC}"
echo ""

# 1. Delete ECS Service & Cluster
echo -e "${YELLOW}[1/10] Deleting ECS Service & Cluster...${NC}"
aws ecs update-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --desired-count 0 --region $AWS_REGION 2>/dev/null || true
aws ecs delete-service --cluster ${PROJECT_NAME}-cluster --service ${PROJECT_NAME}-service --force --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ ECS Service deleted${NC}" || echo -e "${YELLOW}⚠️ No ECS Service${NC}"
echo "   Waiting 10s for service to drain..."
sleep 10
aws ecs delete-cluster --cluster ${PROJECT_NAME}-cluster --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ ECS Cluster deleted${NC}" || echo -e "${YELLOW}⚠️ No ECS Cluster${NC}"
echo ""

# 2. Delete ECR Repository
echo -e "${YELLOW}[2/10] Deleting ECR Repository...${NC}"
aws ecr delete-repository --repository-name ${PROJECT_NAME}-app --force --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ ECR Repository deleted${NC}" || echo -e "${YELLOW}⚠️ No ECR Repository${NC}"
echo ""

# 3. Delete Load Balancer
echo -e "${YELLOW}[3/10] Deleting Load Balancer...${NC}"
ALB_ARN=$(aws elbv2 describe-load-balancers --region $AWS_REGION --query "LoadBalancers[?LoadBalancerName=='${PROJECT_NAME}-alb'].LoadBalancerArn" --output text 2>/dev/null)
if [ -n "$ALB_ARN" ] && [ "$ALB_ARN" != "None" ]; then
    aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region $AWS_REGION
    echo -e "${GREEN}✅ Load Balancer deleted${NC}"
    echo "   Waiting 20s for ALB to fully delete..."
    sleep 20
else
    echo -e "${YELLOW}⚠️ No Load Balancer${NC}"
fi
echo ""

# 4. Delete Target Group
echo -e "${YELLOW}[4/10] Deleting Target Group...${NC}"
TG_ARN=$(aws elbv2 describe-target-groups --region $AWS_REGION --query "TargetGroups[?TargetGroupName=='${PROJECT_NAME}-tg'].TargetGroupArn" --output text 2>/dev/null)
if [ -n "$TG_ARN" ] && [ "$TG_ARN" != "None" ]; then
    aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region $AWS_REGION
    echo -e "${GREEN}✅ Target Group deleted${NC}"
else
    echo -e "${YELLOW}⚠️ No Target Group${NC}"
fi
echo ""

# 5. Find VPC
echo -e "${YELLOW}[5/10] Finding VPC...${NC}"
VPC_ID=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=tag:Name,Values=${PROJECT_NAME}-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
if [ -z "$VPC_ID" ] || [ "$VPC_ID" == "None" ]; then
    echo -e "${YELLOW}⚠️ No VPC found with name ${PROJECT_NAME}-vpc${NC}"
else
    echo -e "${GREEN}Found VPC: $VPC_ID${NC}"
    
    # 6. Delete NAT Gateway
    echo ""
    echo -e "${YELLOW}[6/10] Deleting NAT Gateway...${NC}"
    NAT_ID=$(aws ec2 describe-nat-gateways --region $AWS_REGION --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available,pending" --query 'NatGateways[0].NatGatewayId' --output text 2>/dev/null)
    if [ -n "$NAT_ID" ] && [ "$NAT_ID" != "None" ]; then
        aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" --region $AWS_REGION
        echo -e "${GREEN}✅ NAT Gateway deletion initiated${NC}"
        echo "   Waiting 60s for NAT Gateway to delete..."
        sleep 60
    else
        echo -e "${YELLOW}⚠️ No NAT Gateway${NC}"
    fi
    
    # 7. Delete Internet Gateway
    echo ""
    echo -e "${YELLOW}[7/10] Deleting Internet Gateway...${NC}"
    IGW_ID=$(aws ec2 describe-internet-gateways --region $AWS_REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
    if [ -n "$IGW_ID" ] && [ "$IGW_ID" != "None" ]; then
        aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region $AWS_REGION
        aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region $AWS_REGION
        echo -e "${GREEN}✅ Internet Gateway deleted${NC}"
    else
        echo -e "${YELLOW}⚠️ No Internet Gateway${NC}"
    fi
    
    # 8. Delete Subnets
    echo ""
    echo -e "${YELLOW}[8/10] Deleting Subnets...${NC}"
    for SUBNET_ID in $(aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text); do
        aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ Deleted $SUBNET_ID${NC}"
    done
    
    # Delete Route Tables (non-main)
    echo ""
    echo -e "${YELLOW}[8b/10] Deleting Route Tables...${NC}"
    for RT_ID in $(aws ec2 describe-route-tables --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'RouteTables[?Associations[0].Main!=`true`].RouteTableId' --output text); do
        aws ec2 delete-route-table --route-table-id "$RT_ID" --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ Deleted $RT_ID${NC}"
    done
    
    # Delete Security Groups (non-default)
    echo ""
    echo -e "${YELLOW}[8c/10] Deleting Security Groups...${NC}"
    for SG_ID in $(aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text); do
        aws ec2 delete-security-group --group-id "$SG_ID" --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ Deleted $SG_ID${NC}"
    done
    
    # Release Elastic IPs
    echo ""
    echo -e "${YELLOW}[8d/10] Releasing Elastic IPs...${NC}"
    EIP_ALLOC=$(aws ec2 describe-addresses --region $AWS_REGION --filters "Name=tag:Name,Values=${PROJECT_NAME}-nat-eip" --query 'Addresses[0].AllocationId' --output text 2>/dev/null)
    if [ -n "$EIP_ALLOC" ] && [ "$EIP_ALLOC" != "None" ]; then
        aws ec2 release-address --allocation-id "$EIP_ALLOC" --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ Elastic IP released${NC}"
    fi
    
    # 9. Delete VPC
    echo ""
    echo -e "${YELLOW}[9/10] Deleting VPC...${NC}"
    aws ec2 delete-vpc --vpc-id "$VPC_ID" --region $AWS_REGION && echo -e "${GREEN}✅ VPC deleted${NC}" || echo -e "${RED}❌ Failed to delete VPC${NC}"
fi
echo ""

# 10. Delete IAM Roles & CloudWatch Logs
echo -e "${YELLOW}[10/10] Deleting IAM Roles & CloudWatch Logs...${NC}"
aws iam detach-role-policy --role-name ${PROJECT_NAME}-ecs-task-execution --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy 2>/dev/null || true
aws iam delete-role --role-name ${PROJECT_NAME}-ecs-task-execution 2>/dev/null && echo -e "${GREEN}✅ Deleted ecs-task-execution role${NC}" || true
aws iam delete-role --role-name ${PROJECT_NAME}-ecs-task 2>/dev/null && echo -e "${GREEN}✅ Deleted ecs-task role${NC}" || true
aws logs delete-log-group --log-group-name /ecs/${PROJECT_NAME} --region $AWS_REGION 2>/dev/null && echo -e "${GREEN}✅ Deleted CloudWatch log group${NC}" || true

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   ✅ CLEANUP COMPLETE!                 ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""
echo "Optional: Clean Terraform state locally:"
echo "  cd terraform && rm -rf .terraform terraform.tfstate* .terraform.lock.hcl"

