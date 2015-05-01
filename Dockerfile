#
# "MySQL" base by Luispa, Dec 2014
# 
# -----------------------------------------------------

#
# Desde donde parto...
#
FROM debian:jessie

# Autor de este Dockerfile
#
MAINTAINER Luis Palacios <luis@luispa.com>

# Pido que el frontend de Debian no sea interactivo
ENV DEBIAN_FRONTEND noninteractive

# ------- ------- ------- ------- ------- ------- -------
# Básico
# ------- ------- ------- ------- ------- ------- -------

# Actualizo el sistema operativo e instalo lo mínimo
#
RUN apt-get update && \
    apt-get -y install 	locales \
    					net-tools \
                       	vim \
                       	supervisor \
                       	wget \
                       	curl \
                        rsyslog

# Preparo locales y Timezone
#
RUN locale-gen es_ES.UTF-8
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN echo "Europe/Madrid" > /etc/timezone; dpkg-reconfigure -f noninteractive tzdata

# Workaround para el Timezone, en vez de montar el fichero en modo read-only:
# 1) En el DOCKERFILE
RUN mkdir -p /config/tz && mv /etc/timezone /config/tz/ && ln -s /config/tz/timezone /etc/
# 2) En el Script entrypoint:
#     if [ -d '/config/tz' ]; then
#         dpkg-reconfigure -f noninteractive tzdata
#         echo "Hora actual: `date`"
#     fi
# 3) Al arrancar el contenedor, montar el volumen, a contiuación un ejemplo:
#     /Apps/data/tz:/config/tz
# 4) Localizar la configuración:
#     echo "Europe/Madrid" > /Apps/data/tz/timezone
 
# ------- ------- ------- ------- ------- ------- -------
# MySQL
# ------- ------- ------- ------- ------- ------- -------

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r mysql && useradd -r -g mysql mysql

# FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
# File::Basename
# File::Copy
# Sys::Hostname
# Data::Dumper
RUN apt-get update && apt-get install -y perl --no-install-recommends && rm -rf /var/lib/apt/lists/*

# mysqld: error while loading shared libraries: libaio.so.1: cannot open shared object file: No such file or directory
RUN apt-get update && apt-get install -y libaio1 && rm -rf /var/lib/apt/lists/*

# gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
RUN gpg --keyserver pgp.mit.edu --recv-keys A4A9406876FCBD3C456770C88C718D3B5072E1F5

ENV MYSQL_MAJOR 5.6
ENV MYSQL_VERSION 5.6.21

# note: we're pulling the *.asc file from mysql.he.net instead of dev.mysql.com because the official mirror 404s that file for whatever reason - maybe it's at a different path?
RUN apt-get update && apt-get install -y curl --no-install-recommends && rm -rf /var/lib/apt/lists/* \
	&& curl -SL "http://dev.mysql.com/get/Downloads/MySQL-$MYSQL_MAJOR/mysql-$MYSQL_VERSION-linux-glibc2.5-x86_64.tar.gz" -o mysql.tar.gz \
	&& curl -SL "http://mysql.he.net/Downloads/MySQL-$MYSQL_MAJOR/mysql-$MYSQL_VERSION-linux-glibc2.5-x86_64.tar.gz.asc" -o mysql.tar.gz.asc \
	&& apt-get purge -y --auto-remove curl \
	&& gpg --verify mysql.tar.gz.asc \
	&& mkdir /usr/local/mysql \
	&& tar -xzf mysql.tar.gz -C /usr/local/mysql --strip-components=1 \
	&& rm mysql.tar.gz* \
	&& rm -rf /usr/local/mysql/mysql-test /usr/local/mysql/sql-bench \
	&& rm -rf /usr/local/mysql/bin/*-debug /usr/local/mysql/bin/*_embedded \
	&& find /usr/local/mysql -type f -name "*.a" -delete \
	&& apt-get update && apt-get install -y binutils && rm -rf /var/lib/apt/lists/* \
	&& { find /usr/local/mysql -type f -executable -exec strip --strip-all '{}' + || true; } \
	&& apt-get purge -y --auto-remove binutils
ENV PATH $PATH:/usr/local/mysql/bin:/usr/local/mysql/scripts

# Directorio al que conmuto...
WORKDIR /usr/local/mysql

# Soy MySQL, tendré que escuchar no? :)
EXPOSE 3306

# ------- ------- ------- ------- ------- ------- -------
# DEBUG ( Descomentar durante debug del contenedor )
# ------- ------- ------- ------- ------- ------- -------
#
# Herramientas SSH, tcpdump y net-tools
#RUN apt-get update && \
#    apt-get -y install openssh-server \
#                       tcpdump \
#                       net-tools
## Setup de SSHD
#RUN mkdir /var/run/sshd
#RUN echo 'root:docker' | chpasswd
#RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
#RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
#ENV NOTVISIBLE "in users profile"
#RUN echo "export VISIBLE=now" >> /etc/profile

## Script que uso a menudo durante las pruebas. Es como "cat" pero elimina líneas de comentarios
RUN echo "grep -vh '^[[:space:]]*#' \"\$@\" | grep -v '^//' | grep -v '^;' | grep -v '^\$' | grep -v '^\!' | grep -v '^--'" > /usr/bin/confcat
RUN chmod 755 /usr/bin/confcat

#-----------------------------------------------------------------------------------

# Ejecutar siempre al arrancar el contenedor este script
#
ADD do.sh /do.sh
RUN chmod +x /do.sh
ENTRYPOINT ["/do.sh"]

#
# Si no se especifica nada se ejecutará lo siguiente: 
#
CMD ["/usr/bin/supervisord", "-n -c /etc/supervisor/supervisord.conf"]



