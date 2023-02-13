# Despliegue desde cero.

A partir de ahora viene el despliegue completo desde cero.
	
	
# SERVICIO MOSQUITTO

Vamos a crearlo como servicio en compose. Procedemos a crear el contexto de Dockerfile para mosquitto.
```
sudo mkdir $HOME/mosquitto
```

En el directorio ***mosquitto***, crear un archivo llamado ***docker-entrypoint.sh*** y editarlo. Este script será ejecutado cuando se cree la imagen del contenedor.
```
cd $HOME/mosquitto
```
```
sudo nano docker-entrypoint.sh
```

Pegar el siguiente contenido en el archivo.
```
#!/bin/ash
	
	set -e
	
	if ( [ -z "${MOSQUITTO_USERNAME}" ] || [ -z "${MOSQUITTO_PASSWORD}" ] ); then
	  echo "MOSQUITTO_USERNAME or MOSQUITTO_PASSWORD not defined"
	  exit 1
	fi
	
	# create mosquitto passwordfile
	touch passwordfile
	mosquitto_passwd -b passwordfile $MOSQUITTO_USERNAME $MOSQUITTO_PASSWORD
	
	exec "$@"
```

Guardarlos (Ctrl+X, Y, Enter)

Ahora lo hacemos ejecutable
```
sudo chmod 755 docker-entrypoint.sh
```
	
Creamos un archivo para almacenar variables de entorno. Este archivo se llamará ***environment.env*** (se puede cambiar el nombre) Posteriormente recuperaremos los valores con ***${clave}*** en el archivo ***compose***.
```
sudo nano environment.env
```

Y pegamos el siguiente texto
```
MOSQUITTO_USERNAME=antonio
MOSQUITTO_PASSWORD=el_password
```

Guardamos y salimos.


Creamos el Dockerfile para crear la imagen de mosquitto
```
sudo nano Dockerfile
```

Y pegamos el siguiente texto.
```
FROM eclipse-mosquitto:1.6.3
COPY docker-entrypoint.sh /
ENTRYPOINT ["sh", "./docker-entrypoint.sh"]
CMD ["/usr/sbin/mosquitto", "-c", "/mosquitto/config/mosquitto.conf"]
```

Cuando Compose llame a build para el servicio ***mosquitto***, se creará una imagen basada en la versión de ***eclipse-mosquito:1.6.3***. Se copiará el archivo ***docker-entrypoint.sh*** en la raíz del contenedor (este archivo crea el archivo de password de mosquitto). Se ejecuta ***docker-entrypoint.sh*** dentro del contenedor. Por último se ejecuta el software mosquito indicándole donde está el archivo de configuración. 

La imagen final generada por el Dockerfile se llama "eclipse-mosquitto"
	

Creamos el directorio que almacenará  el archivo de configuración de mosquitto
```
sudo mkdir $HOME/mosquitto/config
```

Creamos un archivo vacío que más adelante almacenará la configuración de mosquitto.
```
sudo touch $HOME/mosquitto/config/mosquitto.conf
```

Creamos dos directorios que serán usados para volúmenes bind.
```
sudo mkdir $HOME/mosquitto/data
```
```
sudo mkdir $HOME/mosquitto/log
```

Todas las configuraciones previas se guardan en el siguiente archivo ***docker-compose.yml***
```
sudo nano $HOME/docker-compose.yml
```

Pegar el siguiente texto (Ojo con el pegado, si se pegan tabuladores \t, da error).
```
version: '3.5'
services:
    # broker MQTT eclipse-mosquitto.
    mosquitto:
    build:
        context: ./mosquitto  # indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
        - ./mosquitto/environment.env # archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
        - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
        - ./mosquitto/data:/mosquitto/data
        - ./mosquitto/log:/mosquitto/log

    ports:
        - 1883:1883
```

Para probarlo
```
cd $HOME
```

Se ejecuta la sección "build" de "docker-compose.yml", que generará las imágenes.
```
docker-compose build
```

Crea el stack o pila se servicios (Por ahora solo "mosquitto")
```
docker-compose up -d
```

