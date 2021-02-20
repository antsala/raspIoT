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
