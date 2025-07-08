---- EJERCICIO 1

-- 1. Conectar como administrador
CONNECT sys AS sysdba;

-- 2. Verificar el estado actual
SELECT log_mode FROM v$database; -- Si el resultado es 'NOARCHIVELOG', procede.

-- 3. Cambiar al modo ARCHIVELOG (requiere reinicio)
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

-- 4. Verificar nuevamente
SELECT log_mode FROM v$database; -- Ahora debería mostrar 'ARCHIVELOG'


docker exec -it oracle_db_course /bin/bash
-- Conectar a la base de datos de destino (target)
-- Este comando se ejecuta desde la línea de comandos: 

rman target /

-- Configurar la política de retención

CONFIGURE RETENTION POLICY TO RECOVERY WINDOW OF 7 DAYS;

-- Configurar el formato del respaldo para guardarlo en una ubicación específica
CONFIGURE CHANNEL DEVICE TYPE DISK FORMAT '/u01/backup/full_%U';


--Ejecutar el respaldo completo
RUN {
    -- Respalda toda la base de datos y todos los archivelogs generados
    BACKUP DATABASE PLUS ARCHIVELOG;

    -- Elimina los respaldos que ya no son necesarios según la política de retención
    DELETE OBSOLETE;
}

-- Listar los respaldos para confirmar la creación
LIST BACKUP;
