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

The infrastructure features a **High Availability (HA)** design with **3 control plane nodes** distributed across multiple availability zones for production-grade reliability:
- **Control Plane Cluster**: 3 nodes spread across zones (a, b, c) for redundancy
- **Dual Load Balancer Setup**: External and internal TCP load balancers for API server access
- **Worker Nodes**: Distributed across availability zones for high availability
- **Stacked etcd**: 3-member etcd cluster on control plane nodes (quorum-based)
- **Multi-Zone Resilience**: Survives zone failures with automatic failover

### HA Network Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                         GCP Project - HA Cluster                            │
│                                                                              │
│  ┌────────────────────────────────────────────────────────────────────────┐│
│  │                    VPC Network (tf-vpc) - 9.0.0.0/16                   ││
│  │                                                                          ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  Regional TCP Load Balancer (External) - 34.155.143.202:6443   │   ││
│  │  │  • kubectl/API access from internet                              │   ││
│  │  │  • Health checks on all 3 control planes                         │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │  ┌─────────────────────────────────────────────────────────────────┐   ││
│  │  │  Regional TCP Load Balancer (Internal) - 9.0.1.6:6443          │   ││
│  │  │  • Node-to-API communication within VPC                          │   ││
│  │  │  • Solves GCP hairpinning limitation                             │   ││
│  │  └─────────────────────────────────────────────────────────────────┘   ││
│  │                                                                          ││
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     ││
│  │  │   Zone A         │  │   Zone B         │  │   Zone C         │     ││
│  │  │ europe-west9-a   │  │ europe-west9-b   │  │ europe-west9-c   │     ││
│  │  │                  │  │                  │  │                  │     ││
│  │  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │ ┌──────────────┐ │     ││
│  │  │ │control-plane-│ │  │ │control-plane-│ │  │ │control-plane-│ │     ││
│  │  │ │      1       │ │  │ │      2       │ │  │ │      3       │ │     ││
│  │  │ │  e2-medium   │ │  │ │  e2-medium   │ │  │ │  e2-medium   │ │     ││
│  │  │ │  etcd member │ │  │ │  etcd member │ │  │ │  etcd member │ │     ││
│  │  │ └──────────────┘ │  │ └──────────────┘ │  │ └──────────────┘ │     ││
│  │  │                  │  │                  │  │                  │     ││
│  │  │ ┌──────────────┐ │  │ ┌──────────────┐ │  │                  │     ││
│  │  │ │ k8s-worker-1 │ │  │ │ k8s-worker-2 │ │  │                  │     ││
│  │  │ │  e2-medium   │ │  │ │  e2-medium   │ │  │                  │     ││
│  │  │ └──────────────┘ │  │ └──────────────┘ │  │                  │     ││
│  │  └──────────────────┘  └──────────────────┘  └──────────────────┘     ││
│  └──────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────┘
```

### Infrastructure Components

#### 1. **Virtual Private Cloud (VPC)**
- **Name**: `tf-vpc`
- **Purpose**: Isolated network environment for the HA Kubernetes cluster
- **CIDR**: `9.0.0.0/16`
- **Configuration**: Custom VPC with subnet-a for all nodes

#### 2. **Subnets**
- **Subnet A** (`tf-subnet-a`): 
  - CIDR: `9.0.1.0/24`
  - Purpose: Hosts all 3 control planes and worker nodes
  - Region: `europe-west9`
  - Design: Single subnet simplifies networking while zones provide HA

#### 3. **Load Balancers (Dual Setup)**
- **External TCP Load Balancer**:
  - IP: `34.155.143.202` (example)
  - Port: `6443` (Kubernetes API)
  - Purpose: kubectl/API access from internet
  - Scheme: `EXTERNAL`
  - Health Check: TCP probe on port 6443 every 5s
  
- **Internal TCP Load Balancer**:
  - IP: `9.0.1.6` (within VPC)
  - Port: `6443` (Kubernetes API)
  - Purpose: Node-to-API communication (solves GCP hairpinning)
  - Scheme: `INTERNAL`
  - Global Access: Enabled for cross-region scenarios
  - Health Check: Separate TCP probe on port 6443

- **Health Check Configuration**:
  - Source IPs: `35.191.0.0/16`, `130.211.0.0/22` (GCP-owned permanent ranges)
  - Firewall: Allows health check traffic to control-plane tagged instances

#### 4. **Compute Instances - HA Control Plane**
- **Count**: 5 virtual machines (3 control planes + 2 workers)
- **Control Planes**: 
  - `control-plane-1` (zone: europe-west9-a, etcd member)
  - `control-plane-2` (zone: europe-west9-b, etcd member)
  - `control-plane-3` (zone: europe-west9-c, etcd member)
- **Worker Nodes**: 
  - `k8s-worker-1` (zone: europe-west9-a)
  - `k8s-worker-2` (zone: europe-west9-b)
- **Machine Type**: `e2-medium` (2 vCPUs, 4GB RAM)
- **Operating System**: Ubuntu 22.04 LTS
- **Disk**: 10GB persistent boot disk per instance
- **Zone Distribution**: Control planes spread across 3 zones for zone failure tolerance

#### 5. **Security Configuration**
- **Firewall Rules**:
  - `allow-internal`: Permits all internal communication within the VPC
  - `allow-ssh`: Allows SSH access (port 22) from any IP address
  - `allow-k8s-api`: Allows access to Kubernetes API (port 6443)
  - `allow-health-checks`: Allows GCP health check probes from `35.191.0.0/16` and `130.211.0.0/22`
- **Service Account**: Dedicated service account for Kubernetes nodes with cloud-platform scope
- **SSH Access**: Configured with public key authentication
- **Network Tags**: `control-plane` tag for targeted firewall rules

#### 6. **High Availability Features**
- **etcd Quorum**: 3-member cluster (tolerates 1 failure, requires 2 for quorum)
- **API Server Redundancy**: 3 API servers load-balanced
- **Zone Distribution**: Survives single zone failure
- **Automatic Failover**: Load balancer redirects traffic to healthy control planes
- **Certificate Management**: Shared certificates via `kubeadm init --upload-certs`

## File Structure

```
k8s-gcp-terraform-lab/
├── main.tf                    # Terraform configuration and backend setup
├── variables.tf               # Variable definitions (region, zones, machine types)
├── locals.tf                  # Local values for control plane configuration
├── terraform.tfvars.example   # Example variables file (copy to terraform.tfvars)
├── backend.conf.example       # Example backend config (copy to backend.conf)
├── network.tf                 # VPC, subnets, firewall rules, and DUAL load balancers
├── compute.tf                 # HA control planes (3x) and worker VMs
├── iam.tf                     # Service accounts and IAM bindings
├── outputs.tf                 # Output values (IPs, load balancer addresses)
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

