pipeline {
    agent any

    environment {
        VERSION = "1.0.${BUILD_NUMBER}"
        PATH = "${PATH}:${getSonarPath()}"
        AWS_DEFAULT_REGION = 'us-east-1'
        TARGET_ACCOUNT_ROLE_ARN =  'arn:aws:iam::891377046654:role/Engineer'
        ASSUME_ROLE_SESSION_NAME = 'JenkinsSession'
    }

    stages {
        // stage ('Sonarqube Scan') {
        //     steps {
        //         script {
        //             scannerHome = tool 'sonarqube'
        //         }
        //         withCredentials([string(credentialsId: 'SONAR_TOKEN', variable: 'SONAR_TOKEN')]){
        //             withSonarQubeEnv('SonarQubeScanner') {
        //                 sh """
        //                     ${scannerHome}/bin/sonar-scanner \
        //                     -Dsonar.projectKey=Activiti-app-YinkaR \
        //                     -Dsonar.login=${SONAR_TOKEN}
        //                 """
        //             }
        //         }
        //     }
        // }

        // stage ('Quality Gate') {
        //     steps {
        //         timeout(time: 3, unit: 'MINUTES') {
        //             waitForQualityGate abortPipeline: true
        //         }
        //     }
        // }

        stage ('Build Activiti Docker Image') {
            steps {
                sh "docker build . -t activiti-image:$VERSION"
            }
        }

        stage ('Starting Activiti Docker Image') {
            steps {
                sh '''
                if ( docker ps|grep activiti-cont ) then
                    echo "Docker image exists, killing it"
                    docker stop activiti-cont
                    docker rm activiti-cont
                    docker run --name activiti-cont -p 8081:8080 -d activiti-image:$VERSION
                else
                    docker run --name activiti-cont -p 8081:8080 -d activiti-image:$VERSION 
                fi
                '''
            }
        }

        stage ('Restore Activiti EC2 Database') {
            steps {
                withCredentials([string(credentialsId: 'secret_key', variable: 'SECRET_KEY_VAR'), string(credentialsId: 'access_key', variable: 'ACCESS_KEY_VAR')]){
                    sh '''
                        pip3 install boto3 botocore boto
                        ansible-playbook -i localhost $WORKSPACE/deploy_db_ansible/deploy_ec2_db.yml --extra-vars "access_key=${ACCESS_KEY_VAR} secret_key=${SECRET_KEY_VAR}"
                    '''
                }
            }
        }

        stage ('Configure DB Instance') {
            steps {
                sh '''
                    SERVER_IP=$(curl -s http://checkip.dyndns.org | sed -e 's/.*Current IP Address: //' -e 's/<.*$//')
                    SERVER_INSTANCE='44.211.15.91'
                    docker exec -d activiti-cont sed -i "s/'10.0.20.40'/'${SERVER_INSTANCE}'/g" /usr/local/tomcat/webapps/activiti-app/WEB-INF/classes/META-INF/activiti-app/activiti-app.properties
                '''
            }
        }

        stage ('Tear Down Activiti Docker Image and Database') {
            steps {
                script {
                    def userInput = input(id: 'confirm', message: 'Tear Down Environment?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Tear Down Environment?', name: 'confirm'] ])
                }
                sh '''
                    python3 -m venv python3-virtualenv
                    source python3-virtualenv/bin/activate
                    python3 --version
                    pip3 install boto3 botocore boto
                    ansible-playbook $WORKSPACE/deploy_db_ansible/delete_ec2_db.yml
                    deactivate
                    docker stop activiti-cont
                    docker rm activiti-cont
                '''
            }
        }

        stage ('Log Into ECR and push the newly created Docker') {
            steps {
                script {
                    def userInput = input(id: 'confirm', message: 'Push Image To ECR?', parameters: [ [$class: 'BooleanParameterDefinition', defaultValue: false, description: 'Push to ECR?', name: 'confirm'] ])
                }
                sh '''
                    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 975050060097.dkr.ecr.us-east-1.amazonaws.com/clixx-repository
                    docker tag activiti-image:$VERSION 975050060097.dkr.ecr.us-east-1.amazonaws.com/activiti-repository:activiti-image-$VERSION
                    docker tag activiti-image:$VERSION 975050060097.dkr.ecr.us-east-1.amazonaws.com/activiti-repository:latest
                    docker push 975050060097.dkr.ecr.us-east-1.amazonaws.com/activiti-repository:activiti-image-$VERSION
                    docker push 975050060097.dkr.ecr.us-east-1.amazonaws.com/activiti-repository:latest
                '''
            }
        }
    }
}

def getSonarPath() {
    def SonarHome = tool name: 'sonarqube', type: 'hudson.plugins.sonar.SonarRunnerInstallation'
    return SonarHome
}