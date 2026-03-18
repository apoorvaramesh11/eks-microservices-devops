pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "product-catalog"
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REPO = credentials('docker-username') // Jenkins credential ID
        DOCKER_CREDS = credentials('docker-creds')   // username + password/token
        GIT_CREDS = credentials('github-creds')
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/your-repo.git'
            }
        }

        stage('Build & Test') {
            parallel {

                stage('Build') {
                    steps {
                        sh '''
                        cd src/product-catalog
                        go mod download
                        go build -o product-catalog-service main.go
                        '''
                    }
                }

                stage('Unit Tests') {
                    steps {
                        sh '''
                        cd src/product-catalog
                        go test ./...
                        '''
                    }
                }

                stage('Lint') {
                    steps {
                        sh '''
                        curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s latest
                        export PATH=$PATH:$(pwd)/bin
                        cd src/product-catalog
                        golangci-lint run
                        '''
                    }
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'docker-creds') {
                        def app = docker.build("${DOCKER_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}", "src/product-catalog")
                        app.push()
                    }
                }
            }
        }

        stage('Update Kubernetes Manifest') {
            steps {
                sh '''
                sed -i "s|image: .*|image: ${DOCKER_REPO}/${DOCKER_IMAGE}:${DOCKER_TAG}|" kubernetes/productcatalog/deploy.yaml
                '''
            }
        }

        stage('Commit & Push Changes') {
            steps {
                sh '''
                git config user.email "ci@jenkins.com"
                git config user.name "Jenkins CI"

                git add kubernetes/productcatalog/deploy.yaml

                git diff --quiet || git commit -m "[CI]: Update product catalog image tag"

                git push https://${GIT_CREDS_USR}:${GIT_CREDS_PSW}@github.com/your-repo.git HEAD:main
                '''
            }
        }

        // Optional Manual Approval for Production
        stage('Approval') {
            when {
                branch 'main'
            }
            steps {
                input message: "Deploy to Production?"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl apply -f kubernetes/productcatalog/deploy.yaml
                '''
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully"
        }
        failure {
            echo "❌ Pipeline failed"
        }
        always {
            cleanWs()
        }
    }
}
