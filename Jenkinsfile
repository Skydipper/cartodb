#!groovy

node {

  // Variables
  def tokens = "${env.JOB_NAME}".tokenize('/')
  def appName = tokens[0]
  def dockerUsername = "${DOCKER_USERNAME}"
  def imageTag = "${dockerUsername}/${appName}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"

  currentBuild.result = "SUCCESS"

  checkout scm
  properties([pipelineTriggers([[$class: 'GitHubPushTrigger']])])

  try {

    stage ('Build docker') {

      sh("docker -H :2375 build --build-arg CARTO_USERNAME=${CARTO_USERNAME} --build-arg CARTO_PASSWORD=${CARTO_PASSWORD} --build-arg CARTO_USEREMAIL=${CARTO_USEREMAIL} -t ${dockerUsername}/${appName}:latest .")
    }

    stage('Push Docker') {
      withCredentials([usernamePassword(credentialsId: 'Skydipper Docker Hub', usernameVariable: 'DOCKER_HUB_USERNAME', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
        sh("docker -H :2375 login -u ${DOCKER_HUB_USERNAME} -p ${DOCKER_HUB_PASSWORD}")
        sh("docker -H :2375 push ${imageTag}")
        sh("docker -H :2375 push ${dockerUsername}/${appName}:latest")
        sh("docker -H :2375 rmi ${imageTag}")
      }
    }

    stage ("Deploy Application") {
      switch ("${env.BRANCH_NAME}") {

        // Roll out to production
        case "master":
          def userInput = true
          def didTimeout = false
          try {
            timeout(time: 60, unit: 'SECONDS') {
              userInput = input(
                id: 'Proceed1', message: 'Confirm deployment', parameters: [
                [$class: 'BooleanParameterDefinition', defaultValue: true, description: '', name: 'Please confirm you agree with this deployment']
              ])
            }
          }
          catch(err) { // timeout reached or input false
              sh("echo Aborted by user or timeout")
              if('SYSTEM' == user.toString()) { // SYSTEM means timeout.
                  didTimeout = true
              } else {
                  userInput = false
              }
          }
          if (userInput == true && !didTimeout){
            sh("echo Deploying to PROD cluster")
            sh("kubectl config use-context gke_${GCLOUD_PROJECT}_${GCLOUD_GCE_ZONE}_${KUBE_PROD_CLUSTER}")
            def service = sh([returnStdout: true, script: "kubectl get deploy ${appName} || echo NotFound"]).trim()
            sh("kubectl apply -f k8s/production/")
//             sh("kubectl expose deployment cartodb --port=80 --target-port=80 --name=cartodb --type=LoadBalancer --external-ip=35.233.41.65")
            sh("kubectl set image deployment ${appName} ${appName}=${imageTag} --record")
          } else {
            sh("echo NOT DEPLOYED")
            currentBuild.result = 'SUCCESS'
          }
          break

        // Default behavior?
        default:
          echo "Default -> do nothing"
          currentBuild.result = "SUCCESS"
      }
    }

  } catch (err) {

    currentBuild.result = "FAILURE"
    throw err
  }

}
