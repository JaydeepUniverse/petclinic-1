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

## EFS
- AWS > select region same as EKS > EFS > Create > VPC of the same as EKS > select **private subnets** > Tags > rest all configurations as it is > create

## Administration VM AWS EC2 Ubuntu
 - How to provision using console
   - Straight forward EC2 instance provisioning steps - **just make sure that**
     - provision in the same vpc in which kubernetes is provisioned and
     - enable public ip assignment

## Helm: Install on Administration VM
 - https://github.com/JaydeepUniverse/automation/blob/master/helm.yaml

## Jenkins: Install on EKS using Helm
 - Create jenkinsPersistentVolumeClaim.yaml
 - Create jenkinsStorageClass.yaml
 - Get jenkins helm chart values
   - `helm inspect values stable/jenkins > /tmp/jenkins.values`
 - Append this file with below parameters
   ```
   namespaceOverride: jenkins
   master
    serviceType: LoadBalancer
   slaveKubernetesNamespace: jenkins
   existingClaim: jenkins
   storageClass: jenkins
   adminPassword: admin
   ```
 - Install
   - `helm install myjenkins stable/jenkins --values /tmp/jenkins.values`

## Jenkins: Configurations
- Manage jenkins > cloud > kubernetes >
  - jenkins url: http://k8sServiceName.namespaceOfJenkins:8080 ex. `http://myjenkins.devops-tools:8080`
  ```diff
  - verify this and change accordingly
  ```
  - jenkins tunnel: k8sServiceName-agent.namespaceOfJenkins:50000 ex. `myjenkins-agent.devops-tools:50000`
  ```diff
  - verify this and change accordingly
  ```
  - rest all parameters as it is and save

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

```diff
- confirm below functionality
```

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
 - Straight forward steps from  https://www.spinnaker.io/setup/security/ssl/#server-terminated-ssl
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
   - Create under same namespace same as other resources created and **name the secret as artifactoryCred**
   - Refer https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
 - Spinnaker > applications > create new application
 - Spinnaker > projects > create new project
   - select the application created above, **if application name is not visible then refresh the page and try**
 - go to created application > pipelines > add stage
   - type: deploy (manifest)
   - stage name
   - account name: drop down would show account name while installing spinnaker, select the one
     - Adding an Account from https://www.spinnaker.io/setup/install/providers/kubernetes-v2/#adding-an-account
   - manifest configuration: copy and paste petclinicNamespace.yaml file from this project
 - Similarly create 2 more stages for petclinicService.yaml, petclinicService.yaml

## Jenkins-Spinnaker: Integration
  - Refer https://www.spinnaker.io/setup/ci/jenkins/#add-your-jenkins-master
    - **If the password does not work then provide token**
  - Then in spinnaker application created above, do configuration according to https://www.spinnaker.io/guides/user/pipeline/triggers/jenkins/
  - For the properties file: provide the name "build_properties.yaml", this is from jenkinsfile
    ```
    post {
      always {
        archiveArtifacts artifacts: 'build_properties.yaml', fingerprint: true
      }
    }
    ```

## Git-Jenkins: Integration
- Azure Git-Jenkins integration **(here azure git mentioned, later mention for github/gitlab configurations)**
  - azure devops project settings > general > service hooks > add >
    - trigger: code pushed
    - repository: select repo name
    - next
    - action: trigger git build
    - jenkins base url, username, user api token - here provide user's token
    - Test and finish

## AWS Custom AMI: Create custom AMI for docker image pull from private registry and EFS mount
- After Jfrog Artifactory and EFS created
- SSH into one of worker nodes
- in `/etc/docker/daemon.json` file add `"insecure-registries":["http://jfrogArtifactoryURL:80"]` as below
```
{
  "bridge": "none",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "10"
  },
  "live-restore": true,
  "max-concurrent-downloads": 10,
  "insecure-registries":["http://jfrogArtifactoryURL:80"]
}
```
- Mount EFS permanently as per https://docs.aws.amazon.com/efs/latest/ug/mount-fs-auto-mount-onreboot.html
- AWS > EC2 > select this worker node > actions > create image
- Change launch template configuration
  - EC2 > Launch templates > select the one which is used in Auto Scaler configurations of EKS > actions > modify template > select AMI new one created above from My AMI section > Create template version
- Select default version
  - EC2 > Launch templates > select the one which is used in Auto Scaler configurations of EKS > actions > set default version > select latest created > set default version
- Change version in Auto scaling group
  - EC2 > Auto scaling group > select the one which is used in Auto Scaler configurations of EKS > actions > edit > change launch template version > select latest > save
- Delete all EC2 instances created as part of EKS worker nodes and now let auto scaler create new nodes as per custom AMI

## CICD covered features and Changes to be done
- Versioning: docker image
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
  - spinnaker > application > pipeline > deployment stage > petclinicDeployment.yaml file>  container section > `${trigger["properties"]["BUILD_NUMBER"]}` provided
- Versioning: artifact
- Maven-settings.xml file
  - For docker retistry, provide first `id` tag as entire url of jfrog artifactory ex. jforgArtifactoryURL:80
  - For java artifacts just keep the `id` tag as `jfrogArtifactory`
