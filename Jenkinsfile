pipeline {
    agent any

    environment {
        IMAGE_NAME = "jenkins-pipeline-demo"
        DOCKERHUB_USER = "maniattili"
        DEPLOY_HOST = "ubuntu@98.80.72.236"
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
                withCredentials([usernamePassword(credentialsId: 'dockerhub-login', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo "Building and pushing Docker image..."
                        docker login -u $USER -p $PASS
                        docker build -t $USER/$IMAGE_NAME:latest .
                        docker push $USER/$IMAGE_NAME:latest
                    '''
                }
            }
        }
        
        stage('Deploy to EC2') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ec2-ssh-password', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                    sh '''
                        echo "Deploying container on EC2 via password-based SSH..."
                        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@<EC2-PUBLIC-IP> "
                            sudo docker login -u $DOCKERHUB_USER -p $PASS &&
                            sudo docker pull $DOCKERHUB_USER/$IMAGE_NAME:latest &&
                            sudo docker stop $IMAGE_NAME || true &&
                            sudo docker rm $IMAGE_NAME || true &&
                            sudo docker run -d --name $IMAGE_NAME $DOCKERHUB_USER/$IMAGE_NAME:latest
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
