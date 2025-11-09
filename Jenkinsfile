pipeline {
    agent any

    environment {
        IMAGE_NAME = "jenkins-pipeline-demo"
        DOCKERHUB_USER = "maniattili"
        DEPLOY_HOST = "13.221.130.121"
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

        stage('Blue-Green Deploy to EC2') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'ec2-ssh-password', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
                    sh '''
                        echo "Starting Blue-Green Deployment..."

                        sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $SSH_USER@$DEPLOY_HOST <<'EOF'
                            set -e

                            DOCKER_USER="maniattili"
                            IMAGE="jenkins-pipeline-demo"
                            TAG="v1.0.${BUILD_NUMBER}"

                            echo "Pulling new image..."
                            docker pull ${DOCKER_USER}/${IMAGE}:${TAG}

                            # Detect active environment
                            if docker ps --format "{{.Names}}" | grep -q "${IMAGE}-blue"; then
                                ACTIVE_COLOR=blue
                                IDLE_COLOR=green
                                IDLE_PORT=5001
                            else
                                ACTIVE_COLOR=green
                                IDLE_COLOR=blue
                                IDLE_PORT=5000
                            fi

                            echo "Active environment: $ACTIVE_COLOR"
                            echo "Deploying new version to $IDLE_COLOR on port $IDLE_PORT"

                            docker stop ${IMAGE}-$IDLE_COLOR || true
                            docker rm ${IMAGE}-$IDLE_COLOR || true

                            docker run -d -p $IDLE_PORT:5000 --name ${IMAGE}-$IDLE_COLOR ${DOCKER_USER}/${IMAGE}:${TAG}

                            echo "Health checking new container on port $IDLE_PORT..."
                            sleep 10

                            if curl -s http://localhost:$IDLE_PORT | grep -q "Hello Jenkins"; then
                                echo "✅ New version healthy — switching traffic"
                                docker stop ${IMAGE}-$ACTIVE_COLOR || true
                                docker rm ${IMAGE}-$ACTIVE_COLOR || true
                                echo "Now serving: $IDLE_COLOR"
                            else
                                echo "❌ New version unhealthy — keeping $ACTIVE_COLOR live"
                                docker stop ${IMAGE}-$IDLE_COLOR || true
                                docker rm ${IMAGE}-$IDLE_COLOR || true
                            fi
EOF
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

