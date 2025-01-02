#!/bin/bash

# Nombre del archivo JAR
JAR_FILE="transfer/transfer-00-prerequisites/connector/build/libs/connector.jar"

# Configuración común
COMMON_PARAMS="-Dedc.keystore=transfer/transfer-00-prerequisites/resources/certs/cert.pfx -Dedc.keystore.password=123456"

# Rutas de los archivos de log
PROVIDER_LOG="/tmp/provider.log"
CONSUMER_LOG="/tmp/consumer.log"

# Función para construir el comando Java
build_java_cmd() {
    local user_type=$1
    local config_file
    local log_file
    if [ "$user_type" == "provider" ]; then
        config_file="provider-configuration.properties"
        log_file=$PROVIDER_LOG
    elif [ "$user_type" == "consumer" ]; then
        config_file="consumer-configuration.properties"
        log_file=$CONSUMER_LOG
    else
        echo "Tipo de usuario no válido. Use 'provider' o 'consumer'."
        exit 1
    fi
    
    echo "java $COMMON_PARAMS -Dedc.fs.config=transfer/transfer-00-prerequisites/resources/configuration/$config_file -jar $JAR_FILE >> $log_file 2>&1"
}

# Archivos para guardar los PIDs de los procesos
PROVIDER_PID_FILE="/tmp/java_app_provider.pid"
CONSUMER_PID_FILE="/tmp/java_app_consumer.pid"

start_single() {
    local user_type=$1
    local pid_file
    [ "$user_type" == "provider" ] && pid_file=$PROVIDER_PID_FILE || pid_file=$CONSUMER_PID_FILE

    if [ -f "$pid_file" ]; then
        echo "La aplicación $user_type ya está en ejecución."
    else
        echo "Iniciando la aplicación para $user_type..."
        JAVA_CMD=$(build_java_cmd $user_type)
        nohup bash -c "$JAVA_CMD" > /dev/null 2>&1 & 
        BASH_PID=$!
        JAVA_PID=$(pgrep -P $BASH_PID)
        echo "$BASH_PID $JAVA_PID" > "$pid_file"
        echo "Aplicación $user_type iniciada con PIDs $BASH_PID (bash) y $JAVA_PID (java)"
    fi
}

start() {
    if [ "$1" == "both" ]; then
        start_single "provider"
        start_single "consumer"
    else
        start_single $1
    fi
}

stop_single() {
    local user_type=$1
    local pid_file
    [ "$user_type" == "provider" ] && pid_file=$PROVIDER_PID_FILE || pid_file=$CONSUMER_PID_FILE

    if [ -f "$pid_file" ]; then
        read BASH_PID JAVA_PID < "$pid_file"
        echo "Intentando detener la aplicación $user_type con PIDs $BASH_PID (bash) y $JAVA_PID (java)..."
        
        # Intenta terminar los procesos con SIGTERM
        kill -15 $JAVA_PID $BASH_PID 2>/dev/null
        
        # Espera hasta 10 segundos para que los procesos terminen
        for i in {1..10}; do
            if ! ps -p $JAVA_PID > /dev/null 2>&1 && ! ps -p $BASH_PID > /dev/null 2>&1; then
                echo "Aplicación $user_type detenida."
                rm "$pid_file"
                return 0
            fi
            sleep 1
        done
        
        # Si los procesos aún están en ejecución, usa SIGKILL
        echo "Los procesos no respondieron a SIGTERM. Intentando con SIGKILL..."
        kill -9 $JAVA_PID $BASH_PID 2>/dev/null
        
        # Espera otros 5 segundos
        for i in {1..5}; do
            if ! ps -p $JAVA_PID > /dev/null 2>&1 && ! ps -p $BASH_PID > /dev/null 2>&1; then
                echo "Aplicación $user_type forzada a detenerse."
                rm "$pid_file"
                return 0
            fi
            sleep 1
        done
        
        echo "No se pudo detener la aplicación $user_type. Los procesos con PIDs $BASH_PID y $JAVA_PID aún están en ejecución."
        return 1
    else
        echo "La aplicación $user_type no está en ejecución."
        return 0
    fi
}

stop() {
    if [ "$1" == "both" ]; then
        stop_single "provider"
        stop_single "consumer"
    else
        stop_single $1
    fi
}

status_single() {
    local user_type=$1
    local pid_file
    local log_file
    [ "$user_type" == "provider" ] && pid_file=$PROVIDER_PID_FILE || pid_file=$CONSUMER_PID_FILE
    [ "$user_type" == "provider" ] && log_file=$PROVIDER_LOG || log_file=$CONSUMER_LOG

    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if ps -p $PID > /dev/null; then
            echo "La aplicación $user_type está en ejecución con PID $PID."
            echo "Logs guardados en $log_file"
        else
            echo "El archivo PID existe, pero el proceso $user_type no está en ejecución."
            rm "$pid_file"
        fi
    else
        echo "La aplicación $user_type no está en ejecución."
    fi
}

status() {
    if [ "$1" == "both" ]; then
        status_single "provider"
        status_single "consumer"
    else
        status_single $1
    fi
}

# Verificar si se proporcionó el tipo de usuario
if [ "$2" != "provider" ] && [ "$2" != "consumer" ] && [ "$2" != "both" ]; then
    echo "Uso: $0 {start|stop|restart|status} {provider|consumer|both}"
    exit 1
fi

case "$1" in
    start)
        start $2
        ;;
    stop)
        stop $2
        ;;
    restart)
        stop $2
        start $2
        ;;
    status)
        status $2
        ;;
    *)
        echo "Uso: $0 {start|stop|restart|status} {provider|consumer|both}"
        exit 1
        ;;
esac

exit 0