Muestra los contenedores levantados.
```
docker container ls  -a
```

Creo un contexto para crear otro contenedor que tenga instaladas las herramientas clientes de mosquitto.
```
sudo mkdir $HOME/mosquitto-clients
```
```
sudo nano $HOME/mosquitto-clients/Dockerfile
```

Pegamos el siguiente texto:
```
FROM ubuntu:19.10
RUN apt-get update && apt-get install -y mosquitto-clients
```	
	
Creamos una imagen con las herramientas para probar MQTT y lo subimos al repositorio.
```
cd $HOME/mosquitto-clients
```
```
docker build -t antsala/mosquitto-clients:latest .
```
```
docker login (Poner credenciales)
```
```
docker image push antsala/mosquitto-clients:latest
``` 

Con ello ya la tenemos para instanciar contenedores para probar MQTT. Creo un contenedor con las herramientas cliente de mosquitto.
```
docker container run -itd --name mqtt_clients antsala/mosquitto-clients:latest
```

Entro en el contenedor
```
docker container exec -it mqtt_clients sh
```

Nos subscribimos a los topics enviados a ***casa/#***.
(Nota:  ***-d = debug***, para ver lo que hace))
```
mosquitto_sub  -h 192.168.1.200 -t casa/# -d -u antonio -P mi_password  
```
		
Abrimos otra conexión de ***PuTTY***, conectamos con el contenedor y enviamos un topic (debe poder leerse desde la otra terminal)
```
docker container exec -it mqtt_clients sh
```

Dentro del contenedor, ejecutamos el siguiente comando.
```
mosquitto_pub -h 192.168.1.200 -m "Topic de prueba desde cocina" -t  "casa/cocina" -d -u antonio -P mi_password
```

Una vez comprobado salimos de los contenedores con ***exit*** o ***Ctrl+C, exit***.

Detenemos el contenedor con las herramientas de mqtt para ahorrar recursos.
```
docker container stop mqtt_clients
```
	
Para eliminar el stack (apagando los contenedores de los servicios):
```
docker-compose down
```

# SERVICIO NODERED
	

Creamos una carpeta para el contexto de Dockerfile
```
sudo mkdir $HOME/node-red
```

Creamos un Dockerfile en esa carpeta
```
sudo nano $HOME/node-red/Dockerfile
```
	
Copiamos el siguiente texto y luego guardamos.
```
FROM nodered/node-red-docker:rpi
```
	
Editamos ***docker-compose.yml*** para añadir el nuevo servicio
```
sudo nano $HOME/docker-compose.yml
```

Pegamos el siguiente texto.
(Nota. Se debe eliminar el texto previo, porque este pegado también incluye todo los previo.)
```
version: '3.5'

services:
    # broker MQTT eclipse-mosquitto.
    mosquitto:
    build:
        context: ./mosquitto  # indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
        - ./mosquitto/environment.env # archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
        - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
        - ./mosquitto/data:/mosquitto/data
        - ./mosquitto/log:/mosquitto/log

    ports:
        - 1883:1883

# node-red
    node-red:
    build:
        context: ./node-red  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: node-red  # Este es el nombre de la imagen que genera el build.

    container_name: node-red  # Nombre del contenedor que creará el servicio.

    restart: always    # Que siempre se reinicie.

    ports:
        - 1880:1880

    volumes:
        - node-red-data:/data

volumes:
    node-red-data:
    name: the-node-red-data
```

El volumen con nombre ***the-node-red-data*** se utiliza para la persistencia de node-red (nodos que instalamos, flujos, etc) sin esto se perdería toda la configuración cuando se elimine a capa reescribible al reiniciar el contenedor o los servicios.

Probamos
```
cd $HOME
```
```
docker-compose up -d  
```
```
docker container ls -a
```

En un navegador conectar a http://192.168.1.200:1880. Debe verse la interfaz de nodered.

Comprobamos el uso de recursos
```
sudo docker stats
```

Podemos ver la salida del log:
```
docker-compose logs
```
	
