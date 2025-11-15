#!/bin/bash

echo "=== Bygg och Push till ECR Script ==="
echo ""

# ÄNDRAT: Hårdkodat Account ID
AWS_ACCOUNT_ID="<YOUR-AWS-ACCOUNT-ID>"
AWS_REGION="eu-west-1"
ECR_REPO_NAME="dotnet-mvc-app"
IMAGE_TAG="latest"

echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo "AWS Region: $AWS_REGION"
echo "ECR Repository: $ECR_REPO_NAME"
echo ""

# Kontrollera om ECR repository finns
echo "Kontrollerar om ECR repository finns..."
aws ecr describe-repositories --repository-names $ECR_REPO_NAME --region $AWS_REGION 2>/dev/null

if [ $? -ne 0 ]; then
    echo "Skapar ECR repository..."
    aws ecr create-repository --repository-name $ECR_REPO_NAME --region $AWS_REGION
else
    echo "ECR repository finns redan."
fi

echo ""

# Logga in på ECR
echo "Loggar in på AWS ECR..."
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

if [ $? -ne 0 ]; then
    echo "❌ Fel: Kunde inte logga in på ECR"
    exit 1
fi

echo ""

# Bygg Docker image
echo "Bygger Docker image..."
cd ../webapp
docker build -t $ECR_REPO_NAME:$IMAGE_TAG .

if [ $? -ne 0 ]; then
    echo "❌ Fel: Kunde inte bygga Docker image"
    exit 1
fi

echo ""

# Tagga för ECR
echo "Taggar image för ECR..."
docker tag $ECR_REPO_NAME:$IMAGE_TAG \
    $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

echo ""

# Pusha till ECR
echo "Pushar image till ECR..."
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG

if [ $? -ne 0 ]; then
    echo "❌ Fel: Kunde inte pusha image"
    exit 1
fi

echo ""
echo "=== ✅ Klar! ==="
echo ""
echo "Image URL:"
echo "$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO_NAME:$IMAGE_TAG"
echo ""

# Uppdatera deployment.yaml automatiskt
echo "Uppdaterar k8s-manifests/deployment.yaml..."
cd ..
sed -i.bak "s|<YOUR-AWS-ACCOUNT-ID>|$AWS_ACCOUNT_ID|g" k8s-manifests/deployment.yaml

echo ""
echo "✅ deployment.yaml uppdaterad med ditt AWS Account ID"
echo ""
echo "Nästa steg: Kör ./deploy.sh för att deploya till Kubernetes"