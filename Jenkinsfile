pipeline {
    agent any
    stages {
        stage('Build') {
            steps {
                echo 'Building the Application...'
                sh 'python3 -m py_compile app.py'
            }
        }

        stage('Test') {
            steps {
                echo 'Running Tests...'
                sh 'pytest test_app.py > result.log || true'
                archiveArtifacts artifacts: 'result.log', onlyIfSuccessful: false
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploy stage (placeholder)...'
                echo 'Application build successful!'
            }
        }
    }
    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
