pipeline {
        agent {
                kubernetes {
                        label "maven-pod"
                        defaultContainer "maven-build"
                        yamlFile "jenkinsSlaveAgentMavenPod.yaml"
                }
    }
        environment{
        JAVA_TOOL_OPTIONS = '-Duser.home=/var/maven'
    }
        stages {
                stage("Java & Maven Version"){
            steps{
                    sh "mvn -v"
                    sh "java --version"
					sh "sed -i s/spring-petclinic-*.*-SNAPSHOT.jar/spring-petclinic-${BUILD_NUMBER}-SNAPSHOT.jar/g ${WORKSPACE}/Dockerfile"
            }
        }
                stage("Build"){
            steps{
                    sh "mvn deploy docker:push -s maven-settings.xml -DBUILD_NUMBER=${BUILD_NUMBER} -Dmaven.test.skip=true"
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
                stage("Create spinnaker properties file"){
            steps{
                    sh """
echo "---
BUILD_NUMBER: '${BUILD_NUMBER}'
" > build_properties.yaml
"""
            }
        }
        }
        post {
                always {
            archiveArtifacts artifacts: 'build_properties.yaml', fingerprint: true
                }
        }
}
