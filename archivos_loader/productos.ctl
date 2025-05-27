-- productos.ctl
-- Archivo de control para cargar datos en la tabla Productos

OPTIONS (SKIP=1, ROWS=1000)
LOAD DATA
INFILE 'datos_csv_generados/productos.csv'
BADFILE 'productos.bad'
DISCARDFILE 'productos.dsc'
APPEND
INTO TABLE curso_topicos.Productos
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    ProductoID        INTEGER EXTERNAL,
    Nombre            CHAR,
    Precio            DECIMAL EXTERNAL -- Usar DECIMAL EXTERNAL para números con decimales
)