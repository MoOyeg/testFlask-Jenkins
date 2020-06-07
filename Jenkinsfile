pipeline {
agent {
  kubernetes {
    label "python-agent"
    cloud "openshift"
    containerTemplate {
      name "jnlp"
      image "image-registry.openshift-image-registry.svc:5000/$JENKINS_NAMESPACE/python-jenkins:latest"  
      resourceRequestMemory "500Mi"
      resourceLimitMemory "500Mi"
      resourceRequestCpu "300m"
      resourceLimitCpu "300m"
      alwaysPullImage "True"
    }
  }
}

environment {
  // Define global variables
  mvnCmd = "mvn"
  
  // Images and Projects
  imageName   = "tasks"
  devProject  = "${GUID}-tasks-dev"
  prodProject = "${GUID}-tasks-prod"

  // Tags
  devTag      = "0.0-0"
  prodTag     = "0.0"

  // Blue-Green Settings
  destApp     = "tasks-green"
  activeApp   = ""
}


  stages {

    stage('Checkout Source') {
     steps {
       echo "Checking out Code}"
       checkout scm

         script {
           sh "ls ./"
         }
      }     
    }

   
  }
}

