-- clientes.ctl
-- Archivo de control para cargar datos en la tabla Clientes

OPTIONS (SKIP=1, ROWS=1000) -- Omitir la cabecera, procesar en lotes de 1000 filas
LOAD DATA
INFILE 'datos_csv_generados/clientes.csv' -- Nombre del archivo CSV de entrada
BADFILE 'clientes.bad' -- Archivo para filas erróneas
DISCARDFILE 'clientes.dsc' -- Archivo para filas descartadas por cláusulas WHEN
APPEND -- Añadir datos a la tabla (si ya tiene, si no, igual inserta)
INTO TABLE curso_topicos.Clientes -- Usuario.Tabla destino
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"' -- Campos delimitados por coma, opcionalmente encerrados en comillas
TRAILING NULLCOLS -- Permitir columnas nulas al final de la línea
(
    ClienteID         INTEGER EXTERNAL,
    Nombre            CHAR,
    Ciudad            CHAR,
    FechaNacimiento   DATE "YYYY-MM-DD"
)
```sql