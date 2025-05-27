-- detalles_pedidos.ctl
-- Archivo de control para cargar datos en la tabla DetallesPedidos

OPTIONS (SKIP=1, ROWS=1000)
LOAD DATA
INFILE 'datos_csv_generados/detalles_pedidos.csv'
BADFILE 'detalles_pedidos.bad'
DISCARDFILE 'detalles_pedidos.dsc'
APPEND
INTO TABLE curso_topicos.DetallesPedidos
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    DetalleID         INTEGER EXTERNAL,
    PedidoID          INTEGER EXTERNAL,
    ProductoID        INTEGER EXTERNAL,
    Cantidad          INTEGER EXTERNAL,
    PrecioUnitario    DECIMAL EXTERNAL
)