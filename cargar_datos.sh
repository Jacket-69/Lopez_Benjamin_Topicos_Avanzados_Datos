# cargar_datos.sh
    # Script para cargar datos en las tablas de Oracle usando SQL*Loader.

    # Configuración de la conexión a la base de datos
    DB_USER="curso_topicos"
    DB_PASS="curso2025"
    DB_CONNECTION_TARGET="//localhost:1521/XEPDB1"

    # Directorios relativos al directorio raíz del proyecto donde se ejecuta este script
    DATA_DIR_CSV="./datos_csv_generados"
    CTL_DIR="./archivos_loader"
    LOG_DIR="./archivos_loader/logs" # Directorio para logs y bad files
    BAD_DIR="./archivos_loader/bad_files" # Directorio para bad files

    echo "---------------------------------------------------------------------"
    echo "Iniciando carga de datos con SQL*Loader..."
    echo "Usuario: ${DB_USER}"
    echo "Directorio de CTLs: ${CTL_DIR}"
    echo "Directorio de CSVs (referenciado en CTLs): ${DATA_DIR_CSV}"
    echo "Directorio de Logs: ${LOG_DIR}"
    echo "Directorio de Bad Files: ${BAD_DIR}"
    echo "---------------------------------------------------------------------"

    # Crear directorios para logs y bad files si no existen
    mkdir -p "${LOG_DIR}"
    mkdir -p "${BAD_DIR}"

    # Función para ejecutar sqlldr y verificar errores
    execute_sqlldr() {
        local ctl_base_name=$(basename "$1" .ctl) # ej. clientes
        local ctl_file_path="${CTL_DIR}/${ctl_base_name}.ctl"
        local log_file_path="${LOG_DIR}/${ctl_base_name}.log"
        local bad_file_path="${BAD_DIR}/${ctl_base_name}.bad"
        # El archivo de datos es referenciado por la cláusula INFILE dentro del .ctl

        echo ""
        echo "Cargando datos con ${ctl_file_path}..."
        echo "  Archivo de Log: ${log_file_path}"
        echo "  Archivo Bad (si hay errores): ${bad_file_path}"

        sqlldr "${DB_USER}/${DB_PASS}@${DB_CONNECTION_TARGET}" \
               control="${ctl_file_path}" \
               log="${log_file_path}" \
               bad="${bad_file_path}" \
               rows=50000 \
               bindsize=10485760 \
               readsize=10485760 \
               parallel=false # Usar true si la BD y la carga lo permiten y es una tabla muy grande, pero puede complicar logs.

        local exit_code=$?
        if [ ${exit_code} -eq 0 ]; then
            echo "Carga con ${ctl_base_name}.ctl completada exitosamente."
        elif [ ${exit_code} -eq 1 ]; then
            # Código 1 en sqlldr (EX_FAIL) usualmente significa errores fatales (ej. error de sintaxis en CTL)
            echo "ERROR FATAL: Falló la carga con ${ctl_base_name}.ctl. Código de salida: ${exit_code}"
            echo "Revisar ${log_file_path}."
            exit 1 # Detener el script si una carga falla críticamente
        elif [ ${exit_code} -eq 2 ]; then
            # Código 2 en sqlldr (EX_WARN) significa que se completó pero con algunas filas rechazadas (en .bad)
            echo "ADVERTENCIA: Carga con ${ctl_base_name}.ctl completada con errores (algunas filas rechazadas)."
            echo "Revisar ${log_file_path} y ${bad_file_path}."
        elif [ ${exit_code} -eq 4 ]; then
            # Código 4 en sqlldr (EX_SUCC) significa éxito pero con advertencias (ej. conversiones de datos)
             echo "ÉXITO CON ADVERTENCIAS: Carga con ${ctl_base_name}.ctl completada con advertencias."
            echo "Revisar ${log_file_path}."
        else
            echo "ERROR INESPERADO: Falló la carga con ${ctl_base_name}.ctl. Código de salida: ${exit_code}"
            echo "Revisar ${log_file_path} y ${bad_file_path}."
            exit 1 # Detener el script
        fi
        echo "---------------------------------------------------------------------"
    }

    # Orden de carga:
    execute_sqlldr "clientes.ctl"
    execute_sqlldr "productos.ctl"
    execute_sqlldr "inventario.ctl"
    execute_sqlldr "pedidos.ctl"
    execute_sqlldr "detalles_pedidos.ctl"

    echo ""
    echo "Proceso de carga de datos finalizado."
    echo "Verifica los archivos .log y .bad en los directorios ${LOG_DIR} y ${BAD_DIR} en caso de errores/advertencias."
    echo "Recuerda que los triggers del DWH deberían haberse disparado durante estas cargas."
    