**Customization Options:**
- Adjust `worker_count` in `terraform.tfvars` to change number of worker nodes (default: 2)
- Workers are automatically distributed across subnets and zones for high availability

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

- **Estimated Monthly Cost**: ~$160-180 USD for HA setup:
  - 3 control planes (e2-medium): ~$75/month
  - 2 workers (e2-medium): ~$50/month
  - 2 TCP load balancers: ~$20/month
  - 5 persistent disks (10GB each): ~$5/month
  - Networking/egress: ~$10/month
- **Cost Optimization**: 
  - **vs Single Control Plane**: HA adds ~$85/month but provides production-grade reliability
  - Instances sized for testing, not production workloads
  - Consider preemptible instances for dev/test environments (save ~60%)
  - Internal LB has no cost for traffic within same region
  - **Remember to destroy resources when not in use**: `terraform destroy`
- **Production Considerations**:
  - HA cluster survives zone failures (worth the cost for production)
  - Single control plane: ~$75/month (no HA, no failover)
  - For learning/testing, single control plane may be sufficient

## Next Steps

After infrastructure deployment, you'll have a production-ready HA cluster infrastructure. Follow the [k8s-bootstrap](https://github.com/mehenna/k8s-bootstrap) project to deploy Kubernetes:

1. **Bootstrap HA Kubernetes**: Use Ansible playbooks to initialize the 3-node control plane cluster
2. **Configure CNI**: Install Calico with VXLAN networking
3. **Join Workers**: Add worker nodes to the cluster
4. **Verify HA**: Test failover by stopping one control plane
5. **Access Cluster**: Use external LB IP for kubectl commands

**Recommended Resources:**
- [HA_DEPLOYMENT_GUIDE.md](https://github.com/mehenna/k8s-bootstrap/blob/feature/high_availability_cluster/HA_DEPLOYMENT_GUIDE.md) - Complete deployment walkthrough
- [ISSUES_FACED.md](https://github.com/mehenna/k8s-bootstrap/blob/feature/high_availability_cluster/ISSUES_FACED.md) - Architectural evolution and troubleshooting
- [DEPLOYMENT_SUMMARY.md](https://github.com/mehenna/k8s-bootstrap/blob/feature/high_availability_cluster/DEPLOYMENT_SUMMARY.md) - Cluster overview and validation

## Troubleshooting

### Common Issues

1. **Authentication Errors**: Verify service account permissions and key file path
2. **SSH Connection Issues**: Check firewall rules and SSH key configuration
3. **Resource Quotas**: Ensure your GCP project has sufficient compute quotas

### Useful Commands

```bash
# Check all instances status
gcloud compute instances list

# SSH to control planes
gcloud compute ssh control-plane-1 --zone=europe-west9-a
gcloud compute ssh control-plane-2 --zone=europe-west9-b
gcloud compute ssh control-plane-3 --zone=europe-west9-c

# SSH to workers
gcloud compute ssh k8s-worker-1 --zone=europe-west9-a
gcloud compute ssh k8s-worker-2 --zone=europe-west9-b

# Check load balancers
gcloud compute forwarding-rules list
gcloud compute backend-services list
gcloud compute health-checks list

# View firewall rules
gcloud compute firewall-rules list

# Test external load balancer (from your local machine)
curl -k https://<EXTERNAL_LB_IP>:6443/version

# Test internal load balancer (from any control plane)
curl -k https://9.0.1.6:6443/version
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