pipeline {
    agent {
        kubernetes {
            label "petclinic-CICD"
            defaultContainer "jenkins-slave"
            yamlFile "petclinic-CICD.yaml"
        }
    }
    parameters {
        string(name: 'version', defaultValue: '')
    }
    options {
        ansiColor('xterm')
    }
    environment{
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
        MAVEN_OPTS = '-Djansi.force=true'
        def version = "${params.version}"
    }
    stages {
        stage("Get application version & create spinnaker pipeline"){
            steps{
                script{
                    version = sh(script: "mvn help:evaluate -Dexpression=project.version -q -DforceStdout", returnStdout: true).trim()
                }
                sh "sed -i 's/branchName/'${env.BRANCH_NAME}'/g' template.json"
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
        stage("Build"){
            steps{
                    sh "mvn deploy docker:push -s maven-settings.xml -Dmaven.test.skip=true -DBUILD_NUMBER=${BUILD_NUMBER} -DBRANCH_NAME=${env.BRANCH_NAME} -Dmaven.test.skip=true -Dstyle.color=always -B"
                }
            }
       stage("Test"){
            steps{
                  sh "mvn test"
          }
          post{
              always{
                      junit "**/target/surefire-reports/TEST-*.xml"
              }
           }
        }
    }
    post {
        always {
            archiveArtifacts artifacts: 'build_properties.yaml', fingerprint: true
        }
    }
}
