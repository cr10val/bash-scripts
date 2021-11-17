
#!/bin/bash
###################################################
# This bash script get the public ip and send and 
# telegram message when it detect a change.
# 
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

#Check if are internet conection
if ping -c1 google.com &>/dev/null; then

        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "*** HAY INTERNET" >> $LOG_FILE; fi

        #Get Public IP
        CURRENT_IP=`wget -q -O - ifconfig.me/ip`

        #If there is an error we try to get it again from ipinfo.io                
        if [ "$CURRENT_IP" = "" ]; then
                if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** ERROR IP ifconfig <<"$CURRENT_IP">>" >> $LOG_FILE; fi
                CURRENT_IP=`curl ipinfo.io/ip`
                if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp " IP ipinfo.io: <<"$CURRENT_IP">>" >> $LOG_FILE; fi
                if [ $LOG_LEVEL -ge 2 ]; then `telegram-send -g   $curDate" "$timestamp" ERROR ipinfo.io IP:<"$CURRENT_IP">" &`; fi
        fi

        # If there is not an empty ip
        if [ "$CURRENT_IP" != "" ]; then

                #We check for the ip file and if it's exist we get the known ip
                if [ -f $EXT_IP_FILE ]; then
                        KNOWN_IP=$(cat $EXT_IP_FILE)
                else
                        #If the file does not exist we create it and save the actual ip
                        KNOWN_IP= touch $EXT_IP_FILE
                        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "*** ARCHIVO DE CONFIGURACION NO ENCONTRADO " >> $LOG_FILE; fi
                fi

                if [ $LOG_LEVEL -ge 3 ]; then echo $curDate $timestamp "*** KNOWN IP: <<"$KNOWN_IP">>" >> $LOG_FILE; fi

                #Check if the actual ip if different from then known ip
                if [ "$CURRENT_IP" != "$KNOWN_IP" ]; then
                        echo $CURRENT_IP > $EXT_IP_FILE
                       #If it detect a change we send a tg message
                        telegram-send -g  "NUEVA IP: "$CURRENT_IP &
                        #Log the new ip
                        echo $curDate $timestamp "* NUEVA IP: " $CURRENT_IP >> $LOG_FILE
                else
                        if [ $LOG_LEVEL -ge 2 ]; then echo $curDate $timestamp "* Misma IP: " $CURRENT_IP >> $LOG_FILE; fi
                        #telegram-send -g  "Misma IP: "$CURRENT_IP &
                fi
        else
                #If there isn't ip we log the error
                if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** ERROR IP: <<"$CURRENT_IP">>" >> $LOG_FILE; fi
        fi

else
        #If there isn't internet conection and exit
        if [ $LOG_LEVEL -ge 1 ]; then echo $curDate $timestamp "*** NO HAY INTERNET. Salimos" $CURRENT_IP >> $LOG_FILE; fi
fi
