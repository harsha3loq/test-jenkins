FROM ubuntu:16.04

MAINTAINER 3LOQ 

# Installing basic requirements along with python2 and python3 
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
    build-essential \
    ca-certificates \
    gcc \
    git \
    libpq-dev \
    make \
    python-pip \
    python2.7 \
    python2.7-dev \
    ssh \
    vim \
    wget \
    && apt-get autoremove \
    && apt-get clean

# Virtualenv
RUN pip install -U "virtualenv==15.0.1"

# Installing software-properties-common to solve "add-apt" issue
RUN apt-get install -y software-properties-common

# java-8
RUN apt-get update 
RUN apt-get install -y openjdk-8-jdk


# Scala
RUN wget http://www.scala-lang.org/files/archive/scala-2.11.8.tgz && \
    tar -xzf /scala-2.11.8.tgz -C /usr/local/ && \
    ln -s /usr/local/scala-2.11.8 $SCALA_HOME && \
    rm scala-2.11.8.tgz 
RUN apt-get update
RUN apt-get install curl

# Sbt
RUN curl -L -o sbt-1.0.4.deb https://dl.bintray.com/sbt/debian/sbt-1.0.4.deb && \ 
	dpkg -i sbt-1.0.4.deb && \ 
	rm sbt-1.0.4.deb && \ 
	apt-get update && \ 
	apt-get install sbt && \ 
	sbt sbtVersion

# Spark
RUN apt-get update \
    && apt-get dist-upgrade -y \
    && wget https://archive.apache.org/dist/spark/spark-2.2.0/spark-2.2.0-bin-hadoop2.7.tgz \
    && tar -xzf spark-2.2.0-bin-hadoop2.7.tgz && \
    mv spark-2.2.0-bin-hadoop2.7 /spark && \
    rm spark-2.2.0-bin-hadoop2.7.tgz

# Postgresql
RUN add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main" \
    && wget -q -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \ 
    && apt-get update \ 
    && apt-get install -y postgresql-9.6 postgresql-contrib-9.6

RUN /etc/init.d/postgresql start
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/9.6/main/pg_hba.conf &&\
    echo "listen_addresses='*'" >> /etc/postgresql/9.6/main/postgresql.conf
#    psql --command "CREATE USER user WITH SUPERUSER PASSWORD 'user';" &&\
#    createdb -O docker docker

# Hadoop
RUN \
    wget https://archive.apache.org/dist/hadoop/core/hadoop-2.7.3/hadoop-2.7.3.tar.gz && \
    tar -xzf hadoop-2.7.3.tar.gz && \
    mv hadoop-2.7.3 /opt/hadoop && \
    echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/" >> /opt/hadoop/etc/hadoop/hadoop-env.sh 

RUN mv /opt/hadoop/etc/hadoop/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml_bac
RUN echo " <configuration> \
 <property> \
<name>fs.defaultFS</name> \
<value>hdfs://localhost:9000</value> \
</property> \ 
</configuration>" >> /opt/hadoop/etc/hadoop/core-site.xml

RUN mv /opt/hadoop/etc/hadoop/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml_bac
RUN echo "<configuration> \
    <property> \
        <name>dfs.replication</name> \
 <value>1</value> \
    </property> \
</configuration>" >> /opt/hadoop/etc/hadoop/hdfs-site.xml

#RUN mv /opt/hadoop/etc/hadoop/mapred-site.xml.template /opt/hadoop/etc/hadoop/mapred-site.xml

RUN echo "<configuration> \
    <property> \
        <name>mapreduce.framework.name</name> \
        <value>yarn</value> \
    </property> \
</configuration>" >> /opt/hadoop/etc/hadoop/mapred-site.xml

RUN mv /opt/hadoop/etc/hadoop/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml_bac
RUN echo "<configuration> \
    <property> \
        <name>yarn.nodemanager.aux-services</name> \
        <value>mapreduce_shuffle</value> \
    </property> \
    <property> \
       <name>yarn.resourcemanager.address</name> \
       <value>127.0.0.1:8032</value> \
</property> \
</configuration>" >> /opt/hadoop/etc/hadoop/yarn-site.xml


RUN echo "export HADOOP_HOME=/opt/hadoop \
export HADOOP_INSTALL=$HADOOP_HOME \
export HADOOP_MAPRED_HOME=$HADOOP_HOME \
export HADOOP_COMMON_HOME=$HADOOP_HOME \
export HADOOP_HDFS_HOME=$HADOOP_HOME \
export YARN_HOME=$HADOOP_HOME \
export HADOOP_COMMON_LIB_NATIVEDIR=$HADOOP_HOME/lib/native \
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin \
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native" " >> ~/.bashrc

RUN /bin/bash -c "source ~/.bashrc"
#RUN source /root/.bashrc
# SSH Keys
RUN \
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && \
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys && \
  chmod 0600 ~/.ssh/authorized_keys     

RUN apt-get install sudo -y

#RUN wget --quiet https://repo.anaconda.com/archive/Anaconda3-5.3.0-Linux-x86_64.sh -O ~/anaconda.sh && \
#    /bin/bash ~/anaconda.sh -b -p /opt/conda && \
#    rm ~/anaconda.sh && \
#    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
 #   echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \ 
 #   echo "conda activate base" >> ~/.bashrc

#Conda
RUN wget https://repo.continuum.io/archive/Anaconda3-5.0.1-Linux-x86_64.sh && \
    bash Anaconda3-5.0.1-Linux-x86_64.sh -b && \
    rm Anaconda3-5.0.1-Linux-x86_64.sh

#Env for conda
ENV PATH /root/anaconda3/bin:$PATH
RUN conda update conda

#Create conda environment here and add packages as needed
RUN conda create -n pythonenv python=3.6.8 pandas numpy keras tensorflow scikit-learn 
#RUN source activate pythonenv
RUN echo "export PATH=/root/anaconda3/bin:$PATH" >> ~/.bashrc
RUN /bin/bash -c "source ~/.bashrc"

#GIT CLONE  
#MAKE SURE YOU DELETE THE TOKEN AFTER CREATING THE IMAGE
RUN mkdir /opt/repos 
WORKDIR /opt/repos
RUN git clone -b OctopusIngestion https://token@github.com/3loq/habitual-spark.git
WORKDIR /opt/repos/habitual-spark/

#Create a jar while building the images itself 
RUN sbt assembly


#Test Case for Git
#RUN /bin/bash -c "export uname"
#RUN /bin/bash -c "export pname"
#RUN /bin/bash -c "git clone https://$uname:$pname@github.com/harshahemanth/yolo.git"

# Git Clones
#ARG username
#ARG password
#RUN git clone https://$username:$password@github.com/harsha3loq/monit_dev.git
#Not the best way to clone . . .



#Setting environment variables for spark, sbt, scala
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME /opt/hadoop
ENV PATH ${HADOOP_HOME}/bin:$PATH
ENV SPARK_HOME /spark
ENV PATH ${SPARK_HOME}/bin:$PATH

ENV SBT_VERSION		1.0.4
ENV SBT_HOME		/usr/local/sbt
ENV SCALA_VERSION	2.11.8
ENV SCALA_HOME		/usr/local/scala-2.11.8
ENV PATH		$SCALA_HOME/bin:$SBT_HOME/bin:$PATH

#Expose all the ports here
EXPOSE 5432 8088 50070 50075 50030 50060 4040

CMD []
ENTRYPOINT ["/bin/bash"]
