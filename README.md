##### Application Programming Language - Java Spring Boot
##### DevOps Tools Installation Platform - AWS EKS
##### Application Deployment Platform - AWS EKS
##### Administration VM - AWS EC2 Ubuntu for Helm, Kubectl, Halyard, AWS CLI etc.
##### Network file system to share data among kubernetes nodes - AWS EFS
##### CI - Jenkins
##### CD - Spinnaker
##### Package Manager for Kubernetes - Helm
##### Artifact Repository Tool - Nexus, and instruction for Jfrog Artifactory as well

### Administration VM AWS EC2 Ubuntu
 - How to provision using console
   - Straight forward EC2 instance provisioning steps - **just make sure that**
     - provision in the same vpc in which kubernetes is provisioned and
     - enable public ip assignment


# Installation of required packages on Administration VM
- Ansible - https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#latest-releases-via-apt-ubuntu
- Terraform - https://github.com/JaydeepUniverse/automation/blob/master/terraform.yaml
- Helm - https://github.com/JaydeepUniverse/automation/blob/master/helm.yaml
- Spinnaker CLI - https://github.com/JaydeepUniverse/automation/blob/master/spinnakerCLI.yaml


# EKS
- ## Using UI
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
- ## Using Terraform
  - Full script is available at https://github.com/JaydeepUniverse/terraform/tree/master/aws/eks 
  ```diff 
  - make sure about notes written eks github readme
  ```


# EFS
- ## Using UI
  - AWS > select region same as EKS > EFS > Create > VPC of the same as EKS > select **private subnets** > Tags > rest all configurations as it is > create
- ## Using Terraform
  - Full script is available at https://github.com/JaydeepUniverse/terraform/tree/master/aws/efs 
- To mount EFS on administration VM for quick development/testing/r&d purpose, if VM is not AMI then efs can be mounted using NFS command
  - Install nfs client command https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-old.html
  - run mount command https://docs.aws.amazon.com/efs/latest/ug/mounting-fs-mount-cmd-dns-name.html


### Jenkins: Install on EKS using Helm
 - Create jenkinsPersistentVolumeClaim.yaml
 - Create jenkinsStorageClass.yaml
 - Create jenkins namespace
 - Install using helm command
 `helm install ng-jenkins stable/jenkins --set namespaceOverride=jenkins,master.serviceType=LoadBalancer,master.slaveKubernetesNamespace=jenkins,master.resources.requests.cpu=500m,master.resources.requests.memory=1Gi,master.resources.limits.cpu=500m,master.resources.limits.memory=1Gi,persistence.existingClaim=jenkins-pvc,persistence.storageClass=jenkins-sc,master.adminPassword=admin`


### Spinnaker: Install on EKS
 - Straight forward steps from https://www.spinnaker.io/setup/install/
 - Install Halyard
   - provide the username by which want to run halyard/spinnaker service
 - Choose Cloud Provider > Kubernetes(Manifest Based)
   - Optional: Create a Kubernetes Service Account
   - Optional: Configure Kubernetes Roles (RBAC)
   - Adding an account
 - Choose an Environment > Distributed Installation
   - **Make sure to run last optional command as well with 600s value**
 - Choose a Storage Service
   - S3
     - **Make sure to add `--bucket s3BucketName` in the command else random name bucket will created**
 - Deploy and Connect


### Spinnaker: Configure to Expose Publicly
 - Straight forward steps from https://docs.armory.io/spinnaker/exposing_spinnaker/


### Nexus: Installation on EKS
- ## Using Helm
  - I've tried many ways of installing nexus using Helm on kubernetes, but I'm failing, there are multiple reasons for that
    - Through helm it needs dedicated domain or public IP routed on that nexus service to access nexus UI
	  - Nexus uses separate port for docker type registry hence it may need all separate ports on single ip address to expose which I'm not getting how to do that on Helm chart values
	  - Tried with normal service type ClusterIP and exposing but still it same because internally it needs separate dedicated domain or public IP
	  - Hence it won't work with nginx-ingress as well, though nexus UI may work but docker registry won't work
	  - This is supported URL https://freshbrewed.science/getting-started-with-containerized-nexus/index.html where author has mentioned the same in summary - that he couldn't able to succeed usin Helm
	  - Another url how this author has tried but with domain name - https://devopsinitiative.com/blog/2018/03/01/setting-up-nexus3-as-a-private-container-registry-inside-kubernetes/

- ## Using normal kubernetes manifest files
  - Create nexusStorageClass.yaml
  - Create nexusPersistentVolumeClaim.yaml
  - Create nexusDeployment.yaml
  - Create nexusService.yaml

