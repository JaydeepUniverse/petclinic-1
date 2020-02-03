#### Application Programming Language - Java Spring Boot
#### DevOps Tools Installation Platform - AWS EKS
#### Administration VM - AWS EC2 Ubuntu for Helm, Kubectl etc.
#### Network file system to share data among kubernetes nodes - AWS EFS
#### CI - Jenkins
#### CD - Spinnaker
#### Package Manager for Kubernetes - Helm
#### Artifact Repository Tool - Jfrog Artifactory

## EKS
 - How to provision using Console
   - https://docs.aws.amazon.com/eks/latest/userguide/getting-started-console.html
   - Create your Amazon EKS Cluster VPC
     - Public and Private subnet
   - Create Your Amazon EKS Cluster
   - Create a kubeconfig File
   - Launch a managed node group
   - Create Cluster Autoscaler for auto VMs provisioning - https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
     - Cluster Autoscaler Node group Considerations
     - Deploy the Cluster Autoscaler
     
## Administration VM AWS EC2 Ubuntu
 - How to provision using console
   - Straight forward EC2 instance provisioning steps - **just make sure that**
     - provision in the same vpc in which kubernetes is provisioned and 
     - enable public ip assignment
