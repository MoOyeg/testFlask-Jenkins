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

  stages {

    stage('Checkout Pipeline Source') {
     steps {
       echo "Checking out Code}"
       checkout scm
      }     
    }


    stage('Clone Application Source') {
     steps {
       echo "Clone our Application Source Code}"
       script {             
             sh "git clone ${REPO}"
          }
      }     
    }

    stage('Run Unit Testing') {
     steps {
       echo "Starting Unit Testing"
       script {
         try {
           sh "python ./testFlask/test.py"
         } catch (Exception e) {
           error("Build failed at Unittest")
         }
       echo "Unittest Passed"
       }
      }     
    }

    stage('Create Test Version of Application') {
     steps {
       script {
         openshift.withCluster() {
           openshift.withProject( "${DEV_PROJECT}" ){
            // def app = openshift.newApp('mysql')  
            // def dc = app.narrow('dc')
            // def dcmap = dc.object()           
            // openshift.apply(dcmap)
           def fromJSON = openshift.create( readFile( 'mysql.json' ) )
           echo "Wait until dc/mysql is available"
           def dc = openshift.selector('dc', "mysql")
           dc.rollout().status()
           echo "dc/mysql is available"
           apply = openshift.apply(openshift.raw("new-app ${REPO} --name=${APP_NAME} -l app=${APP_NAME} --strategy=source --env=APP_CONFIG=${APP_CONFIG} --env=APP_MODULE=${APP_MODULE} --env=MYSQL_NAME=${MYSQL_NAME} --env=MYSQL_DB=${MYSQL_DB}").actions[0].out)
           //def fromJSON2 = openshift.create( readFile( 'app.json' ) )
                      }
         }
       }

      }     
    }
    
    
   
  }
}

