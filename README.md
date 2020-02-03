#### Application Programming Language - Java Spring Boot
#### DevOps Tools Installation Platform - AWS EKS
#### Administration VM - AWS EC2 Ubuntu for Helm, Kubectl, Halyard, AWS CLI etc.
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
     
## Install Helm on Administration VM
 - https://github.com/JaydeepUniverse/automation/blob/master/helm.yaml

## Install Spinnaker on EKS
 - Straight forward steps from https://www.spinnaker.io/setup/install/
 - Install Halyard
   - provide the username by which want to run halyard/spinnaker service
 - Choose Cloud Provider > Kubernetes(Manifest Based)
   - Optional: Create a Kubernetes Service Account
   - Optional: Configure Kubernetes Roles (RBAC)
   - Adding an account
 - Choose an Environment > Distributed Installation
   - **Make sure to run last optional command as well with 60s value**
 - Choose a Storage Service
   - S3
     - **Make sure to add `--bucket s3BucketName` in the command else random name bucket will created**
 - Deploy and Connect
 
## Configure Spinnaker to Expose Publicly
 - Straight forward steps from https://docs.armory.io/spinnaker/exposing_spinnaker/
 
## Configure Spinnaker on HTTPS
 - Straight forward steps from	https://www.spinnaker.io/setup/security/ssl/#server-terminated-ssl
 - **Make sure to increase --liveness-probe-initial-delay-seconds to 600s in the command**  
   - `hal config deploy edit --liveness-probe-enabled true --liveness-probe-initial-delay-seconds 600`


## Install Jenkins on EKS using Helm
 - Create storageClass.yaml
 - Create persistentVolumeClaim.yaml
 - Get jenkins helm chart values
   - `helm inspect values stable/jenkins > /tmp/jenkinsvalues`
 - Append this file with below parameters
   ```
   namespaceOverride: devops-tools
   master
    serviceType: LoadBalancer
   slaveKubernetesNamespace: devops-tools
   existingClaim: jenkins-pvc
   storageClass: jenkins-storage-class
   adminPassword: admin
   ```
 - Install
   - `helm install myjenkins stable/jenkins --values /tmp/jenkins.values`
