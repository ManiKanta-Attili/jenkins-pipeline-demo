pipeline {
    agent any

    environment {
        IMAGE_NAME = "jenkins-pipeline-demo"
        DOCKERHUB_USER = "maniattili"
        DEPLOY_HOST = "zrybs@13.221.130.121"
    }

    stages {
        stage('Build') {
            steps {
                echo "Building Python app..."
                sh 'python3 -m py_compile app.py'
            }
        }

        stage('Test') {
            steps {
                echo "Running tests..."
                sh '''
                    pytest test_app.py | tee result.log || true
                '''
                archiveArtifacts artifacts: 'result.log', allowEmptyArchive: true
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def versionTag = "v1.0.${env.BUILD_NUMBER}"
                    env.IMAGE_TAG = versionTag
                    echo "Building Docker image with tag: ${versionTag}"
                }
                withCredentials([usernamePassword(credentialsId: 'dockerhub-login', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo "Building and pushing Docker image..."
                        docker login -u $USER -p $PASS
                        docker build -t $USER/$IMAGE_NAME:$IMAGE_TAG -t $USER/$IMAGE_NAME:latest .
                        docker push $USER/$IMAGE_NAME:$IMAGE_TAG
                        docker push $USER/$IMAGE_NAME:latest
                    '''
                }
            }
        }
        

        stage('Deploy to EC2') {
           steps {
               withCredentials([usernamePassword(credentialsId: 'ec2-ssh-password', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                   sh '''
                       echo "Deploying version $IMAGE_TAG on EC2..."
                       sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $DEPLOY_HOST "
                           docker pull $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG &&
                           docker stop $IMAGE_NAME || true &&
                           docker rm $IMAGE_NAME || true &&
                           docker run -d -p 80:5000 --name $IMAGE_NAME $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG
                           sleep 10
                           if ! curl -s http://localhost:5000 | grep -q 'Hello Jenkins'; then
                              echo 'New version failed — rolling back...'
                              docker stop $IMAGE_NAME || true
                              docker rm $IMAGE_NAME || true
                              docker run -d -p 80:5000 --name $IMAGE_NAME $DOCKERHUB_USER/$IMAGE_NAME:latest
                           else
                               echo 'Deployment successful!'
                           fi
                       "
                      '''
               }
           }
        }
}
    
 

    post {
        always {
            echo "Cleaning workspace..."
            cleanWs()
        }
    }
}
