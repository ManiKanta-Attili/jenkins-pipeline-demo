pipeline {
    agent any
    environment {
        IMAGE_NAME = "jenkins-pipeline-demo"
        DOCKERHUB_USER = "maniattili"
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

        stage('Docker Build') {
            steps {
                echo "Building Docker image..."
                sh '''
                    docker build -t $IMAGE_NAME:latest .
                    docker images | grep $IMAGE_NAME
                '''
            }
        }

        stage('Docker Run (Test)') {
            steps {
                echo "Running Docker container..."
                sh '''
                    docker run --rm $IMAGE_NAME:latest
                '''
            }
        }

        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-login', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                sh '''
                    echo "Pushing image to DockerHub..."
                    docker login -u $USER -p $PASS
                    docker tag $IMAGE_NAME:latest $USER/$IMAGE_NAME:latest
                    docker push $USER/$IMAGE_NAME:latest
                '''
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

