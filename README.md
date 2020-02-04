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
     
## Helm: Install on Administration VM
 - https://github.com/JaydeepUniverse/automation/blob/master/helm.yaml

## Jenkins: Install on EKS using Helm
 - Create storageClass.yaml
 - Create persistentVolumeClaim.yaml
 - Get jenkins helm chart values
   - `helm inspect values stable/jenkins > /tmp/jenkins.values`
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
 
## Jfrog Artifactory: Install on EKS
 - Create S3 bucket for storage purpose ***<< Confirm this functionality***
 - First add jfrog required repository
   - `helm repo add jfrog https://charts.jfrog.io`
 - Get artifactory helm chart values
   - `helm inspect values jfrog/artifactory > /tmp/artifactory.values`
 - Append this file with below parameters
   ```
   artifactory:
     resources: {}
       requests:
         memory: "1Gi"
         cpu: "500m"
       limits:
         memory: "4Gi"
         cpu: "2"
     javaOpts:
       xms: "1g"
       xmx: "4g"
   nginx:
     resources: {}
       requests:
         memory: "250Mi"
         cpu: "100m"
       limits:
         memory: "500Mi"
         cpu: "250m"
    ``` 
    ***Confirm below functionality***
    ```
    awsS3V3:
      identity: awsAccessKey
      credential: awsSecretKey
      region: ap-southeast-1
      bucketName: s3BucketName
      endpoint: s3.ap-southeast-1.amazonaws.com
   ```
 - Install
   - `helm install myartifactory  jfrog/artifactory --values /tmp/artifactory.values`

## Spinnaker: Install on EKS
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
 
## Spinnaker: Configure to Expose Publicly
 - Straight forward steps from https://docs.armory.io/spinnaker/exposing_spinnaker/
 
## Spinnaker: Configure on HTTPS
 - Straight forward steps from	https://www.spinnaker.io/setup/security/ssl/#server-terminated-ssl
 - **Make sure to increase --liveness-probe-initial-delay-seconds to 600s in the command**  
   - `hal config deploy edit --liveness-probe-enabled true --liveness-probe-initial-delay-seconds 600`
   
## Jenkins: Create Multibranch CI pipeline
 - Create credentials to authenticate to git repository
   - Jenkins > Credentials > System > Global credentials > Add credentials
     - Scope: Global
     - Username: Username of the git repository
     - Password: Password of git repository
     - ID: ID(name) to be used to select in job configuration
     - Description: description
 - Jenkins > new job > multibranch type > git > url, credentials > save
 - This job will automatically fetch all branch names from git and create separate jobs for each branch wise
 
 ## Spinnaker: Create CD pipeline
 - Before creating spinnaker pipeline, first create kubernetes secret to pull the image from private docker registry
   - Create under same namespace same as other resources created
   - Refer https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
 - Spinnaker > applications > create new application
 - Spinnaker > projects > create new project
   - select the application created above, **if application name is not visible then refresh the page and try**
 - go to created application > pipelines > add stage
   - type: deploy (manifest)
   - stage name
   - account name: drop down would show account name while installing spinnaker, select the one
     - Adding an Account from https://www.spinnaker.io/setup/install/providers/kubernetes-v2/#adding-an-account
   - manifest configuration: copy and paste namespace.yaml file from this project
 - Similarly create 2 more stages for service.yaml, deployment.yaml
 
 ## Jenkins-Spinnaker: Integration
  - Refer https://www.spinnaker.io/setup/ci/jenkins/#add-your-jenkins-master
    - **If the password does not work then provide token**
  - Then in spinnaker application created above, do configuration according to https://www.spinnaker.io/guides/user/pipeline/triggers/jenkins/
  - For the properties file: provide the name "build_properties.yaml", this is from jenkinsfile
  
  
## CICD covered features
- Versioning
  - pom.xml > properties > `<version.number>${env.BUILD_NUMBER}</version.number>` provided which is docker image tag and same has been referenced further in fabric8 > docker-maven-plugin > configurations
  - jenkinsfile creates build_properties.yaml file which forward the same build_number to spinnaker 
  ```
  stage("Create spinnaker properties file"){
    steps{
      sh """
        echo "---
        BUILD_NUMBER: '${BUILD_NUMBER}'
        " > build_properties.yaml
      """
    }
  }
  ```
  - spinnaker > application > pipeline > deployment stage > deployment.yaml file>  container section > `${trigger["properties"]["BUILD_NUMBER"]}` provided