### Nexus: Configuration
- At first time login, password would be stored in - nexus-data/admin.password
- ## To create **docker type** repository
  - Create blob-store for all required repositories - Settings button on top left > Blob stores > create blob store
  - Settings button on top left > repositories > create repository
	- Select Docker(Hosted) for docker type
    - Name
		- Online - keep selected
		- Repository connectors http/https - on this port docker images will be uploaded - provide port number which is exposed in service as well
		- Allow anonymous docker pull - select
		- Enable docker v1 api - select
		- Blob store - select from previous step created
		- Deployment policy: Allow Redeploy for Snapshots type of repo and Disable redeploy for Release type of repo
	  - Cleanup policy - select if created one
  - `settings > security > realms > move "docker bearer token realm" to active`, else while pushing image to repo. it will throw error `Error response from daemon: login attempt to http://10.236.2.5:8085/v2/ failed with status: 401 Unauthorized`



### Jenkins: Configurations
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

### Jfrog Artifactory: Install on EKS
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

## Jfrog OSS
 - Jfrog OSS can be configured using command ```helm install --name artifactory --set artifactory.image.repository=docker.bintray.io/jfrog/artifactory-oss stable/artifactory``` however **docker registry feature is not supportable in open source image** below are supported link
 - https://stackoverflow.com/questions/58049331/does-jfrog-artifactory-oss-provides-private-docker-registry
 - https://www.jfrog.com/confluence/display/JFROG/Getting+Started+with+Artifactory+as+a+Docker+Registry


### Spinnaker: Configure on HTTPS
- First expplore this https://docs.armory.io/spinnaker/exposing_spinnaker/#secure-with-ssl-on-eks and then go through next option
- Straight forward steps from  https://www.spinnaker.io/setup/security/ssl/#server-terminated-ssl
- **Make sure to increase --liveness-probe-initial-delay-seconds to 600s in the command**
  - `hal config deploy edit --liveness-probe-enabled true --liveness-probe-initial-delay-seconds 600`

### Jenkins: Create Multibranch CI pipeline
 - Create credentials to authenticate to git repository
   - Jenkins > Credentials > System > Global credentials > Add credentials
     - Scope: Global
     - Username: Username of the git repository
     - Password: Password of git repository
     - ID: ID(name) to be used to select in job configuration
     - Description: description
 - Jenkins > new job > multibranch type > git > url, credentials > save
 - This job will automatically fetch all branch names from git and create separate jobs for each branch wise

### Spinnaker: Create CD pipeline
## (1) First Implementation - Manual
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

## (2) Second Implementation - Automation - 
# (1) Creating pipeline from jenkins CI
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
# (2) Creating Spinnaker pipeline before Build step so that pipeline creates properly by the time build finishes and then can execute and also dynamically changing branch name in template.json file
- Moved pipeline creation steps before build in jenkinsfile
- For changing branch name in template.json file used below commands in jenkinsfile
```
sh "sed -i 's/branchName/'${env.BRANCH_NAME}'/g' template.json"
sh "spin pipeline save --file template.json"
```                

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
# Versioning Part 1
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
  - For docker retistry, provide first `id` tag as entire url of jfrog artifactory ex. jforgArtifactoryURL:80
  - For java artifacts just keep the `id` tag as `jfrogArtifactory`

# Versioning Part 2 - This is implemented - Good approach
- It is done using jgitver plugin
- Create .mvn directory in project root directory > inside .mvn create extension.xml and jgitver.config.xml files. Content of the files are inside this project.
- Here is how does it work > Let's say we have initial version in maven pom is 1.0.0 and started development with tag 1.0.0, then our versions would be 1.0.1-1, 1.0.1-2, 1.0.1-3... Next let's say after feature completion we have tagged it 1.0.2 then version will be 1.0.2 and after that automatically 1.0.3-1, 1.0.3-2, so on.
- Also I've appended branch name in the version so now our version would be 1.0.1-1-branchName, 1.0.1-2-branchName. ** This would not work for Master branch. **
- Read below urls for more details
   - https://jgitver.github.io/
   - https://github.com/jgitver/jgitver-maven-plugin

# Versioning Part 2 - This is implemented and improvised for using jenkins build number as patch auto increment in version - Good approach
- Changed jgitver strategy and versionPattern changed
```
<configuration xmlns="http://jgitver.github.io/maven/configuration/1.0.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://jgitver.github.io/maven/configuration/1.0.0 https://jgitver.github.io/maven/configuration/jgitver-configuration-v1_0_0.xsd">
<strategy>PATTERN</strategy>
<versionPattern>${M}.${m}.${p}-${env.BUILD_NUMBER}</versionPattern>
</configuration>
```
- changed in mvn build command - added -DBUILD_NUMBER=${BUILD_NUMBER}
```sh "mvn deploy docker:push -s maven-settings.xml -Dmaven.test.skip=true -DBUILD_NUMBER=${BUILD_NUMBER} -Dmaven.test.skip=true -Dstyle.color=always -B"``` 