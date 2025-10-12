# Kubernetes GCP Terraform Lab

> 🚀 **A complete Terraform setup for deploying Kubernetes infrastructure on Google Cloud Platform**

[![Terraform](https://img.shields.io/badge/Terraform-v1.5%2B-623CE4?logo=terraform)](https://terraform.io)
[![Google Cloud](https://img.shields.io/badge/Google_Cloud-Ready-4285F4?logo=google-cloud)](https://cloud.google.com)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Learning_Lab-326CE5?logo=kubernetes)](https://kubernetes.io)
[![CKA/CKS](https://img.shields.io/badge/Certification-CKA%2FCKS-FF6B35)](https://kubernetes.io/training/)

## Project Aims

This project provisions a Google Cloud Platform (GCP) infrastructure designed for hosting a Kubernetes cluster. The infrastructure is specifically tailored for **CKA (Certified Kubernetes Administrator)** and **CKS (Certified Kubernetes Security Specialist)** certification training and practice environments.

### Key Objectives

- **Learning Environment**: Create a cost-effective, reproducible Kubernetes cluster for certification study
- **Multi-node Setup**: Provision multiple nodes to practice cluster administration tasks
- **Network Segregation**: Distribute nodes across multiple subnets for advanced networking scenarios
- **Security Focus**: Implement proper network segmentation and security groups for CKS practice
- **Infrastructure as Code**: Use Terraform for consistent, version-controlled infrastructure deployment

## Architecture Overview

The infrastructure features a **multi-subnet design** with nodes distributed across different network segments:
- **Control Plane**: Isolated in subnet-a for administrative access
- **Worker Nodes**: Split between subnet-a and subnet-b for workload segregation
- **Cross-Subnet Communication**: Enabled for Kubernetes cluster networking

### Network Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GCP Project                              │
│                your-gcp-project-id                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                VPC Network (tf-vpc)                     ││
│  │                                                         ││
│  │  ┌──────────────────┐    ┌──────────────────────────┐   ││
│  │  │   Subnet A       │    │      Subnet B            │   ││
│  │  │   tf-subnet-a    │    │      tf-subnet-b         │   ││
│  │  │   9.0.1.0/24     │    │      9.0.2.0/24          │   ││
│  │  │                  │    │                          │   ││
│  │  │ ┌──────────────┐ │    │ ┌──────────────────────┐ │   ││
│  │  │ │control-plane │ │    │ │    k8s-worker-2      │ │   ││
│  │  │ │  e2-medium   │ │    │ │    e2-medium         │ │   ││
│  │  │ └──────────────┘ │    │ └──────────────────────┘ │   ││
│  │  │ ┌──────────────┐ │    │                          │   ││
│  │  │ │ k8s-worker-1 │ │    │   (Additional capacity   │   ││
│  │  │ │  e2-medium   │ │    │    for workload          │   ││
│  │  │ └──────────────┘ │    │    segregation)          │   ││
│  │  └──────────────────┘    └──────────────────────────┘   ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### Infrastructure Components

#### 1. **Virtual Private Cloud (VPC)**
- **Name**: `tf-vpc`
- **Purpose**: Isolated network environment for the Kubernetes cluster
- **Configuration**: Custom VPC with manual subnet creation

#### 2. **Subnets**
- **Subnet A** (`tf-subnet-a`): 
  - CIDR: `9.0.1.0/24`
  - Purpose: Hosts control plane and first worker node
  - Region: `europe-west9`
- **Subnet B** (`tf-subnet-b`): 
  - CIDR: `9.0.2.0/24`
  - Purpose: Hosts second worker node for workload segregation

#### 3. **Compute Instances**
- **Count**: 3 virtual machines
- **Control Plane**: `k8s-control-plane` (in subnet-a, zone europe-west9-a)
- **Worker Nodes**: 
  - `k8s-worker-1` (in subnet-a, zone europe-west9-a)
  - `k8s-worker-2` (in subnet-b, zone europe-west9-b)
- **Machine Type**: `e2-medium` (2 vCPUs, 4GB RAM)
- **Operating System**: Ubuntu 22.04 LTS
- **Disk**: 20GB persistent boot disk

#### 4. **Security Configuration**
- **Firewall Rules**:
  - `allow-internal`: Permits all internal communication within the VPC
  - `allow-ssh`: Allows SSH access (port 22) from any IP address
- **Service Account**: Dedicated service account for Kubernetes nodes with cloud-platform scope
- **SSH Access**: Configured with public key authentication

#### 5. **Instance Template**
- **Purpose**: Standardized configuration for creating additional nodes
- **Features**: 
  - IP forwarding enabled (required for Kubernetes networking)
  - Consistent tagging for resource management
  - Automated service account assignment

## File Structure

```
k8s-gcp-terraform-lab/
├── main.tf                    # Terraform configuration and backend setup
├── variables.tf               # Variable definitions (no sensitive defaults)
├── terraform.tfvars.example   # Example variables file (copy to terraform.tfvars)
├── backend.conf.example       # Example backend config (copy to backend.conf)
├── network.tf                 # VPC, subnets, and firewall rules
├── compute.tf                 # VM instances and instance templates
├── outputs.tf                 # Output values for infrastructure components
├── .gitignore                 # Excludes sensitive files from version control
└── terraform-admin.json       # GCP service account credentials (NOT in repo)
```

## Security Features

✅ **Sensitive data protection:**
- All credentials excluded via `.gitignore`
- No hardcoded project IDs or secrets in code
- Example configuration files provided
- Terraform state can be stored remotely (GCS backend)

## Why This Project Name?

**`k8s-gcp-terraform-lab`** - This name was chosen for maximum discoverability on GitHub:
- **`k8s`**: Standard abbreviation for Kubernetes, widely searchable
- **`gcp`**: Clearly indicates Google Cloud Platform
- **`terraform`**: Infrastructure as Code tool used
- **`lab`**: Indicates this is for learning/experimentation

Perfect for developers searching for: "kubernetes terraform", "gcp k8s", "terraform lab", "kubernetes certification setup"

## Prerequisites

1. **Google Cloud Platform Account** with billing enabled
2. **Terraform** v1.5.0 or later installed locally
3. **GCP Service Account** with appropriate permissions:
   - Compute Admin
   - Service Account User
   - Project Editor
4. **SSH Key Pair** generated and available at `~/.ssh/id_rsa.pub`

## Deployment Instructions

### 1. Clone and Setup
```bash
git clone https://github.com/YOUR_USERNAME/k8s-gcp-terraform-lab.git
cd k8s-gcp-terraform-lab
```

### 2. Configure Credentials
```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your actual values
nano terraform.tfvars

# Optional: Configure backend for remote state storage
cp backend.conf.example backend.conf
nano backend.conf
```

**Important Security Notes:**
- Place your GCP service account JSON key as `terraform-admin.json` in the project root directory
- The `terraform.tfvars` file will contain your project ID and should NEVER be committed to version control
- The `backend.conf` file will contain your bucket name and should also be private
- Ensure your SSH public key is available at `~/.ssh/id_rsa.pub`

### 3. Initialize Terraform
```bash
# Initialize with backend configuration
terraform init -backend-config=backend.conf
```

### 4. Review and Plan
```bash
terraform plan
```

### 5. Deploy Infrastructure
```bash
terraform apply
```

### 6. Access Your Nodes
After deployment, use the output IP addresses to SSH into your nodes:
```bash
ssh ubuntu@<node-ip-address>
```

## Cost Considerations

- **Estimated Monthly Cost**: ~$60-90 USD (3 x e2-medium instances)
- **Cost Optimization**: 
  - Instances are sized for learning/testing, not production workloads
  - Consider using preemptible instances for additional savings
  - Remember to destroy resources when not in use: `terraform destroy`

## Next Steps

After infrastructure deployment:

1. **Install Kubernetes**: Set up kubeadm, kubelet, and kubectl on all nodes
2. **Initialize Cluster**: Create the master node and join worker nodes
3. **Configure Networking**: Install a CNI plugin (Calico, Flannel, etc.)
4. **Practice CKA/CKS Tasks**: Use the cluster for certification preparation

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify service account permissions and key file path
2. **SSH Connection Issues**: Check firewall rules and SSH key configuration
3. **Resource Quotas**: Ensure your GCP project has sufficient compute quotas

### Useful Commands

```bash
# Check instance status
gcloud compute instances list

# SSH to a specific node
gcloud compute ssh k8s-node-1 --zone=europe-west9-a

# View firewall rules
gcloud compute firewall-rules list
```

## Security Notes

- SSH access is currently open to all IP addresses (0.0.0.0/0)
- For production use, restrict SSH access to specific IP ranges
- Consider implementing additional security hardening for CKS practice scenarios

## Contributing

Feel free to submit issues and enhancement requests. This infrastructure template is designed to be educational and can be extended based on specific learning requirements.

## Repository Topics

When uploading to GitHub, consider adding these topics for better discoverability:
`kubernetes` `terraform` `gcp` `google-cloud` `infrastructure-as-code` `cka` `cks` `certification` `devops` `learning-lab`

## License

This project is intended for educational purposes as part of Kubernetes certification preparation.