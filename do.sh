#!/bin/bash
#
# Punto de entrada para el servicio GIT
#
# Activar el debug de este script:
# set -eux

##################################################################
#
# main
#
##################################################################

# Averiguar si necesito configurar por primera vez
#
CONFIG_DONE="/.config_mysql_done"
NECESITA_PRIMER_CONFIG="si"
if [ -f ${CONFIG_DONE} ] ; then
    NECESITA_PRIMER_CONFIG="no"
fi

##################################################################
#
# PREPARAR MYSQL
#
##################################################################

chown -R mysql:mysql /var/lib/mysql

# Creo la estructura MySSQL si no existe... 
#if [ ! -d '/var/lib/mysql/mysql' -a "${1%_safe}" = 'mysqld' ]; then
if [ ! -d '/var/lib/mysql/mysql' ]; then

	# Necesito la contraseña de root, si no la tengo aborto...
	if [ -z "${MYSQL_ROOT_PASSWORD}" ]; then
		echo >&2 "error: MySQL no está inicializado y falta la contraseña de root, variable: MYSQL_ROOT_PASSWORD"
		exit 1
	fi

	# Creo la estructura
	mysql_install_db --user=mysql --datadir=/var/lib/mysql
	
	# Creo root y borro la base de datos test
	TEMP_FILE='/tmp/mysql-first-time.sql'
	cat > "$TEMP_FILE" <<-EOSQL
		DELETE FROM mysql.user ;
		CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
		GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
		DROP DATABASE IF EXISTS test ;
		FLUSH PRIVILEGES ;
	EOSQL

	set -- /usr/local/mysql/bin/mysqld --datadir=/var/lib/mysql --user=mysql --init-file="$TEMP_FILE"
fi

##################################################################
#
# PREPARAR EL CONTAINER POR PRIMERA VEZ
#
##################################################################

# Necesito configurar por primera vez?
#
if [ ${NECESITA_PRIMER_CONFIG} = "si" ] ; then

	############
	#
	# Supervisor
	# 
	############
	echo "Configuro supervisord.conf"

	cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
[unix_http_server]
file=/var/run/supervisor.sock 					; path to your socket file

[inet_http_server]
port = 0.0.0.0:9001								; allow to connect from web browser to supervisord

[supervisord]
logfile=/var/log/supervisor/supervisord.log 	; supervisord log file
logfile_maxbytes=50MB 							; maximum size of logfile before rotation
logfile_backups=10 								; number of backed up logfiles
loglevel=error 									; info, debug, warn, trace
pidfile=/var/run/supervisord.pid 				; pidfile location
minfds=1024 									; number of startup file descriptors
minprocs=200 									; number of process descriptors
user=root 										; default user
childlogdir=/var/log/supervisor/ 				; where child log files will live

nodaemon=false 									; run supervisord as a daemon when debugging
;nodaemon=true 									; run supervisord interactively (production)
 
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface
 
[supervisorctl]
serverurl=unix:///var/run/supervisor.sock		; use a unix:// URL for a unix socket 

# Para enviar logs
[program:mysql]
process_name = mysql
command=/usr/local/mysql/bin/mysqld --datadir=/var/lib/mysql --user=mysql
startsecs = 0
autorestart = true

## En caso de debug
#[program:sshd]
#process_name = sshd
#command=/usr/sbin/sshd -D
#startsecs = 0
#autorestart = true

EOF

    #
    # Creo el fichero de control para que el resto de 
    # ejecuciones no realice la primera configuración
    > ${CONFIG_DONE}
	
fi


##################################################################
#
# EJECUCIÓN DEL COMANDO SOLICITADO
#
##################################################################
#
exec "$@"
