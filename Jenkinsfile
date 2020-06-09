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
           echo "Creating Mysql Application"
           def fromJSON = openshift.create( readFile( 'mysql.json' ) )
           
           echo "Wait until dc/mysql is available"
           def dcmysql = openshift.selector('dc', "mysql")
           dcmysql.rollout().status()
           echo "dc/mysql is available"
           
           echo "Creating Main Application"
           apply = openshift.apply(openshift.raw("new-app ${REPO} --name=${APP_NAME} -l app=${APP_NAME} --strategy=source --env=APP_CONFIG=${APP_CONFIG} --env=APP_MODULE=${APP_MODULE} --env=MYSQL_NAME=${MYSQL_NAME} --env=MYSQL_DB=${MYSQL_DB} --dry-run --output=yaml").actions[0].out)
               
           openshift.raw("set env dc/${APP_NAME} --from=secret/my-secret")
           openshift.raw("expose svc ${APP_NAME}")
           openshift.raw("label dc/mysql app=${APP_NAME}")
           openshift.raw("label dc/${APP_NAME} app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("label dc/mysql app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("annotate dc/${APP_NAME} app.openshift.io/connects-to=mysql")

           echo "Wait until dc/${APP_NAME} is available"
           def dcmainapp = openshift.selector('dc', "${APP_NAME}")
           dcmainapp.rollout().status()
           echo "dc/${APP_NAME} is available"
          }
         }
       }

      }     
    }
    
    stage('Run System Testing') {
     steps {
       echo "Starting System Testing"
       script {
         echo "Obtain ${APP_NAME} service"
         def svc_name = "http://${APP_NAME}.${DEV_PROJECT}.svc:8080"
        //def latestDeploymentVersion = openshift.selector('dc',"simple-python").object().status.latestVersion       
         echo "Test Application Status Code == 200"
         status_code1 = sh "curl -s -o /dev/null -w \"%{http_code}\" ${svc_name}"
         echo "${status_code1}"
         //if ( "${status_code1}" == "200" ){
         //  echo "Application Passed Service Response Test"
         //} else {
         //  error("Application Failed Service Response Test")
         //}

       }
      }     
    }  
   
  }
}
