------------------------ EJERCICIO 1

-- 1. crear índice compuesto en DetallesPedidos para PedidoID y ProductoID

CREATE INDEX idx_detallepedidos_ped_prod ON DetallesPedidos (PedidoID, ProductoID);

SET SERVEROUTPUT ON;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Índice idx_detallepedidos_ped_prod creado en DetallesPedidos(PedidoID, ProductoID).');
END;
/

-- 2. escribir una consulta que usaria el índice

SELECT * FROM DetallesPedidos
WHERE PedidoID = 1 AND ProductoID = 62;

-- 3. 'explain plan' la consulta

EXPLAIN PLAN FOR SELECT DetalleID, Cantidad FROM DetallesPedidos
WHERE PedidoID = 1 AND ProductoID = 62;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);



------------------------ EJERCICIO 2

-- 1. crear tabla Ventas particionada por HASH en ClienteID

CREATE TABLE Ventas (
    VentaID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PedidoID_NK NUMBER, -- clave natural del pedido original
    ClienteID NUMBER NOT NULL,
    FechaVenta DATE,
    TotalVenta NUMBER
)
PARTITION BY HASH (ClienteID) -- particionar por HASH usando la columna ClienteID
PARTITIONS 4;                 -- se especifica el número de particiones

-- 2. se insertan los datos en la tabla Ventas desde la tabla Pedidos

INSERT INTO Ventas (PedidoID_NK, ClienteID, FechaVenta, TotalVenta)
SELECT PedidoID, ClienteID, FechaPedido, Total
FROM Pedidos;

COMMIT;

-- 3. consulta que muestre el total de ventas por cliente.
-- se agrupa por ClienteID

SELECT ClienteID, SUM(TotalVenta) AS Total_Ventas_Por_Cliente
FROM Ventas
GROUP BY ClienteID
ORDER BY ClienteID;

-- 4. EXPLAIN PLAN FOR

EXPLAIN PLAN FOR
SELECT ClienteID, SUM(TotalVenta) AS Total_Ventas_Por_Cliente
FROM Ventas
GROUP BY ClienteID
ORDER BY ClienteID;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);