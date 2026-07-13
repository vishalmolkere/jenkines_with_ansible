pipeline {
    agent any

    // ── Environment variables ────────────────────────────────────────────────
    environment {
        // Docker Hub
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-credentials')   // Jenkins credential ID
        DOCKER_IMAGE          = "vishalmolkere/employeemanagement"
        IMAGE_TAG             = "${env.BUILD_NUMBER}"                   // e.g. "42"
        IMAGE_FULL            = "${DOCKER_IMAGE}:${IMAGE_TAG}"
        IMAGE_LATEST          = "${DOCKER_IMAGE}:latest"

        // Ansible
        ANSIBLE_PLAYBOOK      = "ansible/deploy.yml"
        ANSIBLE_INVENTORY     = "ansible/inventory.ini"
    }

    // ── Shared tools ─────────────────────────────────────────────────────────
    tools {
        maven 'Maven-3.9'   // name configured in Jenkins → Global Tool Configuration
        jdk   'JDK-17'      // name configured in Jenkins → Global Tool Configuration
    }

    // ── Pipeline stages ──────────────────────────────────────────────────────
    stages {

        // ── 1. Source Code ───────────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo '📥  Pulling source code from GitHub …'
                checkout scm
            }
        }

        // ── 2. Build ─────────────────────────────────────────────────────────
        stage('Build') {
            steps {
                echo '🔨  Building application with Maven …'
                sh 'mvn clean package -DskipTests -B'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }

        // ── 3. Unit Tests ────────────────────────────────────────────────────
        stage('Unit Tests') {
            steps {
                echo '🧪  Running unit tests …'
                sh 'mvn test -B'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
                }
                failure {
                    error '❌  Unit tests failed — pipeline aborted.'
                }
            }
        }

        // ── 4. Docker Build ──────────────────────────────────────────────────
        stage('Docker Build') {
            steps {
                echo "🐳  Building Docker image: ${IMAGE_FULL} …"
                sh """
                    docker build \
                        --tag ${IMAGE_FULL} \
                        --tag ${IMAGE_LATEST} \
                        --label "build=${env.BUILD_NUMBER}" \
                        --label "git-commit=${env.GIT_COMMIT}" \
                        .
                """
            }
        }

        // ── 5. Push to Docker Hub ────────────────────────────────────────────
        stage('Push to Docker Hub') {
            steps {
                echo '📤  Pushing Docker image to Docker Hub …'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login -u "\$DOCKER_USER" --password-stdin
                        docker push ${IMAGE_FULL}
                        docker push ${IMAGE_LATEST}
                        docker logout
                    """
                }
            }
        }

        // ── 6 & 7. Ansible Deployment ────────────────────────────────────────
        stage('Deploy via Ansible') {
            steps {
                echo '🚀  Triggering Ansible playbook to deploy on Worker Server …'
                sh """
                    ansible-playbook \
                        -i ${ANSIBLE_INVENTORY} \
                        ${ANSIBLE_PLAYBOOK} \
                        --extra-vars "docker_image=${IMAGE_FULL}" \
                        -v
                """
            }
        }

        // ── 8. Smoke-test: verify app is up ──────────────────────────────────
        stage('Verify Deployment') {
            steps {
                echo '✅  Verifying the application is running on the worker server …'
                script {
                    // Read worker IP from inventory (or hard-code it here)
                    def workerIp = sh(
                        script: "grep -A1 '\\[worker\\]' ${ANSIBLE_INVENTORY} | tail -1 | awk '{print \$1}'",
                        returnStdout: true
                    ).trim()

                    // Retry for up to 3 minutes (18 × 10 s)
                    retry(18) {
                        sleep(time: 10, unit: 'SECONDS')
                        def status = sh(
                            script: "curl -s -o /dev/null -w '%{http_code}' http://${workerIp}:8080/actuator/health || true",
                            returnStdout: true
                        ).trim()
                        if (status != '200') {
                            error "App not healthy yet (HTTP ${status}) — retrying …"
                        }
                        echo "✅  Application is UP at http://${workerIp}:8080  (HTTP ${status})"
                    }
                }
            }
        }
    }

    // ── Post-pipeline actions ────────────────────────────────────────────────
    post {
        always {
            echo '🧹  Cleaning up local Docker images …'
            sh """
                docker rmi ${IMAGE_FULL} || true
                docker rmi ${IMAGE_LATEST} || true
            """
            cleanWs()
        }
        success {
            echo "🎉  Pipeline SUCCESS — Build #${env.BUILD_NUMBER} deployed."
        }
        failure {
            echo "💥  Pipeline FAILED — Check stage logs above."
        }
    }
}
