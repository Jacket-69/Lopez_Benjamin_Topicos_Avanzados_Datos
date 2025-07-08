----- EJERCICIO 1

-- 1. DEFINICIÓN DE ROLES
PROMPT Creando rol para vendedores...
CREATE ROLE rol_vendedor;

PROMPT Creando rol para administradores...
CREATE ROLE rol_administrador;

-- 2. ASIGNACIÓN DE PERMISOS A ROLES

-- Permisos para el ROL_VENDEDOR
PROMPT Asignando permisos al rol_vendedor...
-- Permite consultar la información de clientes y productos.
GRANT SELECT ON Clientes TO rol_vendedor;
GRANT SELECT ON Productos TO rol_vendedor;
GRANT SELECT ON Inventario TO rol_vendedor;

-- Permite crear nuevos pedidos y añadir detalles a esos pedidos.
GRANT INSERT, SELECT ON Pedidos TO rol_vendedor;
GRANT INSERT, SELECT ON DetallesPedidos TO rol_vendedor;

-- Permisos para el ROL_ADMINISTRADOR
PROMPT Asignando permisos al rol_administrador...
-- Permite realizar cualquier operación (CRUD) sobre las tablas transaccionales.
GRANT SELECT, INSERT, UPDATE, DELETE ON Clientes TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON Productos TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON Pedidos TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON DetallesPedidos TO rol_administrador;
GRANT SELECT, INSERT, UPDATE, DELETE ON Inventario TO rol_administrador;

-- Permiso para administrar otros usuarios y roles (opcional pero común para un admin).
GRANT CREATE USER, DROP USER, CREATE ROLE, DROP ANY ROLE TO rol_administrador WITH ADMIN OPTION;    

-- 3. CREACIÓN DE USUARIOS Y ASIGNACIÓN DE ROLES

PROMPT Creando usuario 'vendedor01'...
CREATE USER vendedor01 IDENTIFIED BY VentaSegura2025;
GRANT CONNECT, rol_vendedor TO vendedor01;
ALTER USER vendedor01 DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;

PROMPT Creando usuario 'admin01'...
CREATE USER admin01 IDENTIFIED BY AdminTotal2025;
GRANT CONNECT, RESOURCE, rol_administrador TO admin01;
ALTER USER admin01 DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS;

PROMPT Aplicando cambios (COMMIT)...
COMMIT;


----- EJERCICIO 2

-- 1. ANÁLISIS DE LA CONSULTA CRÍTICA (ESTADO INICIAL)

-- Consulta: Reporte de ventas totales y cantidad de productos por cliente.

PROMPT Analizando el plan de ejecución ANTES de la optimización...

EXPLAIN PLAN FOR
SELECT
    c.Nombre,
    COUNT(p.PedidoID) AS NumeroDePedidos,
    SUM(p.Total) AS TotalGastado
FROM
    Clientes c
JOIN
    Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY
    c.Nombre
ORDER BY
    TotalGastado DESC;

-- Mostrar el plan de ejecución
PROMPT Plan de Ejecución Inicial:
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- 2. APLICACIÓN DE LA MEJORA

PROMPT Creando índices para optimizar los JOINs...

-- Índice en la columna Pedidos(ClienteID) para acelerar el JOIN con Clientes.
CREATE INDEX idx_pedidos_clienteid ON Pedidos(ClienteID);

-- Índice en la columna DetallesPedidos(PedidoID) para futuras consultas de detalle.
CREATE INDEX idx_detalles_pedidoid ON DetallesPedidos(PedidoID);

-- 3. ANÁLISIS POST-OPTIMIZACIÓN

PROMPT Analizando el plan de ejecución DESPUÉS de la optimización...

EXPLAIN PLAN FOR
SELECT
    c.Nombre,
    COUNT(p.PedidoID) AS NumeroDePedidos,
    SUM(p.Total) AS TotalGastado
FROM
    Clientes c
JOIN
    Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY
    c.Nombre
ORDER BY
    TotalGastado DESC;

-- Mostrar el nuevo plan de ejecución
PROMPT Nuevo Plan de Ejecución:
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

COMMIT;

PROMPT Script de optimización finalizado.