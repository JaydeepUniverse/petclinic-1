# Tools used in this project
##### Application Programming Language - Java Spring Boot
##### DevOps Tools Installation Platform - AWS EKS
##### Application Deployment Platform - AWS EKS
##### Administration VM - AWS EC2 Ubuntu for Helm, Kubectl, Halyard, AWS CLI etc.
##### Network file system to share data among Kubernetes nodes - AWS EFS
##### Store Jenkins, Nexus data - AWS EBS
##### Store Spinnaker data - AWS S3
##### CI - Jenkins
##### CD - Spinnaker
##### Package Manager for Kubernetes - Helm
##### Artifact Repository Tool - Nexus and instruction for Jfrog Artifactory


# :apple: Administration VM AWS EC2 Ubuntu
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) How to provision using console
  - Straight forward EC2 instance provisioning steps from console

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Installation of required packages on Administration VM
  - Ansible - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-ubuntu
  - Terraform - https://github.com/JaydeepUniverse/automation/blob/master/terraform.yaml
  - Helm - https://github.com/JaydeepUniverse/automation/blob/master/Helm.yaml
  - Spinnaker CLI - https://github.com/JaydeepUniverse/automation/blob/master/spinnakerCLI.yaml


# :tangerine: EKS
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Using Terraform
  - Initially keep `use_custom_image_id` in `eks-cluster-workers/variables.tf` false
  - For this setup we're going to create 2 EKS clusters, one for CICD Tools and another for application
  - For EKS Application cluster - while creating it :small_blue_diamond: ***change CIDR blocks*** :small_blue_diamond:in  `/aws/eks/environment/dev/main.tf` because we'll need to communicate Administrative VM which is in CICD EKS VPC To VMs in EKS Application cluster. For which we'll create VPC peering between EKS CICD VPC and EKS App VPC. And as per VPC peering rule if CIDR blocks of 2 VPCs are same then peering is not allowed between those 2 VPCs.
  - Full script is available at https://github.com/JaydeepUniverse/terraform/tree/master/aws/eks :small_blue_diamond: ***make sure about notes written eks github readme*** :small_blue_diamond: 
  

# :lemon: EFS
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Using Terraform
  - Full script is available at https://github.com/JaydeepUniverse/terraform/tree/master/aws/efs 

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Mount on Admnistration VM and Worker nodes
  - To mount EFS on administration VM for quick development/testing/r&d purpose, if VM is not amazon linux ex. ubuntu then efs can be mounted using NFS command as per below process
    - Install nfs client command https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-old.html & run mount command https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html
      - `mkdir /home/ec2-user/m2`
      - Add this entry in `sudo vim /etc/fstab` - `fs-ID.efs.Region.amazonaws.com:/ /home/ec2-user/m2 nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 0 0` 
      - `sudo mount -fav`
    - If there is mounting issue in these 2 steps then
      - Add VM's security group to efs manage network access > sec groups, in both/whichever available subnets
      - if required add inbound NFS 2049 rule in security group of VM


# :cherries: Nexus: Installation on EKS CICD Cluster & Configuration
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Using Helm
  - I've tried many ways of installing Nexus using Helm on Kubernetes, but I'm failing, there are multiple reasons for that
    - Through Helm it needs dedicated domain or public IP routed on that Nexus service to access Nexus UI
	  - Nexus uses separate port for docker type registry hence it may need all separate ports on single ip address to expose which I'm not getting how to do that in Helm chart values
	  - Tried with normal service type ClusterIP and exposing but still it same because internally it needs separate dedicated domain or public IP
	  - Hence it won't work with nginx-ingress as well, though nexus UI may work but docker registry won't work
	  - This is supported URL https://freshbrewed.science/getting-started-with-containerized-nexus/index.html where author has mentioned the same in summary - that he couldn't able to succeed using Helm
	  - Another url how this author has tried but with domain name - https://devopsinitiative.com/blog/2018/03/01/setting-up-nexus3-as-a-private-container-registry-inside-Kubernetes/

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Using normal Kubernetes manifest files
  - Create nexusStorageClass.yaml
  - Create nexusPersistentVolumeClaim.yaml
  - Create nexusDeployment.yaml
  - Create nexusService.yaml

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Nexus: Configuration
- At first time login, password would be stored in - `nexus-data/admin.password`
  - ## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Create Docker Registry
  - Create blob-store for all required repositories - Settings button on top left > Blob stores > create blob store
  - Settings button on top left > repositories > create repository
	- Select Docker(Hosted) for docker type
    - Name
		- Online - keep selected
		- Repository connectors http - on this port docker images will be pushed/pulled - provide port number which is exposed in service as well
		- Allow anonymous docker pull - select
		- Enable docker v1 api - select
		- Blob store - select from previous step created
		- Deployment policy: Allow Redeploy for Snapshots type of repo and Disable redeploy for Release type of repo
	  - Cleanup policy - select if created one
  - :small_blue_diamond: ***`settings > security > realms > move "docker bearer token realm" to active`*** :small_blue_diamond: else while pushing image to repo. it will throw error 
  ```diff
  - Error response from daemon: login attempt to http://10.236.2.5:8085/v2/ failed with status: 401 Unauthorized
  ```

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Test docker registry
  - In Administraiton VM, tag the image name as :small_blue_diamond: ***nexusURL:dockerPort/dockerRegName/imageName:tag*** :small_blue_diamond:
  - In `/etc/docker/daemon.json` file add `"insecure-registries":["http://nexusURL:dockerPort"]`
  - Restart docker service
  - `sudo docker login nexusURL:dockerPort`
  - `sudo docker push nexusURL:dockerPort/dockerReg/imageName:tag`


