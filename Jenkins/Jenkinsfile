def registry = 'https://automationsaan.jfrog.io' // Artifactory base URL (no trailing slash)
// Jenkins Declarative Pipeline definition
pipeline {
    agent {
        node {
            label 'maven' // Use Jenkins agent/node labeled 'maven' for builds
        }
    }
    environment {
        // Set JAVA_HOME and update PATH to use Java 21 and Maven 3.9.9
        JAVA_HOME = "/lib/jvm/java-21-openjdk-amd64"
        PATH = "/opt/apache-maven-3.9.9/bin:$JAVA_HOME/bin:$PATH"
    }
    stages {
        // Build stage: compiles code and runs all tests
        stage('Build') {
            steps {
                echo "JAVA VERSION:" // Print Java version for debugging
                sh 'java -version'
                echo "MAVEN VERSION:" // Print Maven version for debugging
                sh 'mvn -version'
                echo "----------- build started ----------"
                sh 'mvn clean verify' // Clean, compile, and run tests
                echo "----------- build completed ----------"
            }
        }
        // Test stage: generates test reports
        stage('Test') {
            steps {
                echo "----------- unit test started ----------"
                sh 'mvn surefire-report:report' // Generate Surefire test report
                echo "----------- unit test completed ----------"
            }
        }
        // SonarQube analysis stage: runs static code analysis
        stage('SonarQube analysis') {
            environment {
                scannerHome = tool 'sonar-scanner' // Use SonarQube scanner tool
            }
            steps {
                withSonarQubeEnv('sonarqube-server') { // Use SonarQube server credentials
                    echo "----------- SonarQube analysis started ----------"
                    sh "${scannerHome}/bin/sonar-scanner" // Run SonarQube analysis
                    echo "----------- SonarQube analysis completed ----------"
                }
            }
        }
        // Quality Gate stage: skipped due to SonarCloud premium requirement
        // stage('Quality Gate') {
        //     steps {
        //         echo "----------- Quality Gate started ----------"
        //         script {
        //             timeout(time: 15, unit: 'MINUTES') { // Wait up to 15 minutes
        //                 def qg = waitForQualityGate() // Get quality gate result
        //                 if (qg.status != 'OK') {
        //                     error "Pipeline aborted due to quality gate failure: ${qg.status}" // Fail if not OK
        //                 }
        //             }
        //         }
        //         echo "----------- Quality Gate completed ----------"
        //     }
        // }
        // Jar Publish stage: uploads the built JAR to Artifactory local repository
        stage('Jar Publish') {
            steps {
                script {
                    echo '<--------------- Jar Publish Started --------------->'
                    // Create Artifactory server object using the base URL and credentials
                    def server = Artifactory.newServer url:registry+"/artifactory", credentialsId:"jfrog-artifact-cred"
                    // Build properties for traceability (build ID and commit ID)
                    def properties = "buildid=${env.BUILD_ID},commitid=${GIT_COMMIT}";
                    // Upload spec: upload JAR(s) from target/ to the correct local repo in Artifactory
                    // 'flat: true' ensures the JAR is uploaded without the 'target/' directory in Artifactory
                    def uploadSpec = """
                        {
                          \"files\": [
                            {
                              \"pattern\": \"target/*.jar\",
                              \"target\": \"hello-world-spring-libs-release-local/\",
                              \"flat\": \"true\",
                              \"props\" : \"${properties}\",
                              \"exclusions\": [ \"*.sha1\", \"*.md5\"]
                            }
                          ]
                        }
                    """
                    def buildInfo = server.upload(uploadSpec) // Upload the JAR to Artifactory local repo
                    buildInfo.env.collect() // Collect environment info for traceability
                    server.publishBuildInfo(buildInfo) // Publish build info to Artifactory
                    echo '<--------------- Jar Publish Ended --------------->'
                }
            }
        }
    }
}
