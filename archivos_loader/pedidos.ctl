-- pedidos.ctl
-- Archivo de control para cargar datos en la tabla Pedidos

OPTIONS (SKIP=1, ROWS=1000)
LOAD DATA
INFILE 'datos_csv_generados/pedidos.csv'
BADFILE 'pedidos.bad'
DISCARDFILE 'pedidos.dsc'
APPEND
INTO TABLE curso_topicos.Pedidos
FIELDS TERMINATED BY "," OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    PedidoID          INTEGER EXTERNAL,
    ClienteID         INTEGER EXTERNAL,
    FechaPedido       DATE "YYYY-MM-DD HH24:MI:SS", -- Formato de fecha y hora
    Total             DECIMAL EXTERNAL
)
```sql