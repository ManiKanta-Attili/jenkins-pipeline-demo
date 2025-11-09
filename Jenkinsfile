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
        
	stage('Blue-Green Deploy to EC2') {
	    steps {
		withCredentials([usernamePassword(credentialsId: 'ec2-ssh-password', usernameVariable: 'SSH_USER', passwordVariable: 'SSH_PASS')]) {
		    sh '''
			echo "Starting Blue-Green Deployment..."
			sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no $DEPLOY_HOST "
			    echo 'Pulling new image...'
			    docker pull $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG

			    # Identify active container (blue or green)
			    ACTIVE_CONTAINER=\$(docker ps --filter name=${IMAGE_NAME}-blue --format '{{.Names}}')
			    if [ -z \"\$ACTIVE_CONTAINER\" ]; then
				ACTIVE_COLOR=green
				IDLE_COLOR=blue
			    else
				ACTIVE_COLOR=blue
				IDLE_COLOR=green
			    fi

			    echo 'Active environment: '\$ACTIVE_COLOR
			    echo 'Deploying new version to '\$IDLE_COLOR

			    # Stop and remove old idle container if exists
			    docker stop ${IMAGE_NAME}-\$IDLE_COLOR || true
			    docker rm ${IMAGE_NAME}-\$IDLE_COLOR || true

			    # Start new idle container on alternate port
			    IDLE_PORT=\$( [ \$IDLE_COLOR = 'blue' ] && echo 5000 || echo 5001 )
			    docker run -d -p \$IDLE_PORT:5000 --name ${IMAGE_NAME}-\$IDLE_COLOR $DOCKERHUB_USER/$IMAGE_NAME:$IMAGE_TAG

			    echo 'Health checking new container on port '\$IDLE_PORT
			    sleep 10

			    if curl -s http://localhost:\$IDLE_PORT | grep -q 'Hello Jenkins'; then
				echo '✅ New version healthy — promoting to production'
				docker stop ${IMAGE_NAME}-\$ACTIVE_COLOR || true
				docker rm ${IMAGE_NAME}-\$ACTIVE_COLOR || true
			    else
				echo '❌ New version unhealthy — keeping current live version'
				docker stop ${IMAGE_NAME}-\$IDLE_COLOR || true
				docker rm ${IMAGE_NAME}-\$IDLE_COLOR || true
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
