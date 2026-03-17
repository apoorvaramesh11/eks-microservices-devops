pipeline {
    agent any

    environment {
        REGISTRY = "docker.io/yourdockerhub"
        DOCKER_CREDS = "dockerhub-creds"
    }

    options {
        timestamps()
    }

    stages {

        stage('Checkout') {
            steps {
                git 'https://github.com/apoorvaramesh11/eks-microservices-devops.git'
            }
        }

        stage('Detect Services') {
            steps {
                script {
                    SERVICES = sh(
                        script: "ls src",
                        returnStdout: true
                    ).trim().split("\n")

                    echo "Detected services: ${SERVICES}"
                }
            }
        }

        stage('Build Services') {
            steps {
                script {

                    def builds = [:]

                    for (svc in SERVICES) {

                        builds[svc] = {

                            stage("Build-${svc}") {

                                dir("src/${svc}") {

                                    sh '''
                                    echo "Detecting language..."

                                    # Java / Kotlin
                                    if [ -f pom.xml ] || [ -f build.gradle ]; then
                                        echo "Java/Kotlin project"
                                        ./mvnw clean package || mvn clean package || ./gradlew build
                                    fi

                                    # NodeJS / TypeScript
                                    if [ -f package.json ]; then
                                        echo "NodeJS project"
                                        npm install
                                        npm run build || true
                                    fi

                                    # Python
                                    if [ -f requirements.txt ]; then
                                        echo "Python project"
                                        pip install -r requirements.txt
                                    fi

                                    # Go
                                    if [ -f go.mod ]; then
                                        echo "Go project"
                                        go build
                                    fi

                                    # .NET
                                    if ls *.csproj 1> /dev/null 2>&1; then
                                        echo ".NET project"
                                        dotnet build
                                    fi

                                    # Rust
                                    if [ -f Cargo.toml ]; then
                                        echo "Rust project"
                                        cargo build --release
                                    fi

                                    # Ruby
                                    if [ -f Gemfile ]; then
                                        echo "Ruby project"
                                        bundle install
                                    fi

                                    # PHP
                                    if [ -f composer.json ]; then
                                        echo "PHP project"
                                        composer install
                                    fi

                                    # Elixir
                                    if [ -f mix.exs ]; then
                                        echo "Elixir project"
                                        mix deps.get
                                        mix compile
                                    fi

                                    # C++
                                    if ls *.cpp 1> /dev/null 2>&1; then
                                        echo "C++ project"
                                        g++ *.cpp -o app || true
                                    fi
                                    '''
                                }
                            }
                        }
                    }

                    parallel builds
                }
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {

                    def dockerStages = [:]

                    for (svc in SERVICES) {

                        dockerStages[svc] = {

                            stage("Docker-${svc}") {

                                dir("src/${svc}") {

                                    withCredentials([usernamePassword(
                                        credentialsId: DOCKER_CREDS,
                                        usernameVariable: 'USER',
                                        passwordVariable: 'PASS'
                                    )]) {

                                        sh """
                                        echo \$PASS | docker login -u \$USER --password-stdin

                                        docker build -t $REGISTRY/${svc}:${BUILD_NUMBER} .
                                        docker push $REGISTRY/${svc}:${BUILD_NUMBER}
                                        """
                                    }
                                }
                            }
                        }
                    }

                    parallel dockerStages
                }
            }
        }

        stage('Deploy') {
            steps {
                sh "kubectl apply -f manifests/"
            }
        }
    }

    post {

        success {
            echo "All services built successfully"
        }

        failure {
            echo "Pipeline failed"
        }

        always {
            cleanWs()
        }
    }
}