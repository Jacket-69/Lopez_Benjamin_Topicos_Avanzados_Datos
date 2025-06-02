---------EJERCICIO 1

SELECT c.Nombre, COUNT(p.PedidoID) AS TotalPedidos
FROM Clientes c, Pedidos p
WHERE c.ClienteID = p.ClienteID
AND c.Ciudad = 'Calama'
AND p.FechaPedido >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
GROUP BY c.Nombre;

-- 1. EXPLAIN PLAN
EXPLAIN PLAN FOR
SELECT c.Nombre, COUNT(p.PedidoID) AS TotalPedidos
FROM Clientes c, Pedidos p
WHERE c.ClienteID = p.ClienteID
AND c.Ciudad = 'Calama'
AND p.FechaPedido >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
GROUP BY c.Nombre;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
ANALISIS

c.Ciudad = 'Santiago' causaria un escaneo completo si no hay indice

se reemplazan los WHERE por un INNER JOIN para mejorar la claridad

El INNER JOIN c.ClienteID = p.ClienteID va a necesitar indices tambien

La condición p.FechaPedido >= TO_DATE(...) tambien necesita indices
o un particionamiento en FechaPedido

Si Pedidos no tiene particiones en FechaPedido se van a tener que escanear
muchos datos

*/

-- 2. Optimizar la consulta
--actualizar estadisticas
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS('CURSO_TOPICOS', 'Clientes');
  DBMS_STATS.GATHER_TABLE_STATS('CURSO_TOPICOS', 'Pedidos');
END;
/
-- usar indices
-- usar JOINS en vez de WHERE, para mejorar la claridad
CREATE INDEX idx_clientes_ciudad ON Clientes(Ciudad);
CREATE INDEX idx_pedidos_clienteid ON Pedidos(ClienteID);

EXPLAIN PLAN FOR
SELECT c.Nombre,
       COUNT(p.PedidoID) AS TotalPedidos 
FROM   Clientes c
INNER JOIN Pedidos p ON c.ClienteID = p.ClienteID
WHERE  c.Ciudad = 'Santiago'
AND    p.FechaPedido >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
GROUP BY c.Nombre;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 3. Particiones

CREATE TABLE Pedidos_Partitioned (
    PedidoID    NUMBER NOT NULL,
    ClienteID   NUMBER,
    Total       NUMBER,
    FechaPedido DATE NOT NULL,
    CONSTRAINT pk_pedidos_partitioned PRIMARY KEY (PedidoID)
)
PARTITION BY RANGE (FechaPedido) (
    PARTITION p0_antes_2025 VALUES LESS THAN (TO_DATE('2025-01-01', 'YYYY-MM-DD')),
    PARTITION p1_2025_q1    VALUES LESS THAN (TO_DATE('2025-04-01', 'YYYY-MM-DD')), -- Trimestre 1 2025
    PARTITION p2_2025_q2    VALUES LESS THAN (TO_DATE('2025-07-01', 'YYYY-MM-DD')), -- Trimestre 2 2025
    PARTITION p3_2025_q3    VALUES LESS THAN (TO_DATE('2025-10-01', 'YYYY-MM-DD')), -- Trimestre 3 2025
    PARTITION p4_2025_q4    VALUES LESS THAN (TO_DATE('2026-01-01', 'YYYY-MM-DD')), -- Trimestre 4 2025
    PARTITION p_resto       VALUES LESS THAN (MAXVALUE) -- Para fechas futuras
);

-- Crear índice local en la columna de JOIN (ClienteID)
CREATE INDEX idx_pedidos_part_clienteid ON Pedidos_Partitioned(ClienteID) LOCAL;


-- 4. Migrar los datos ;-;

INSERT INTO Pedidos_Partitioned (PedidoID, ClienteID, Total, FechaPedido)
SELECT PedidoID, ClienteID, Total, FechaPedido FROM Pedidos;

COMMIT;

-- 5. Reemplazar la tabla orignal

DROP TABLE Pedidos CASCADE CONSTRAINTS;
-- Renombrar la nueva tabla particionada
ALTER TABLE Pedidos_Partitioned RENAME TO Pedidos;

-- 6. Recrear las llaves e indices

ALTER TABLE DetallesPedidos
ADD CONSTRAINT fk_detalles_pedidos_pedido FOREIGN KEY (PedidoID)
REFERENCES Pedidos(PedidoID);

ALTER TABLE Pedidos
ADD CONSTRAINT fk_pedidos_cliente FOREIGN KEY (ClienteID)
REFERENCES Clientes(ClienteID);

-- 7. Probar consulta optimizada

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'Pedidos');
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'Clientes');
END;
/

EXPLAIN PLAN FOR
SELECT c.Nombre, COUNT(p.PedidoID) AS TotalPedidos
FROM   Clientes c
       JOIN Pedidos p ON c.ClienteID = p.ClienteID
WHERE  c.Ciudad = 'Santiago'
AND    p.FechaPedido >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
GROUP BY c.Nombre;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

---------EJERCICIO 1