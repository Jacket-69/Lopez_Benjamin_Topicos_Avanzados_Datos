-- inventario.ctl
-- Archivo de control para cargar datos en la tabla Inventario

OPTIONS (SKIP=1, ROWS=1000)
LOAD DATA
INFILE 'datos_csv_generados/inventario.csv'
BADFILE 'inventario.bad'
DISCARDFILE 'inventario.dsc'
APPEND
INTO TABLE curso_topicos.Inventario
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    ProductoID         INTEGER EXTERNAL,
    CantidadProductos  INTEGER EXTERNAL
)
```sql