# Introducción

Este repositorio alberga un *contenedor Docker* para "[MySQL](http://www.mysql.com/)". Lo tienes automatizado en el registry hub de Docker [luispa/base-mysql](https://registry.hub.docker.com/u/luispa/base-mysql/) con los fuentes en GitHub: [base-mysql](https://github.com/LuisPalacios/base-mysql). Lo uso en combinación con otros contenedores. Consulta este [apunte técnico sobre varios servicios en contenedores Docker](http://www.luispa.com/?p=172) para acceder a otros contenedores Docker y sus fuentes en GitHub.


## Ficheros

* **Dockerfile**: Para crear la base de servicio.
* **do.sh**: Para arrancar el contenedor creado con esta imagen.

## Instalación de la imagen

### desde Docker

Para usar esta imagen desde el registry de docker hub

    totobo ~ $ docker pull luispa/base-mysql

### manualmente

Si prefieres crear la imagen de forma manual en tu sistema, primero debes clonarla desde Github para luego ejecutar el build

    $ git clone https://github.com/LuisPalacios/base-mysql.git
    $ docker build -t luispa/base-mysql ./


# Personalización

La primera vez que arranques el contenedor es muy importante porque analizará si es necesario crear la estructura MySQL en el Volumen. Si lo encuentra vacío la creará y la contraseña de root será la que indiquemos en la variable MYSQL_ROOT_PASSWORD. Si por el contrario encuentra una estructura ya existente entonces la utilizará.


### Volumen

Directorio persistente para la estructura MySQL, debe apuntar a un directorio de tu HOST (/Apps/data/blog/db/mysql) que se montará en el contenedor como /var/lib/mysql.

   - "/Directorio/Persistente/En/Tu/Host:/var/lib/mysql"  


Directorio persistente para configurar el Timezone. Crear el directorio /Apps/data/tz y dentro de él crear el fichero timezone. Luego montarlo con -v o con fig.yml

    Montar:
       "/Apps/data/tz:/config/tz"  
    Preparar: 
       $ echo "Europe/Madrid" > /config/tz/timezone


### Variable: MYSQL_ROOT_PASSWORD

Contraseña del usuario "root" que se asignará a MySQL si descubre el directorio vacío y necesita crear la estructura inicial. 


### Troubleshooting

A continuación un ejemplo sobre cómo ejecutar manualmente el contenedor, útil para hacer troubleshooting. 

    docker run --rm -t -i -p 3306:3306 -e MYSQL_ROOT_PASSWORD="mipase" -v /Apps/data/pruebas:/var/lib/mysql luispa/base-mysql /bin/bash
