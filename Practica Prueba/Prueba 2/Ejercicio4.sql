---EJERCICIO 2
CREATE TABLE AuditoriaPedidos (
    AuditoriaID      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PedidoID         NUMBER NOT NULL,
    ClienteID        NUMBER,
    Total            NUMBER,
    FechaEliminacion DATE NOT NULL,
    UsuarioBD        VARCHAR2(100)
);
/


CREATE OR REPLACE TRIGGER auditar_eliminacion_pedido
AFTER DELETE ON Pedidos
FOR EACH ROW
BEGIN
    INSERT INTO AuditoriaPedidos (
        PedidoID,
        ClienteID,
        Total,
        FechaEliminacion,
        UsuarioBD
    )
    VALUES (
        :OLD.PedidoID,
        :OLD.ClienteID,
        :OLD.Total,
        SYSDATE,
        USER
    );
END auditar_eliminacion_pedido;
/

---pruebasss

--ver tabla de auditoria
SELECT * FROM AuditoriaPedidos WHERE PedidoID = 1;

--borrar un pedido 

BEGIN
    DELETE FROM DetallesPedidos WHERE PedidoID = 1;
    DELETE FROM Pedidos WHERE PedidoID = 1;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Intentando eliminar el Pedido 1. El trigger debería haberse disparado.');
END;
/

--verificar en tabla

SELECT 
    AuditoriaID, 
    PedidoID, 
    ClienteID, 
    Total, 
    TO_CHAR(FechaEliminacion, 'YYYY-MM-DD HH24:MI:SS') AS FechaEliminacion, 
    UsuarioBD 
FROM 
    AuditoriaPedidos 
WHERE 
    PedidoID = 1;