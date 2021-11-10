#!/bin/bash
CFG_FILE="/etc/check_internet"
LOG_FILE="/var/log/check_internet.log"
timestamp=$( date +%T )
curDate=$( date +"%d-%m-%y" )

#Comprobamos que hay internet
if ping -c1 google.com &>/dev/null; then
    STATUS='OK'
else
    STATUS='KO'
    #Si no hay internet, se escribe en el registro
    echo $curDate $timestamp "*** ESTADO INTERNET: "$STATUS"!!!" >> $LOG_FILE    
fi

#Para eliminar una vez comprobado
echo $curDate $timestamp "*** ESTADO INTERNET: "$STATUS  >> $LOG_FILE

#Si existe el archivo de configuacion
if [ -f $CFG_FILE ]; then
    # Get PREVIUS_STATUS from file
    PREV_STATUS=$(cat $CFG_FILE)    
else    
    #Si no existe el archivo se pone el estado previo igual al estado actual
    PREV_STATUS=$STATUS
fi

#se guarda el estado actual en el fichero
echo $STATUS > $CFG_FILE

if  [ "$STATUS" = "OK" ] && [ "$PREV_STATUS" = "KO" ]; then
    #Si hay internet y antes no habia
    telegram-send -g  "INTERNET RECUPERADO: "$STATUS &
    #Se escribe en el registro
    echo $curDate $timestamp "*** INTERNET RECUPERADO: "$STATUS  >> $LOG_FILE
fi

