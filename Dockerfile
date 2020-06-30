FROM registry.redhat.io/openshift4/ose-jenkins-agent-base
USER root
RUN yum install -y git && \
yum -y install rh-python36 rh-python36-python-tools && curl -O https://raw.githubusercontent.com/MoOyeg/testFlask/master/requirements.txt && \
/opt/rh/rh-python36/root/usr/bin/pip install --upgrade pip && /opt/rh/rh-python36/root/usr/bin/pip install -r requirements.txt
ENV PATH="/opt/rh/rh-python36/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ENV PYTHONPATH="/opt/rh/rh-python36/root/usr/lib/python3.6/site-packages"
USER 1001