# :apple: Administration VM AWS EC2 Ubuntu & Worker Nodes
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Administration VM
  - Once EKS cluster is created, EFS is mounted & Nexus docker registry checked then move or create new VM in same VPC in which Kubernetes CICD cluster is provisioned
    - To create new VM take image backup of existing EC2 > launch new EC2 in the same VPC and subnet as of CICD EKS cluster > enable public ip assignment > give name to security_group > terminate previous EC2

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Worker node  custom AMI for docker image pull from private registry and EFS mount
- After Nexus or Jfrog Artifactory - docker registry and EFS created
- Find out Security Group of worker nodes and add SSH inbound rule for all IPs or SG of Administation VM
- Create VPC peering between EKS CICD and EKS Application cluster
  - Add routes in EKS CICD and EKS Application cluster Route Table
  - Check other routing configurations if require if SSH is not working between Administration VM and worker nodes
- SSH into one of worker nodes, for this below configurations needed in Administration VM
  - To SSH EKS worker nodes, we need EKS key pair .pem file. 
    - For this, first we'd have created .ppk file while proviosioning EKS using Terraform
    - From this PPK, convert to .pem format - here's the link of how to - https://aws.amazon.com/premiumsupport/knowledge-center/convert-pem-file-into-ppk/
    - Put this key in this VM
    - Change permission to 400
    - SSH using command `ssh -i key.pem ec2-user@pvtIp`
- After SSH, in worker nodes, In `/etc/docker/daemon.json` file, add `"insecure-registries":["http://jfrogArtifactoryURL:80"]` for JFrog Artifactory and `"insecure-registries":["http://nexusURL:dockerPort"]` for Nexus


# :grapes: Jenkins: Install on EKS using Helm
 - Create jenkins namespace
 - Create jenkinsStorageClass.yaml
 - Create jenkinsPersistentVolumeClaim.yaml
 - Install using Helm command
 ```
 Helm install jenkins stable/jenkins -n jenkins --set namespaceOverride=jenkins,master.serviceType=LoadBalancer,master.slaveKubernetesNamespace=jenkins,master.resources.requests.cpu=500m,master.resources.requests.memory=1Gi,master.resources.limits.cpu=500m,master.resources.limits.memory=1Gi,persistence.existingClaim=jenkins,persistence.storageClass=jenkins,master.adminPassword=admin
 ```


# :grapes: Jenkins: Configurations
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+)) Kubernetes configurations
- Manage jenkins > Manage Nodes & Cloud > Configure Cloud > Kubernetes >
  - Name: Kubernetes
  - Kubernetes URL: `https://kubernetes.default` keep this default as if Jenkins is installed in same EKS cluster
  - Kubernetes Namespace: jenkins
  - Credentials: Add > Jenkins:
    - Domain: Global
    - Kind: Kubernetes service account
    - Scope: Global
    - Add
    - Test Connection
  - Jenkins URL: http://k8sServiceName.namespaceOfJenkins:8080 ex. `http://myjenkins.devops-tools:8080`
  - Jenkins tunnel: k8sServiceName-agent.namespaceOfJenkins:50000 ex. `myjenkins-agent.devops-tools:50000`
  - Credentials: Add new > global > kind: Kubernetes service account > add > Test connection 
  - rest all parameters as it is and save
- Plugins
  - ansicolor

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Create Multibranch CI pipeline
- Take username and token of repository from Azure DevOps
  - Azure DevOps > Repository > clone > Generate Git Credentials > keep copied this username and token, will be required in next step
