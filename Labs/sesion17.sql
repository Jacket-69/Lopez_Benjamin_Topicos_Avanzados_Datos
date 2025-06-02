--------EJERCICIO 1
CONNECT SYS AS SYSDBA;
--pass: oracle

ALTER SESSION SET CONTAINER = XEPDB1;

CREATE USER user_analista IDENTIFIED BY analista123;
GRANT CONNECT TO user_analista;

CREATE ROLE rol_analista;

GRANT SELECT ON curso_topicos.Clientes TO rol_analista;
GRANT SELECT ON curso_topicos.Pedidos TO rol_analista;
GRANT SELECT ON curso_topicos.Productos TO rol_analista;
GRANT SELECT ON curso_topicos.DetallesPedidos TO rol_analista;
GRANT SELECT ON curso_topicos.Inventario TO rol_analista;
GRANT SELECT ON curso_topicos.Dim_Cliente TO rol_analista;
GRANT SELECT ON curso_topicos.Dim_Producto TO rol_analista;
GRANT SELECT ON curso_topicos.Dim_Tiempo TO rol_analista;
GRANT SELECT ON curso_topicos.Hecho_Ventas TO rol_analista;

GRANT INSERT ON curso_topicos.Pedidos TO rol_analista;

GRANT rol_analista TO user_analista;

SELECT * FROM CURSO_TOPICOS.Clientes FETCH FIRST 5 ROWS ONLY;
SELECT * FROM CURSO_TOPICOS.Pedidos FETCH FIRST 5 ROWS ONLY;
SELECT * FROM CURSO_TOPICOS.Productos FETCH FIRST 5 ROWS ONLY;
SELECT * FROM CURSO_TOPICOS.DetallesPedidos FETCH FIRST 5 ROWS ONLY;



CONNECT user_analista/analista123@XEPDB1

SELECT COUNT(*) FROM curso_topicos.Clientes;
SELECT COUNT(*) FROM curso_topicos.Pedidos;
SELECT COUNT(*) FROM curso_topicos.Productos;
SELECT COUNT(*) FROM curso_topicos.DetallesPedidos;
SELECT COUNT(*) FROM curso_topicos.Inventario;
SELECT COUNT(*) FROM curso_topicos.Dim_Cliente;
SELECT COUNT(*) FROM curso_topicos.Dim_Producto;
SELECT COUNT(*) FROM curso_topicos.Dim_Tiempo;
SELECT COUNT(*) FROM curso_topicos.Hecho_Ventas;

INSERT INTO curso_topicos.Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (9999999, (SELECT MIN(ClienteID) FROM curso_topicos.Clientes), 100.50, SYSDATE); 

SELECT * FROM CURSO_TOPICOS.Pedidos p
WHERE p.PedidoID = 9999999;

--------EJERCICIO 2
CONNECT SYS AS SYSDBA;
ALTER SESSION SET CONTAINER = XEPDB1;

SHOW PARAMETER audit_trail;

AUDIT SELECT ON curso_topicos.Clientes BY ACCESS;
AUDIT INSERT ON curso_topicos.Pedidos BY ACCESS;

CONNECT user_analista/analista123@XEPDB1;

SELECT * FROM curso_topicos.Clientes WHERE ROWNUM <= 3;
SELECT Nombre, Ciudad FROM curso_topicos.Clientes WHERE ClienteID = (SELECT MIN(ClienteID) FROM curso_topicos.Clientes);


INSERT INTO curso_topicos.Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (
    9999998, 
    (SELECT MIN(ClienteID) FROM curso_topicos.Clientes), 
    199.99, 
    SYSDATE 
);
COMMIT;

INSERT INTO curso_topicos.Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (
    9999997, 
    (SELECT MAX(ClienteID) FROM curso_topicos.Clientes), 
    249.50, 
    SYSDATE - 1 
);
COMMIT;


CONNECT SYS AS SYSDBA;

ALTER SESSION SET CONTAINER = XEPDB1;


SELECT USERNAME, ACTION_NAME, TIMESTAMP
FROM DBA_AUDIT_TRAIL
WHERE USERNAME = 'USER_ANALISTA';
    