# Raspberry IoT con Docker.

Despliegue de IoT.


## Preparar la Raspberry.

Pasos a realizar.
* Descargar https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2019-04-09/ (stretch última versión) 
* Formateamos la SD. Ver: Formatear con FAT32 y Windows una tarjeta > 32GB: https
* Quemamos la imagen descargada con "balenaEtcher-portable": https://www.balena.io/etcher/

Configuración Headless. Creamos un archivo llamado "ssh" en la SD. Esto se hace así porque por razones de reguridad ***ssh*** ya no está habilitado por defecto. Para habilitarlo creamos un archivo vacío llamado ***ssh*** (sin extensión) en la raíz del disco de arranque de la SD.

Ponemos la SD en la Raspberry y la iniciamos. Con el programa ***Advanced-IP-Scan*** localizaremos la IP de la Raspberry en la red y nos conectamos por ssh a dicha IP. El usuario es ***pi*** y el password ***raspberry***

Escribimos el siguiente comando para poder cambiar el password y configurar la WiFi.
```
sudo raspi-config
```

La IP la configuramos editando el siguiente archivo.
```
sudo nano /etc/dhcpcd.conf
```

Debe quedar así:

![IP](./img/202212221940.png)

Ahora habilitamos SSH por medio de ***raspi-config***
```
sudo raspi-config
```

Y realizamos lo siguiente.

![Habilitar SSH](./img/202212221948.png)


