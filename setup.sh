#!/bin/bash

# setup.sh - Initial setup script for Kubernetes GCP Terraform Lab
# This script handles the initial service account creation and authentication

set -e

PROJECT_ID=${1:-""}
REGION=${2:-"europe-west9"}

if [ -z "$PROJECT_ID" ]; then
    echo "Usage: $0 <PROJECT_ID> [REGION]"
    echo "Example: $0 my-gcp-project-123 europe-west9"
    exit 1
fi

echo "🚀 Setting up Kubernetes GCP Terraform Lab"
echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"

# Update terraform.tfvars with project details
cat > terraform.tfvars <<EOF
project_id = "$PROJECT_ID"
region = "$REGION"
credentials_file = "./terraform-admin-key.json"
worker_count = 2
EOF

echo "✅ Created terraform.tfvars"

# Create initial service account manually if it doesn't exist
SA_EMAIL="terraform-admin@${PROJECT_ID}.iam.gserviceaccount.com"

if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "📝 Creating initial Terraform admin service account..."
    
    gcloud iam service-accounts create terraform-admin \
        --display-name="Terraform Admin Service Account" \
        --project="$PROJECT_ID"
    
    echo "⏳ Waiting for service account to be ready..."
    sleep 10
    
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="roles/editor"
    
    gcloud iam service-accounts keys create ./terraform-admin-key.json \
        --iam-account="$SA_EMAIL" \
        --project="$PROJECT_ID"
    
    echo "✅ Created service account and downloaded key"
else
    echo "ℹ️  Service account already exists"
    if [ ! -f "./terraform-admin-key.json" ]; then
        echo "📝 Creating new service account key..."
        gcloud iam service-accounts keys create ./terraform-admin-key.json \
            --iam-account="$SA_EMAIL" \
            --project="$PROJECT_ID"
        echo "✅ Downloaded service account key"
    fi
fi

# Set environment variable for Terraform
export GOOGLE_APPLICATION_CREDENTIALS="$(pwd)/terraform-admin-key.json"
echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$(pwd)/terraform-admin-key.json\"" >> ~/.bashrc

echo "🔧 Initializing Terraform..."
terraform init

echo "📋 Planning Terraform deployment..."
terraform plan

echo ""
echo "🎉 Setup complete! Next steps:"
echo "1. Review the Terraform plan above"
echo "2. Apply the infrastructure: terraform apply"
echo "3. Run the Kubernetes bootstrap: cd ../k8s-bootstrap && ansible-playbook -i inventory/hosts.yaml playbooks/install_kubernetes.yml"
echo ""
echo "Environment variable set:"
echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$(pwd)/terraform-admin-key.json\""