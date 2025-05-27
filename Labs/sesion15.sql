-- ejercicio 1:

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