- Create credentials to authenticate to git repository
  - Jenkins > Credentials > System > Global credentials > Add credentials
    - Scope: Global
    - Username: Username of the git repository
    - Password: Token of the repository
    - ID: ID(name) to be used to select in job configuration
    - Description: description
 - Jenkins > new job > multibranch type > git > url, credentials > save
 - This job will automatically fetch all branch names from git and create separate jobs for each branch wise

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Git-Jenkins: Integration **(here azure git mentioned, later mention for github/gitlab configurations)**
- Create Jenkins userid token
  - click on admin user id > configure > API Token > create one > keep copied for next step
- Azure Git-Jenkins integration 
  - Azure Devops project settings > general > service hooks > add >
    - trigger: code pushed
    - repository: select repo name
    - next
    - action: trigger git build
    - jenkins base url, username, user api token - here provide user's token
    - Test and finish


# :watermelon: Spinnaker 
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Install on EKS
  - Straight forward steps from https://www.spinnaker.io/setup/install/
  - Install Halyard
    - provide the username by which want to run halyard service
  - Choose Cloud Provider > Kubernetes(Manifest Based) :small_blue_diamond: ***Run these step(all commands) 2 times for each cluster by changing kubectl context*** :small_blue_diamond:
    - Optional: Create a Kubernetes Service Account
    - Optional: Configure Kubernetes Roles (RBAC)
    - Adding an account
  - Choose an Environment > Distributed Installation
    - **Make sure to run last optional command as well with 600s value**
  - Choose a Storage Service
    - Create S3 bucket and add `--bucker S3BucketName` else next command will create automatically
    - Script to create S3 bucket is available at https://github.com/JaydeepUniverse/terraform/tree/master/aws/s3 
  - Deploy and Connect

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Spinnaker-Jenkins: Integration
  - Refer https://www.spinnaker.io/setup/ci/jenkins/#add-your-jenkins-master
    - **Provide admin user token created in previous step**
  - For the properties file: provide the name "build_properties.yaml", this is from jenkinsfile
    ```
    post {
      always {
        archiveArtifacts artifacts: 'build_properties.yaml', fingerprint: true
      }
    }
    ```
  
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Spinnaker configuration
- Create application
- Create project, refresh the page and associate application created above to the project
- Pipeline creation will be taken care by `template.json` file while running jenkins build
  - Change Jenkins name created in above account
  - Change EKS Application Account created while spinnaker installation process
- Create secret file manually first to pull docker image from nexus and then change values in template.json

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Configure to Expose Publicly
  - Straight forward steps from https://docs.armory.io/spinnaker/exposing_spinnaker/

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Create CD pipeline
## ![#A04000](https://placehold.it/15/A04000/000000?text=+) (1) First Implementation - Manual
 - Before creating spinnaker pipeline, first create Kubernetes secret to pull the image from private docker registry
   - Create under same namespace same as other resources created and **name the secret as artifactoryCred**
   - Refer https://Kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/
 - Spinnaker > applications > create new application
 - Spinnaker > projects > create new project
   - select the application created above, **if application name is not visible then refresh the page and try**
 - go to created application > pipelines > add stage
   - type: deploy (manifest)
   - stage name
   - account name: drop down would show account name while installing spinnaker, select the one
     - Adding an Account from https://www.spinnaker.io/setup/install/providers/Kubernetes-v2/#adding-an-account
   - manifest configuration: copy and paste petclinicNamespace.yaml file from this project
 - Similarly create 2 more stages for petclinicService.yaml, petclinicService.yaml

## ![#A04000](https://placehold.it/15/A04000/000000?text=+) (2) Second Implementation - Automation - 
## ![#28B463](https://placehold.it/15/28B463/000000?text=+) (1) Creating pipeline from jenkins CI
- Clone the project and Create Template.json spinnaker pipeline file in the project root directory
  - ```spin pipeline get --name cdspinnaker --application petclinic > template.json```
- We will use 2 dynamic parameters: Version(calculated by jgiver) and Branch name (jenkins default env variable)
- Then pipeline creation command ```spin pipeline save --file template.json```
- All configurations and code is as below in the pipeline
```
    parameters {
        string(name: 'version', defaultValue: '')
    }
    environment{

        def version = "${params.version}"
    }

    stage("Get application version & create spinnaker pipeline"){
            steps{
                script{
                    version = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                }
                sh "spin pipeline save --file template.json"
            }
        }
    stage("Create spinnaker properties file"){
            steps{
                sh """
echo "---
branch_name: "${env.BRANCH_NAME}"
version: "${version}"
" > build_properties.yaml
"""
            }
        }
  ```
