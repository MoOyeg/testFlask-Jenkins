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
       checkout scm

         script {
           def pom = readMavenPom file: 'pom.xml'
           def version = pom.version

           // Set the tag for the development image: version + build number
           devTag  = "${version}-" + currentBuild.number
           // Set the tag for the production image: version
           prodTag = "${version}"

           // Patch Source artifactId to include GUID
           sh "sed -i 's/GUID/${GUID}/g' ./pom.xml"
         }
      }     
    }

   
  }
}

