FROM registry.redhat.io/openshift4/ose-jenkins-agent-base
USER root
RUN yum install -y git python && curl https://copr.fedorainfracloud.org/coprs/alsadi/dumb-init/repo/epel-7/alsadi-dumb-init-epel-7.repo && \
yum -y install rh-python36 rh-python36-python-tools && curl -O https://raw.githubusercontent.com/MoOyeg/testFlask/master/requirements.txt && \
/opt/rh/rh-python36/root/usr/bin/pip install -r requirements.txt
ENV PATH="/opt/rh/rh-python36/root/usr/bin/python:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
USER 1001