# SERVICIO NGINX

Creamos un directorio de contexto para ***NGINX***.
```
sudo mkdir $HOME/nginx-reverse-proxy
```

Y creamos y editamos el archivo de configuración de nginx
```
sudo nano $HOME/nginx-reverse-proxy/nginx.conf
```

Pegamos el siguiente texto
```
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    server {
        listen 80;

        location / {
            proxy_ssl_session_reuse  on;
            proxy_pass               http://node-red:1880;  #  Aprovechamos la resolución de nombres de contenedores que proporciona la red de tipo bridge.
            proxy_http_version       1.1;
            proxy_set_header         Upgrade        $http_upgrade;
            proxy_set_header         Connection     "upgrade";
            proxy_redirect           default;
            proxy_read_timeout       90;
        }
    }
}
```

Editamos el Dockerfile de nginx.
```
sudo nano $HOME/nginx-reverse-proxy/Dockerfile
```

Pegamos el siguiente texto.
```
FROM nginx:alpine
```

Guardamos (Ctrl+X, Y, Enter)

Editamos ***docker-compose.yml*** para añadir el servicio de nginx.

```
sudo nano docker-compose.yml
```
	
Pegar el siguiente texto. Sustutir todo el archivo por este.
(Nota: Se han añadido cláusulas ***depends_on*** a lo servicios anteriores)
```
version: '3.5'

services:

    # broker MQTT eclipse-mosquitto.
    mosquitto:
    build:
        context: ./mosquitto  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
        - ./mosquitto/environment.env # Archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
        - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
        - ./mosquitto/data:/mosquitto/data
        - ./mosquitto/log:/mosquitto/log

    ports:
        - 1883:1883

    # node-red
    node-red:
    build:
        context: ./node-red  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: node-red  # Este es el nombre de la imagen que genera el build.

    container_name: node-red  # Nombre del contenedor que creará el servicio.

    restart: always    # Que siempre se reinicie.

    ports:
        - 1880:1880

    volumes:
        - node-red-data:/data  # Ofrecemos persistencia de la configuración de node-red.

    depends_on:
        - mosquitto


    # nginx-reverse-proxy
    nginx-reverse-proxy:
    build:
        context: ./nginx-reverse-proxy  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: nginx-reverse-proxy  # Este es el nombre de la imagen que genera el build.

    container_name: nginx-reverse-proxy  # Nombre del contenedor que creará el servicio.

    restart: always  # Que siempre se reinicie.

    ports:
        - 80:80
        - 443:443

    volumes:
        - ./nginx-reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro

    depends_on:
        - node-red

volumes:
    node-red-data:
    name: the-node-red-data
```
	
Compilamos.
```
docker-compose build
```
	
Levantamos los servicios
```
docker-compose up -d
```
	
Comprobamos que vaya todo bien
```
docker container ls
```	
	
Creamos una red personalizada en Compose para que haya resolución DNS. 

Editar el ***docker-compose.yml***.
```
sudo nano $HOME/docker-compose.yml
```

Pegar el siguiente texto (se ha añadido un objeto network al final y los contenedores hacen referencia a esta red). 
(Nota: Sustituir todo el contenido por este)
```
version: '3.5'

services:

    # broker MQTT eclipse-mosquitto.
    mosquitto:
    build:
        context: ./mosquitto  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
        - ./mosquitto/environment.env # Archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
        - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
        - ./mosquitto/data:/mosquitto/data
        - ./mosquitto/log:/mosquitto/log

    ports:
        - 1883:1883

    networks:
        - container-network


    
    # node-red
    node-red:
    build:
        context: ./node-red  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: node-red  # Este es el nombre de la imagen que genera el build.

    container_name: node-red  # Nombre del contenedor que creará el servicio.

    restart: always    # Que siempre se reinicie.

    ports:
        - 1880:1880

    volumes:
        - node-red-data:/data

    networks:
        - container-network

    depends_on:
        - mosquitto

    # nginx-reverse-proxy
    nginx-reverse-proxy:
    build:
        context: ./nginx-reverse-proxy  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: nginx-reverse-proxy  # Este es el nombre de la imagen que genera el build.

    container_name: nginx-reverse-proxy  # Nombre del contenedor que creará el servicio.

    restart: always  # Que siempre se reinicie.

    ports:
        - 80:80
        - 443:443

    networks:
        - container-network

    volumes:
        - ./nginx-reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro

    depends_on:
        - node-red

networks:
    container-network:
    name: the-container-network
    driver: bridge

volumes:
    node-red-data:
    name: the-node-red-data
```
	
