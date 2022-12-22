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
	