## ![#28B463](https://placehold.it/15/28B463/000000?text=+) (2) Creating Spinnaker pipeline before Build step so that pipeline creates properly by the time build finishes and then can execute and also dynamically changing branch name in template.json file
- Moved pipeline creation steps before build in jenkinsfile
- For changing branch name in template.json file used below commands in jenkinsfile
```
sh "sed -i 's/branchName/'${env.BRANCH_NAME}'/g' template.json"
sh "spin pipeline save --file template.json"
```                

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Configure on HTTPS
- First expplore this https://docs.armory.io/spinnaker/exposing_spinnaker/#secure-with-ssl-on-eks and then go through next option
- Straight forward steps from  https://www.spinnaker.io/setup/security/ssl/#server-terminated-ssl
- **Make sure to increase --liveness-probe-initial-delay-seconds to 600s in the command**
  - `hal config deploy edit --liveness-probe-enabled true --liveness-probe-initial-delay-seconds 600`


# :strawberry: Jfrog Artifactory: Install on EKS
 - Create S3 bucket for storage purpose ***<< Confirm this functionality***
 - First add jfrog required repository
   - `Helm repo add jfrog https://charts.jfrog.io`
 - Get artifactory Helm chart values
   - `Helm inspect values jfrog/artifactory > /tmp/artifactory.values`
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
   - `Helm install myartifactory  jfrog/artifactory --values /tmp/artifactory.values`

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Jfrog OSS
 - Jfrog OSS can be configured using command ```Helm install --name artifactory --set artifactory.image.repository=docker.bintray.io/jfrog/artifactory-oss stable/artifactory``` however :small_blue_diamond: ***docker registry feature is not supportable in open source image*** :small_blue_diamond: below are supported link
 - https://stackoverflow.com/questions/58049331/does-jfrog-artifactory-oss-provides-private-docker-registry
 - https://www.jfrog.com/confluence/display/JFROG/Getting+Started+with+Artifactory+as+a+Docker+Registry


# :peach: Versioning
## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Versioning Part 1
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
  - In pom.xml changed artifact's version tag as `<version>${env.BUILD_NUMBER}-SNAPSHOT</version>`
  - In Jenkinsfile added step to change the same version in Dockerfile to build newer artifact version 
    `sh "sed -i s/spring-petclinic-*.*-SNAPSHOT.jar/spring-petclinic-${BUILD_NUMBER}-SNAPSHOT.jar/g ${WORKSPACE}/Dockerfile"`

- Maven-settings.xml file
  - For docker retistry, provide first `id` tag as entire url of nexus or jfrog artifactory ex. or nexusURL:8082 or jforgArtifactoryURL:80
  - For java artifacts just keep the `id` tag as `petclinic-snapshot` or `petclinic-releases` or `jfrogArtifactory`

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Versioning Part 2 - This is implemented - Good approach
- It is done using jgitver plugin
- Create .mvn directory in project root directory > inside .mvn create extension.xml and jgitver.config.xml files. Content of the files are inside this project.
- Here is how does it work > Let's say we have initial version in maven pom is 1.0.0 and started development with tag 1.0.0, then our versions would be 1.0.1-1, 1.0.1-2, 1.0.1-3... Next let's say after feature completion we have tagged it 1.0.2 then version will be 1.0.2 and after that automatically 1.0.3-1, 1.0.3-2, so on.
- Also I've appended branch name in the version so now our version would be 1.0.1-1-branchName, 1.0.1-2-branchName. ** This would not work for Master branch. **
- Read below urls for more details
   - https://jgitver.github.io/
   - https://github.com/jgitver/jgitver-maven-plugin

## ![#1589F0](https://placehold.it/15/1589F0/000000?text=+) Versioning Part 2 - This is implemented and improvised for using jenkins build number as patch auto increment in version - Good approach
- Changed jgitver strategy and versionPattern changed. Here I've added branchName and build number both, so that each patched version would be identified by jenkins's build number and if 2 branch have same tag then to avoid conflict added branch name.
```
<configuration xmlns="http://jgitver.github.io/maven/configuration/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://jgitver.github.io/maven/configuration/1.0.0 https://jgitver.github.io/maven/configuration/jgitver-configuration-v1_0_0.xsd">
<strategy>PATTERN</strategy>
<versionPattern>${M}.${m}.${p}-${env.BRANCH_NAME}-${env.BUILD_NUMBER}</versionPattern>
</configuration>
```
- changed in mvn build command - added -DBUILD_NUMBER=${BUILD_NUMBER}
```sh "mvn deploy docker:push -s maven-settings.xml -Dmaven.test.skip=true -DBUILD_NUMBER=${BUILD_NUMBER} -DBRANCH_NAME=${env.BRANCH_NAME} -Dmaven.test.skip=true -Dstyle.color=always -B"``` 