pipeline {
agent {
  kubernetes {
    label "maven-agent"
    cloud "openshift"
    containerTemplate {
      name "jnlp"
      image "registry.redhat.io/ubi8"  
      command "echo 1 && sleep 500"
      resourceRequestMemory "500Mi"
      resourceLimitMemory "500Mi"
      resourceRequestCpu "300m"
      resourceLimitCpu "300m"
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

