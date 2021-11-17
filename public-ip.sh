
#!/bin/bash
###################################################
# TODO: CHECK if the string we get it's a valid IP
###################################################
EXT_IP_FILE="/etc/ip_publica"
LOG_FILE="/var/log/ip_publica.log"
timestamp=$( date +%T )
curDate=$( date +"%d-%m-%y" )
#--------------
# LOG LEVEL
# 0 - Nothing
# 1 - Only Errors
# 2 - Verbose
# 3 - ALL
#---------------
LOG_LEVEL=1


if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "--- Comprobando IP Publica ---" >> $LOG_FILE; fi

#Primero comprobamos que haya internet
if ping -c1 google.com &>/dev/null; then

        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "*** HAY INTERNET" >> $LOG_FILE; fi

        #Conseguir la IP pública
        CURRENT_IP=`wget -q -O - ifconfig.me/ip`

        #Si falla al conseguir la IP volvemos a buscar la ip en ipinfo.io
        # Parece que si no lo ponemos entre comillas no comprueba bien
        if [ "$CURRENT_IP" = "" ]; then
                if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** ERROR IP ifconfig <<"$CURRENT_IP">>" >> $LOG_FILE; fi
                CURRENT_IP=`curl ipinfo.io/ip`
                if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp " IP ipinfo.io: <<"$CURRENT_IP">>" >> $LOG_FILE; fi
                if [ $LOG_LEVEL -ge 2 ]; then `telegram-send -g   $curDate" "$timestamp" ERROR ipinfo.io IP:<"$CURRENT_IP">" &`; fi
        fi

        # Si la ip obtenida no esta vacia, tenemos IP
        if [ "$CURRENT_IP" != "" ]; then

                #Si existe el archivo se saca la IP que había
                if [ -f $EXT_IP_FILE ]; then
                        KNOWN_IP=$(cat $EXT_IP_FILE)
                else
                        #Si no existe el archivo se crea y se guarda la IP pública actual
                        KNOWN_IP= touch $EXT_IP_FILE
                        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "*** ARCHIVO DE CONFIGURACION NO ENCONTRADO " >> $LOG_FILE; fi
                fi

                if [ $LOG_LEVEL -ge 3 ]; then echo $curDate $timestamp "*** KNOWN IP: <<"$KNOWN_IP">>" >> $LOG_FILE; fi

                #Comprueba si la IP actual ha cambiado de la IP que se había guardado
                if [ "$CURRENT_IP" != "$KNOWN_IP" ]; then
                        echo $CURRENT_IP > $EXT_IP_FILE
                        #Si es distinta la IP se envía un TG con la IP actual
                        telegram-send -g  "NUEVA IP: "$CURRENT_IP &
                        #Se guardan las IPs en un archivo de log
                        echo $curDate $timestamp "* NUEVA IP: " $CURRENT_IP >> $LOG_FILE
                else
                        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "* Misma IP: " $CURRENT_IP >> $LOG_FILE; fi
                        #telegram-send -g  "Misma IP: "$CURRENT_IP &
                fi
        else
                #se escribe en el registro, error
                if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** ERROR IP: <<"$CURRENT_IP">>" >> $LOG_FILE; fi
        fi

else
        #Si no hay internet, lo escribimos en el registro y salimos
        if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** NO HAY INTERNET. Salimos" $CURRENT_IP >> $LOG_FILE; fi
fi