Actualizamos el servicio:
```
docker-compose up -d
```
	
Para comprobar si nginx está corriendo, nos conectamos con un navegador a http://192.168.1.200:80, debe aparecer la página de nodered.
	
	
Ahora hay que cargar los flujos en node-red. Pero antes hay que administrar la paleta (manage-pallete) de nodos y añadir los siguientes
```
node-red-dashboard, node-red-contrib-alexa-home-skill
```

![Añadir nodos](./img/202212222049.png)


Importar los flujos en node-red.
(Nota: Los backups de los flujos están el la carpeta ***Backup Flujos Node-Red*** del repositorio)
(Nota: La importación de los flujos se hace desde la página de edición de nodered: http://192.168.1.200:1880/)

![Importar flujos](./img/202212222051.png)

Los flujos se han importado. Hacer un ***Deploy***. Es posible que la conexión con el servidor mqtt haya que actualizarla. Si la editamos pone ***localhost*** como servidor mqtt. Hay que cambiarla a ***mosquitto*** que es el nombre del contenedor del servidor mqtt y, gracias a la resolución de nombres que ofrece la red de tipo bridge, podemos resolverlo.

Comprobar en la pestaña ***Alexa*** que los nodos conectan. Si no fuera así, para solucionarlo editar uno de ellos, para poder poner las credenciales (Están en la copia de seguridad de credenciales). Los nodos, después de un momento, deben conectar a la función de AWS.

# Let's Encrypt

Vamos a crear un volumen bind para Let's encrypt. A través de este volumen, podemos generar hacer llegar los certificados digitales al contenedor ***nginx-reverse-proxy***.
```
sudo nano $HOME/docker-compose.yml
```

En el contenedor de nginx, añadir el siguiente volumen bind ***/etc/letsencrypt/:/etc/letsencrypt/***.

El compose debe quedar así:
```
version: '3.5'

services:

    # broker MQTT eclipse-mosquitto.
    mosquitto:
    build:
        context: ./mosquitto  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
        - ./mosquitto/environment.env # Archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
        - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
        - ./mosquitto/data:/mosquitto/data
        - ./mosquitto/log:/mosquitto/log

    ports:
        - 1883:1883

    networks:
        - container-network

    # node-red
    node-red:
    build:
        context: ./node-red  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: node-red  # Este es el nombre de la imagen que genera el build.

    container_name: node-red  # Nombre del contenedor que creará el servicio.

    restart: always    # Que siempre se reinicie.

    ports:
        - 1880:1880

    volumes:
        - node-red-data:/data


    networks:
        - container-network

    depends_on:
        - mosquitto


    # nginx-reverse-proxy
    nginx-reverse-proxy:
    build:
        context: ./nginx-reverse-proxy  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: nginx-reverse-proxy  # Este es el nombre de la imagen que genera el build.

    container_name: nginx-reverse-proxy  # Nombre del contenedor que creará el servicio.

    restart: always  # Que siempre se reinicie.

    ports:
        - 80:80
        - 443:443

    networks:
        - container-network

    volumes:
        - ./nginx-reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro
        - /etc/letsencrypt/:/etc/letsencrypt/

    depends_on:
        - node-red

networks:
    container-network:
    name: the-container-network
    driver: bridge

volumes:
    node-red-data:
    name: the-node-red-data
```	
	
Preparamos la raspberry para que pueda pedir (y renovar) certificados a Let's Encrypt. Estos certificados se utilizarán para https en nginx. Instalamos "certbot", el cliente de Let's encrypt.
```
sudo apt-get install certbot
```
	
Vamos a usar el plugin en modo ***standalone***". Al ejecutarlo (certbot) arranca un servidor web para la solicitud del certificado. Esto significa que los puertos 80 y 443 deben estar disponibles, así que debemos apagar el servidor nginx, ya que tiene los dos puertos enlazados.
	
Además, para la verificación, let's encrypt se conectará al cliente (certbot) que está haciendo de nuestro servidor web (nginx). En la fase de descarga inicial del certificado aún no se puede mover el tráfico por ssl, ya que no hay certificado alguno. Por esta razón, certbot se expone en el puerto 80, así que hay que mapear el tráfico Http (80) en el router hacia 192.168.1.200. Cuando tengamos el certificado, se lo instalaremos a nginx, para proteger las conexiones hacia node-red desde Internet, así que también tenemos que crear una regla de redirección de puerto hacia el 443 de la ip 192.168.1.200. En definitiva, dos mapeos para los puertos 80 y 443 hacia la ip interna 192.168.1.200. 
(NOTA IMPORTANTE. No puede haber ningún contenedor que tenga mapeado el puerto 80, así que lo mejor es parar todo el servicio?
```
sudo docker-compose down
```	

Vamos a crear el certificado. Se pueden crear certificados para diferentes URL, para ello repetir el parámetro ***-d*** por cada una de ellas.   
(Nota: Seguir las instrucciones)
```
sudo certbot certonly --standalone -d <sevilla.antsala.xyz>
```
	
La autoridad certificadora de Let's Encrypt entrega certificados de corta vida, solo son válidos por 90 días. Esto hace que sea importante el proceso de renovación automático. Certbot lo hace fácil por medio del comando ***certbot renew***, que comprueba los certificados instalados y renueva aquellos que expirarán en menos de 30 días.

Vamos a usar el mismo plugin para la renovación que usamos para pedir el certificado, el plugin standalone. Para el proceso de renovación, los puerto 80 o 443 deben estar libres.

Certbot proporciona ***hooks*** antes y después del procedimiento de renovación, que usaremos para detener y arrancar el servidor web (nginx) durante la renovación, con la idea de liberar los puertos.

Los ***hooks*** se ejecutan solo cuando el certificado necesita ser renovado, de esta forma no hay downtime innecesario.

El comando docker-compose es el siguiente:
```
	sudo certbot renew --pre-hook "docker-compose -f $HOME/docker-compose.yml down" --post-hook "docker-compose -f $HOME/docker-compose.yml up -d"
```
	
Como se puede ver en la siguiente imagen, si se fuerza la renovación del certificado, pero no estamos en el periodo de validación, entonces no se hace nada (skipped)

![Skipped](./img/202212222107.png)
	
Necesitamos que este procedimiento se realice son frecuencia, así que usamos crontab
```
sudo crontab -e
```

Elegir ***nano***, Escribir estas dos líneas al final y guardar.
```
@weekly sudo certbot renew --pre-hook "docker-compose -f $HOME/docker-compose.yml down" --post-hook "docker-compose -f $HOME/docker-compose.yml up -d"
@daily service nginx reload
```

Hasta el momento los certificados son solicitados y almacenados en raspbian. Ahora necesitamos proporcionárselos a nginx. La primera parte ya está configurada y consistía en crear un volumen bind para let's encrypt en el contenedor nginx. Esta configuración  ya se encuentra en el compose.
```
   volumes:
     - ./nginx-reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro
     - /etc/letsencrypt/:/etc/letsencrypt/
```

Por defecto, un servidor virtual escucha en el puerto 80 y ahora tenemos que hacer que escuche en el 443, esto se hace por directivas ***listen***. Además el certificado debe estar definido y lo configuraremos con las directivas ***ssl_certificate*** y ***ssl_certificate_key***. Editamos el archivo de configuración de nginx.
```
sudo nano nginx-reverse-proxy/nginx.conf
```

Debe quedar de la siguiente forma.
(Nota: Sustituir el anterior y actualizar ***<poner_la_dns_correcta>***
```
worker_processes 1;

events { worker_connections 1024; }

http {

    sendfile on;

    server {
        listen 80;

        listen 443 ssl;
        ssl_certificate /etc/letsencrypt/live/<poner_la_dns_correcta>/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/<poner_la_dns_correcta>/privkey.pem;

        location / {
            proxy_ssl_session_reuse         on;
            proxy_pass                      http://node-red:1880;  #  Aprovechamos la resolución de nombres 
            proxy_http_version              1.1;
            proxy_set_header                Upgrade        $http_upgrade;
            proxy_set_header                Connection     "upgrade";
            proxy_redirect                  default;
            proxy_read_timeout              90;
        }
    }
}
```
	
Arrancamos nuestro stack
```
sudo docker-compose up -d
```

Conectamos con un navegador a https://poner_la_dns_correcta/ui y vemos si funciona.

Hasta aquí todo correcto. Desde Internet montamos un túnel SSL hasta nginx, pero no hay autenticación con node-red y cualquiera podría acceder al servidor. Lo que vamos a hacer es configurar node-red para que exija autenticación.

Esto se hace en el archivo de configuración ***settings.js***. Este archivo se almacena en un volumen con nombre llamado ***the-node-red-data***, para editarlo, primero nos aseguramos que el contenedor no está corriendo:
```
docker-compose down
```

La ruta del archivo de configuración es ***/var/lib/docker/volumes/the-node-red-data/_data/settings.js***. La usaremos en un momento para editar dicho archivo.

Suponemos que ya hemos cambiado el password por defecto de la raspberry. Esto debe hacerse al instalar raspbian, ya que este password es conocido por la comunidad.

Hay tres credenciales que debemos conocer (y su password cambiar) en node-red: ***node-red admin***, permite acceder al editor de node-red. ***node-red http and flow***, que se utiliza para autenticar las requests de HTTP, por ejemplo a la interfaz gráfica /ui. ***node-red static auth***, que se utiliza en la autenticación del contenido estático como las páginas web hospedadas (esta última credencial es opcional de configurar y no la pondremos)

En el archivo de configuración debemos poner los hashes (y no las contraseñas) de estas credenciales, por lo que nos hará falta una herramienta para generarlos (***node-red-admin***)

Instalamos el gestor de paquetes de node ***npm***
```
sudo apt install npm
```

Instalamos la herramienta
```
sudo npm install -g node-red-admin
```

Ahora generamos los hashes
```
sudo node-red-admin hash-pw (Ponemos un password y copiamos al portapapeles el hash generado)
```	
	
Editamos el archivo de configuración ***settings.js***
```
sudo nano /var/lib/docker/volumes/the-node-red-data/_data/settings.js
```
En nano buscar (Ctrl+W) y buscar ***adminAuth***. Quitar todos los comentarios del bloque y sustituir el hash que aparece por el que hemos copiado previamente.

Luego buscar (Ctrl+W) y buscar ***httpNodeAuth***. Quitar los comentarios para habilitar esta credencial, sustituir ***user*** por el usuario que deseemos, por ejemplo ***admin***, y pegar el hash del password que copiamos anteriormente.

Guardamos Ctrl+X, Y, Enter y arrancamos el stack
```
docker-compose up -d
```

Ahora, al conectar con nodered, aparece el diálogo de autenticación.

	
    
## SERVICIO UPDATE_DNS (CON AZURE FUNCTIONS)

Crear el contexto de Dockerfile para mosquitto.
```
sudo mkdir $HOME/updateDNSAzureFunctions
``` 
	
En el directorio ***updateDNSAzureFunctions***, crear un archivo llamado ***updatePublicIP.sh*** y editarlo. Este script será ejecutado cuando se cree la imagen del contenedor.
```
cd $HOME/updateDNSAzureFunctions
```
``` 
sudo nano update_public_ip.sh
```

Pegar el siguiente contenido en el archivo
```
#!/bin/bash

set -e

REQIP="$(curl icanhazip.com)"

#echo "URL=$URL"
#echo "code=$CODE"
#echo "name=$NAME"
#echo "zone=$ZONE"
#echo "La IP publica es:$REQIP"

URI="$URL?code=$CODE&name=$NAME&zone=$ZONE&reqIP=$REQIP"

echo "$URI"

curl -X POST $URI -d ""

exec "$@"
```

Guardarlo (Ctrl+X, Y, Enter)

Ahora lo hacemos ejecutable
```
sudo chmod 755 update_public_ip.sh
```	

Creamos un archivo para almacenar variables de entorno. Este archivo se llamará ***environment.env***. Posteriormente recuperaremos los valores con ***${clave}*** en el archivo compose. Estas variables son tomadas de la URL de llamada a la Azure Function.
```
sudo nano environment.env
```

Y pegamos el siguiente texto
```
URL=https://antsalaupdatedns.azurewebsites.net/api/doUpdate
CODE=x33XYR3aS7maofEPBgmkyKa3K12622l4jAZ37Mihte9u0tJIQTMgOQ==
NAME=sevilla
ZONE=antsala.xyz
```

Voy a crear un script ***loop.sh*** para que lance una actualización al iniciar el contenedor, asegure iniciar el servicio cron y luego entre en bucle infinito para que el contenedor no se pare.
```
sudo nano loop.sh
```	
Pegar este texto. Ojo, cuando cron llama al script su contexto es diferente, por lo tanto no ve las variables de entorno que se le pasan al contenedor. Usamos un truco consistente en exportar las variables a un script (***cron_env.sh***)que luego se carga al ejecutar cron. Ver Access environment variables from crontab into a docker container – Yannick Pereira-Reis (ypereirareis.github.io)
```
#!/bin/bash

# Hago una llamada inicial a la actualización de la IP. Las posteriores actualizaciones  será llamadas por cron
/update_public_ip.sh

# Paso las variables de entorno al contexto de cron mediante un truco.
# creo un  script con la exportación de las variables. Este script es ejecutado
# por cron cada vez que lanza el script principal.
printenv | sed 's/^\(.*\)$/export \1/g' > /cron_env.sh

# Inicio el servicio cron
service cron start

echo

# Ahora entro en bucle infinito para que no se pare el contenedor.
while :
do
        echo "En bucle infinito para que no se pare el contenedor"
        sleep 300
done
```	

Hacerlo ejecutable
```	
sudo chmod 755 loop.sh
```	
	
Ahora creo la configuración de cron para que se llame al script cada hora.
```	
sudo nano update-cron
```

Pegar este contenido: Se llama al script cada hora. Notar como se llama a ***cron_env.sh*** para hacer accesible las variables de entorno del contenedor al contexto de cron.
```
0 * * * * . /cron_env.sh; /update_public_ip.sh >> /cron.log 2>&1
# An empty line is required at the end of this file for a valid cron file.
```

Creamos el Dockerfile para crear la imagen del updater
```
sudo nano Dockerfile
```

Y pegamos el siguiente texto. ***update-cron*** tiene la configuración de cron para llamar al script ***update-public-ip.sh*** cada hora. la línea RUN lo agrega a crontab. ENTRYPOINT mete al contenedor en un bucle infinito para que no se pare.
```
FROM ubuntu:18.04
RUN apt-get update; apt-get install -y curl
RUN apt-get -y install cron
COPY update-cron /
COPY update_public_ip.sh /
COPY loop.sh /
RUN /usr/bin/crontab /update-cron
CMD ["/bin/bash", "-c", "/loop.sh"]
```
	
Modificamos Compose para incluir el nuevo servicio ( y retirar el antiguo servicio DYNDNS)
```	
sudo nano docker-compose.yml
```	
(Nota: He comentado el servicio DYNDNS, que ya no lo uso)
```
# ddclient (Cliente de DynDns)
    #ddclient:
    #  image: linuxserver/ddclient
    #
    #  container_name: ddclient
    #
    #  environment:
    #    - PUID=1000
    #    - PGID=1000
    #    - TZ=Europe/Madrid
    #
    #  restart: always   # Que siempre se reinicie.
    #
    #  volumes:
    #    - ./ddclient:/config:ro   # Volumen bind para el archivo de configuración.
    #
    #  networks:
    #    - container-network
```

El nuevo servicio updater debe quedar así.
```
# updater_public_ip
updater_public_ip:
build:
    context: ./updateDNSAzureFunctions

env_file:
    - ./updateDNSAzureFunctions/environment.env # archivo con las variables de entorno. Editarlo para configurar.

image: antsala/updater_public_ip

container_name: updater

restart:  always

networks:
    - container-network
```

Para evitar confusiones. La versión final del archivo compose es esta:
```
version: '3.5'
services:
  # broker MQTT eclipse-mosquitto.
  mosquitto:
    build:
      context: ./mosquitto  # indicamos donde está el contexto del Dockerfile para generar la imagen.

    env_file:
      - ./mosquitto/environment.env # archivo con las variables de entorno usuario/password. Editarlo para configurar.

    image: eclipse-mosquitto  # Este es el nombre de la imagen que genera el build.

    container_name: eclipse-mosquitto # Nombre del contenedor que creará el servicio.

    restart: always   # Que siempre se reinicie.

    volumes:
      - ./mosquitto/config/mosquitto.conf:/mosquitto/config/mosquito.conf:ro   # Volumen bind para el archivo de configuración.
      - ./mosquitto/data:/mosquitto/data
      - ./mosquitto/log:/mosquitto/log

    ports:
      - 1883:1883

    networks:
      - container-network

  # node-red
  node-red:
    build:
      context: ./node-red  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: node-red # Este es el nombre de la imagen que genera el build.

    container_name: node-red  # Nombre del contenedor que creará el servicio.

    restart: always    # Que siempre se reinicie.

    ports:
      - 1880:1880

    volumes:
      - node-red-data:/data

    networks:
      - container-network

    depends_on:
      - mosquitto


  # nginx-reverse-proxy
  nginx-reverse-proxy:
    build:
      context: ./nginx-reverse-proxy  # Indicamos donde está el contexto del Dockerfile para generar la imagen.

    image: nginx-reverse-proxy  # Este es el nombre de la imagen que genera el build.

    container_name: nginx-reverse-proxy  # Nombre del contenedor que creará el servicio.

    restart: always  # Que siempre se reinicie.

    ports:
      - 80:80
      - 443:443

    networks:
      - container-network

    volumes:
      - ./nginx-reverse-proxy/nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt/:/etc/letsencrypt/

    depends_on:
      - node-red

  # ddclient (Cliente de DynDns)
  #ddclient:
  #  image: linuxserver/ddclient
  #
  #  container_name: ddclient
  #
  #  environment:
  #    - PUID=1000
  #    - PGID=1000
  #    - TZ=Europe/Madrid
  #
  #  restart: always   # Que siempre se reinicie.
  #
  #  volumes:
  #    - ./ddclient:/config:ro   # Volumen bind para el archivo de configuración.
  #
  #  networks:
  #    - container-network
  

  # updater_public_ip
  updater_public_ip:
    build:
      context: ./updateDNSAzureFunctions

    env_file:
      - ./updateDNSAzureFunctions/environment.env # archivo con las variables de entorno. Editarlo para configurar.

    image: antsala/updater_public_ip 

    container_name: updater

    restart:  always

    networks:
      - container-network


networks:
  container-network:
    name: the-container-network
    driver: bridge

volumes:
    node-red-data:
      name: the-node-red-data
```

Iniciamos todos los servicios convenientemente.
```	
cd $HOME
```

Paramos todos los servicios.
```
sudo docker-compose stop  
```

Se ejecuta sección "build" de "docker-compose.yml", que generará las imágenes.
```
sudo docker-compose build 
```

Crea el stack o pila de servicios
```
sudo docker-compose up -d
```

Muestra los contenedores levantados.
```
sudo docker container ls   
```