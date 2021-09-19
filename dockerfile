FROM centos:7

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN yum check-update; \
    yum install -y gcc libffi-devel python3 epel-release; \
    yum install -y python3-pip; \
    yum install -y wget; \
    yum -y install openssh-server openssh-clients; \
    yum clean all

RUN pip3 install --upgrade pip
RUN pip3 install "ansible"
RUN wget -q https://raw.githubusercontent.com/ansible-collections/azure/dev/requirements-azure.txt
RUN pip3 install -r requirements-azure.txt
RUN rm requirements-azure.txt
RUN ansible-galaxy collection install azure.azcollection

RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
COPY ./azure-cli.repo /etc/yum.repos.d/azure-cli.repo
RUN yum -y install azure-cli
RUN yum -y install expect
RUN az extension add --name resource-graph

USER root
COPY ./home/ /root/
