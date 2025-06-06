-- -----------------------------------------------------------------------------
-- Script: BD_impoluta.sql
-- Descripción: Creación del esquema, tablas transaccionales y de Data Warehouse
--              para el curso de Tópicos Avanzados de Datos.
-- Versión: 2.0 (Incluye Dim_Ciudad, Fact_Pedidos y mejoras generales)
-- -----------------------------------------------------------------------------

-- Detener la ejecución si ocurre un error
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK;

-- Configuración inicial de la sesión (ejecutar como SYS o un usuario con privilegios)
-- Cambiar al PDB XEPDB1
ALTER SESSION SET CONTAINER = XEPDB1;

-- -----------------------------------------------------------------------------
-- Creación del Usuario y Otorgamiento de Privilegios
-- -----------------------------------------------------------------------------
PROMPT Creando usuario curso_topicos...
CREATE USER curso_topicos IDENTIFIED BY curso2025;

PROMPT Otorgando privilegios a curso_topicos...
GRANT CONNECT, RESOURCE, CREATE SESSION TO curso_topicos;
GRANT CREATE TABLE, CREATE VIEW, CREATE TYPE, CREATE PROCEDURE, CREATE SEQUENCE, CREATE TRIGGER TO curso_topicos;
GRANT UNLIMITED TABLESPACE TO curso_topicos;

PROMPT Confirmando creación del usuario...
SELECT username FROM dba_users WHERE username = 'CURSO_TOPICOS';

--Cambiar al esquema del curso (ejecutar como SYS o conectar como curso_topicos)
ALTER SESSION SET CURRENT_SCHEMA = curso_topicos;

-- Habilitar salida de mensajes para PL/SQL
SET SERVEROUTPUT ON;

-- -----------------------------------------------------------------------------
-- TABLAS TRANSACCIONALES (OLTP)
-- -----------------------------------------------------------------------------

-- Tabla: Clientes
PROMPT Creando tabla Clientes...
CREATE TABLE Clientes (
    ClienteID       NUMBER CONSTRAINT pk_clientes PRIMARY KEY,
    Nombre          VARCHAR2(100) NOT NULL, -- Aumentado tamaño para nombres más largos
    Ciudad          VARCHAR2(50),
    FechaNacimiento DATE
);
COMMENT ON TABLE Clientes IS 'Almacena información sobre los clientes.';
COMMENT ON COLUMN Clientes.ClienteID IS 'Identificador único del cliente.';
COMMENT ON COLUMN Clientes.Nombre IS 'Nombre completo del cliente.';
COMMENT ON COLUMN Clientes.Ciudad IS 'Ciudad de residencia del cliente.';
COMMENT ON COLUMN Clientes.FechaNacimiento IS 'Fecha de nacimiento del cliente.';

-- Tabla: Productos
PROMPT Creando tabla Productos...
CREATE TABLE Productos (
    ProductoID      NUMBER CONSTRAINT pk_productos PRIMARY KEY,
    Nombre          VARCHAR2(100) NOT NULL, -- Aumentado tamaño
    Precio          NUMBER(10,2) CONSTRAINT nn_productos_precio NOT NULL CONSTRAINT ck_productos_precio CHECK (Precio >= 0) -- Precio no nulo y positivo
);
COMMENT ON TABLE Productos IS 'Almacena información sobre los productos ofrecidos.';
COMMENT ON COLUMN Productos.ProductoID IS 'Identificador único del producto.';
COMMENT ON COLUMN Productos.Nombre IS 'Nombre del producto.';
COMMENT ON COLUMN Productos.Precio IS 'Precio unitario del producto.';

-- Tabla: Pedidos
PROMPT Creando tabla Pedidos...
CREATE TABLE Pedidos (
    PedidoID        NUMBER CONSTRAINT pk_pedidos PRIMARY KEY,
    ClienteID       NUMBER CONSTRAINT nn_pedidos_clienteid NOT NULL,
    Total           NUMBER(12,2) DEFAULT 0 CONSTRAINT ck_pedidos_total CHECK (Total >= 0), -- Total del pedido, default 0
    FechaPedido     DATE DEFAULT SYSDATE CONSTRAINT nn_pedidos_fechapedido NOT NULL, -- Fecha del pedido, default SYSDATE
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);
COMMENT ON TABLE Pedidos IS 'Almacena información sobre los pedidos realizados por los clientes.';
COMMENT ON COLUMN Pedidos.PedidoID IS 'Identificador único del pedido.';
COMMENT ON COLUMN Pedidos.ClienteID IS 'Identificador del cliente que realizó el pedido (FK a Clientes).';
COMMENT ON COLUMN Pedidos.Total IS 'Monto total del pedido.';
COMMENT ON COLUMN Pedidos.FechaPedido IS 'Fecha en que se realizó el pedido.';

-- Tabla: DetallesPedidos
PROMPT Creando tabla DetallesPedidos...
CREATE TABLE DetallesPedidos (
    DetalleID       NUMBER CONSTRAINT pk_detallespedidos PRIMARY KEY,
    PedidoID        NUMBER CONSTRAINT nn_detalles_pedidoid NOT NULL,
    ProductoID      NUMBER CONSTRAINT nn_detalles_productoid NOT NULL,
    Cantidad        NUMBER CONSTRAINT nn_detalles_cantidad NOT NULL CONSTRAINT ck_detalles_cantidad CHECK (Cantidad > 0), -- Cantidad debe ser positiva
    PrecioUnitario  NUMBER(10,2) CONSTRAINT nn_detalles_preciounit NOT NULL CONSTRAINT ck_detalles_preciounit CHECK (PrecioUnitario >= 0), -- Precio unitario no nulo y positivo
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (PedidoID) REFERENCES Pedidos(PedidoID),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
    CONSTRAINT uk_detalle_pedido_producto UNIQUE (PedidoID, ProductoID) -- Un producto solo puede estar una vez por pedido
);
COMMENT ON TABLE DetallesPedidos IS 'Almacena los detalles de cada producto dentro de un pedido.';
COMMENT ON COLUMN DetallesPedidos.DetalleID IS 'Identificador único del detalle del pedido.';
COMMENT ON COLUMN DetallesPedidos.PedidoID IS 'Identificador del pedido al que pertenece este detalle (FK a Pedidos).';
COMMENT ON COLUMN DetallesPedidos.ProductoID IS 'Identificador del producto en este detalle (FK a Productos).';
COMMENT ON COLUMN DetallesPedidos.Cantidad IS 'Cantidad del producto solicitada en este detalle.';
COMMENT ON COLUMN DetallesPedidos.PrecioUnitario IS 'Precio unitario del producto al momento de la compra.';

-- Tabla: Inventario
PROMPT Creando tabla Inventario...
CREATE TABLE Inventario (
    ProductoID          NUMBER CONSTRAINT pk_inventario PRIMARY KEY,
    CantidadProductos   NUMBER DEFAULT 0 CONSTRAINT nn_inventario_cantidad NOT NULL CONSTRAINT ck_inventario_cantidad CHECK (CantidadProductos >= 0), -- Cantidad no nula y no negativa
    CONSTRAINT fk_inventario_producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
);
COMMENT ON TABLE Inventario IS 'Almacena la cantidad de productos disponibles en inventario.';
COMMENT ON COLUMN Inventario.ProductoID IS 'Identificador del producto (FK a Productos).';
COMMENT ON COLUMN Inventario.CantidadProductos IS 'Cantidad disponible del producto en inventario.';

-- -----------------------------------------------------------------------------
-- SECUENCIAS PARA DATA WAREHOUSE
-- -----------------------------------------------------------------------------
PROMPT Creando secuencias para Data Warehouse...
CREATE SEQUENCE seq_Dim_Tiempo_FechaID START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_Dim_Ciudad_CiudadID START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_Hecho_Ventas_VentaID START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_Fact_Pedidos_FactID START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

-- -----------------------------------------------------------------------------
-- TABLAS DE DIMENSIONES (Data Warehouse - OLAP)
-- -----------------------------------------------------------------------------

-- Dimensión: Dim_Cliente
PROMPT Creando tabla Dim_Cliente...
CREATE TABLE Dim_Cliente (
    ClienteID       NUMBER CONSTRAINT pk_dim_cliente PRIMARY KEY, -- Coincide con Clientes.ClienteID para este diseño
    Nombre          VARCHAR2(100) NOT NULL,
    Ciudad          VARCHAR2(50)
    -- Se podrían añadir más atributos SCD (Slowly Changing Dimensions) aquí si fuera necesario
);
COMMENT ON TABLE Dim_Cliente IS 'Dimensión de Clientes para el Data Warehouse. Contiene atributos descriptivos de los clientes.';
COMMENT ON COLUMN Dim_Cliente.ClienteID IS 'Clave del cliente, usualmente la misma que en el sistema transaccional.';
COMMENT ON COLUMN Dim_Cliente.Nombre IS 'Nombre del cliente.';
COMMENT ON COLUMN Dim_Cliente.Ciudad IS 'Ciudad del cliente.';

-- Dimensión: Dim_Producto
PROMPT Creando tabla Dim_Producto...
CREATE TABLE Dim_Producto (
    ProductoID      NUMBER CONSTRAINT pk_dim_producto PRIMARY KEY, -- Coincide con Productos.ProductoID
    Nombre          VARCHAR2(100) NOT NULL,
    Precio          NUMBER(10,2) -- Precio al momento de la carga, o podría ser el actual
    -- Se podrían añadir categorías, marcas, etc.
);
COMMENT ON TABLE Dim_Producto IS 'Dimensión de Productos para el Data Warehouse. Contiene atributos descriptivos de los productos.';
COMMENT ON COLUMN Dim_Producto.ProductoID IS 'Clave del producto, usualmente la misma que en el sistema transaccional.';
COMMENT ON COLUMN Dim_Producto.Nombre IS 'Nombre del producto.';
COMMENT ON COLUMN Dim_Producto.Precio IS 'Precio del producto (puede variar según la estrategia de carga).';

-- Dimensión: Dim_Tiempo
PROMPT Creando tabla Dim_Tiempo...
CREATE TABLE Dim_Tiempo (
    FechaID         NUMBER CONSTRAINT pk_dim_tiempo PRIMARY KEY,
    Fecha           DATE CONSTRAINT nn_dimtiempo_fecha NOT NULL CONSTRAINT uk_dimtiempo_fecha UNIQUE,
    Año             NUMBER(4) CONSTRAINT nn_dimtiempo_ano NOT NULL,
    Mes             NUMBER(2) CONSTRAINT nn_dimtiempo_mes NOT NULL CONSTRAINT ck_dimtiempo_mes CHECK (Mes BETWEEN 1 AND 12),
    Día             NUMBER(2) CONSTRAINT nn_dimtiempo_dia NOT NULL CONSTRAINT ck_dimtiempo_dia CHECK (Día BETWEEN 1 AND 31)
    -- Se podrían añadir trimestre, día de la semana, semana del año, etc.
);
COMMENT ON TABLE Dim_Tiempo IS 'Dimensión de Tiempo para el Data Warehouse. Permite análisis basados en fechas.';
COMMENT ON COLUMN Dim_Tiempo.FechaID IS 'Clave subrogada única para una fecha.';
COMMENT ON COLUMN Dim_Tiempo.Fecha IS 'Fecha completa (sin hora).';
COMMENT ON COLUMN Dim_Tiempo.Año IS 'Año de la fecha.';
COMMENT ON COLUMN Dim_Tiempo.Mes IS 'Mes de la fecha (1-12).';
COMMENT ON COLUMN Dim_Tiempo.Día IS 'Día del mes de la fecha (1-31).';

-- Dimensión: Dim_Ciudad (NUEVA)
PROMPT Creando tabla Dim_Ciudad...
CREATE TABLE Dim_Ciudad (
    CiudadID        NUMBER CONSTRAINT pk_dim_ciudad PRIMARY KEY,
    NombreCiudad    VARCHAR2(50) CONSTRAINT nn_dimciudad_nombre NOT NULL CONSTRAINT uk_dimciudad_nombre UNIQUE
);
COMMENT ON TABLE Dim_Ciudad IS 'Dimensión de Ciudades para el Data Warehouse.';
COMMENT ON COLUMN Dim_Ciudad.CiudadID IS 'Clave subrogada única para la ciudad.';
COMMENT ON COLUMN Dim_Ciudad.NombreCiudad IS 'Nombre de la ciudad.';

-- -----------------------------------------------------------------------------
-- TABLAS DE HECHOS (Data Warehouse - OLAP)
-- -----------------------------------------------------------------------------

-- Hecho: Hecho_Ventas (a nivel de detalle de producto por pedido)
PROMPT Creando tabla Hecho_Ventas...
CREATE TABLE Hecho_Ventas (
    VentaID         NUMBER CONSTRAINT pk_hecho_ventas PRIMARY KEY,
    PedidoID        NUMBER CONSTRAINT nn_hechoventas_pedidoid NOT NULL, -- Referencia al pedido original
    DetalleID       NUMBER CONSTRAINT nn_hechoventas_detalleid NOT NULL CONSTRAINT uk_hechoventas_detalleid UNIQUE, -- Referencia al detalle original
    ClienteID       NUMBER,
    ProductoID      NUMBER,
    FechaID         NUMBER,
    Cantidad        NUMBER CONSTRAINT nn_hechoventas_cantidad NOT NULL,
    PrecioUnitario  NUMBER(10,2) CONSTRAINT nn_hechoventas_preciounit NOT NULL,
    TotalDetalle    NUMBER(12,2) CONSTRAINT nn_hechoventas_total NOT NULL,
    CONSTRAINT fk_hechoventas_cliente FOREIGN KEY (ClienteID) REFERENCES Dim_Cliente(ClienteID),
    CONSTRAINT fk_hechoventas_producto FOREIGN KEY (ProductoID) REFERENCES Dim_Producto(ProductoID),
    CONSTRAINT fk_hechoventas_tiempo FOREIGN KEY (FechaID) REFERENCES Dim_Tiempo(FechaID)
    -- No hay FK a Pedidos o DetallesPedidos directamente para mantener la independencia del DWH,
    -- pero PedidoID y DetalleID se guardan para trazabilidad.
);
COMMENT ON TABLE Hecho_Ventas IS 'Tabla de hechos para las ventas a nivel de detalle de producto. Contiene métricas de ventas.';
COMMENT ON COLUMN Hecho_Ventas.VentaID IS 'Clave subrogada única para el registro de hecho de venta.';
COMMENT ON COLUMN Hecho_Ventas.PedidoID IS 'ID del pedido original del sistema transaccional.';
COMMENT ON COLUMN Hecho_Ventas.DetalleID IS 'ID del detalle del pedido original.';
COMMENT ON COLUMN Hecho_Ventas.ClienteID IS 'Clave foránea a Dim_Cliente.';
COMMENT ON COLUMN Hecho_Ventas.ProductoID IS 'Clave foránea a Dim_Producto.';
COMMENT ON COLUMN Hecho_Ventas.FechaID IS 'Clave foránea a Dim_Tiempo.';
COMMENT ON COLUMN Hecho_Ventas.Cantidad IS 'Cantidad de producto vendida en este detalle.';
COMMENT ON COLUMN Hecho_Ventas.PrecioUnitario IS 'Precio unitario del producto en este detalle.';
COMMENT ON COLUMN Hecho_Ventas.TotalDetalle IS 'Monto total para este detalle de venta (Cantidad * PrecioUnitario).';


-- Hecho: Fact_Pedidos (NUEVA - a nivel de pedido)
PROMPT Creando tabla Fact_Pedidos...
CREATE TABLE Fact_Pedidos (
    FactPedidoID            NUMBER CONSTRAINT pk_fact_pedidos PRIMARY KEY,
    PedidoID                NUMBER CONSTRAINT nn_factpedidos_pedidoid NOT NULL CONSTRAINT uk_factpedidos_pedidoid UNIQUE, -- PedidoID original, debe ser único en esta tabla de hechos
    ClienteID               NUMBER,
    CiudadID                NUMBER,             -- FK a la nueva Dim_Ciudad
    FechaID                 NUMBER,             -- FK a Dim_Tiempo (del día del pedido)
    TotalPedido             NUMBER(12,2) DEFAULT 0,
    CantidadTotalItems      NUMBER DEFAULT 0,
    CONSTRAINT fk_factpedidos_cliente FOREIGN KEY (ClienteID) REFERENCES Dim_Cliente(ClienteID),
    CONSTRAINT fk_factpedidos_ciudad FOREIGN KEY (CiudadID) REFERENCES Dim_Ciudad(CiudadID),
    CONSTRAINT fk_factpedidos_tiempo FOREIGN KEY (FechaID) REFERENCES Dim_Tiempo(FechaID)
);
COMMENT ON TABLE Fact_Pedidos IS 'Tabla de hechos para los pedidos a nivel de encabezado en el Data Warehouse.';
COMMENT ON COLUMN Fact_Pedidos.FactPedidoID IS 'Clave subrogada única para el registro de hecho de pedido.';
COMMENT ON COLUMN Fact_Pedidos.PedidoID IS 'ID del pedido original del sistema transaccional.';
COMMENT ON COLUMN Fact_Pedidos.ClienteID IS 'Clave foránea a Dim_Cliente.';
COMMENT ON COLUMN Fact_Pedidos.CiudadID IS 'Clave foránea a Dim_Ciudad.';
COMMENT ON COLUMN Fact_Pedidos.FechaID IS 'Clave foránea a Dim_Tiempo, basada en la fecha del pedido.';
COMMENT ON COLUMN Fact_Pedidos.TotalPedido IS 'Métrica: Valor total monetario del pedido.';
COMMENT ON COLUMN Fact_Pedidos.CantidadTotalItems IS 'Métrica: Cantidad total de ítems individuales en el pedido (puede requerir actualización posterior).';

-- -----------------------------------------------------------------------------
-- TRIGGERS PARA POBLAR EL DATA WAREHOUSE (Ejemplos básicos)
-- En un entorno de producción, esto se manejaría usualmente con procesos ETL.
-- -----------------------------------------------------------------------------

-- Trigger para insertar datos en Dim_Cliente
PROMPT Creando trigger trg_sync_dim_cliente...
CREATE OR REPLACE TRIGGER trg_sync_dim_cliente
AFTER INSERT OR UPDATE ON Clientes
FOR EACH ROW
BEGIN
    MERGE INTO Dim_Cliente d
    USING (SELECT :NEW.ClienteID AS ClienteID, :NEW.Nombre AS Nombre, :NEW.Ciudad AS Ciudad FROM dual) n
    ON (d.ClienteID = n.ClienteID)
    WHEN MATCHED THEN
        UPDATE SET d.Nombre = n.Nombre, d.Ciudad = n.Ciudad
        WHERE d.Nombre <> n.Nombre OR d.Ciudad <> n.Ciudad OR (d.Ciudad IS NULL AND n.Ciudad IS NOT NULL) OR (d.Ciudad IS NOT NULL AND n.Ciudad IS NULL) -- Solo actualizar si hay cambios
    WHEN NOT MATCHED THEN
        INSERT (ClienteID, Nombre, Ciudad)
        VALUES (n.ClienteID, n.Nombre, n.Ciudad);
END;
/
COMMENT ON TRIGGER trg_sync_dim_cliente IS 'Sincroniza Dim_Cliente con los cambios en la tabla Clientes.';

-- Trigger para insertar datos en Dim_Producto
PROMPT Creando trigger trg_sync_dim_producto...
CREATE OR REPLACE TRIGGER trg_sync_dim_producto
AFTER INSERT OR UPDATE ON Productos
FOR EACH ROW
BEGIN
    MERGE INTO Dim_Producto d
    USING (SELECT :NEW.ProductoID AS ProductoID, :NEW.Nombre AS Nombre, :NEW.Precio AS Precio FROM dual) n
    ON (d.ProductoID = n.ProductoID)
    WHEN MATCHED THEN
        UPDATE SET d.Nombre = n.Nombre, d.Precio = n.Precio
        WHERE d.Nombre <> n.Nombre OR d.Precio <> n.Precio
    WHEN NOT MATCHED THEN
        INSERT (ProductoID, Nombre, Precio)
        VALUES (n.ProductoID, n.Nombre, n.Precio);
END;
/
COMMENT ON TRIGGER trg_sync_dim_producto IS 'Sincroniza Dim_Producto con los cambios en la tabla Productos.';

-- Trigger para insertar datos en Dim_Tiempo (cuando se crea un pedido)
PROMPT Creando trigger trg_ensure_dim_tiempo...
CREATE OR REPLACE TRIGGER trg_ensure_dim_tiempo
AFTER INSERT ON Pedidos
FOR EACH ROW
DECLARE
    v_count NUMBER;
    v_fecha_truncada DATE := TRUNC(:NEW.FechaPedido);
BEGIN
    SELECT COUNT(*) INTO v_count FROM Dim_Tiempo WHERE Fecha = v_fecha_truncada;
    IF v_count = 0 THEN
        INSERT INTO Dim_Tiempo (FechaID, Fecha, Año, Mes, Día)
        VALUES (
            seq_Dim_Tiempo_FechaID.NEXTVAL,
            v_fecha_truncada,
            EXTRACT(YEAR FROM v_fecha_truncada),
            EXTRACT(MONTH FROM v_fecha_truncada),
            EXTRACT(DAY FROM v_fecha_truncada)
        );
    END IF;
END;
/
COMMENT ON TRIGGER trg_ensure_dim_tiempo IS 'Asegura que la fecha de un nuevo pedido exista en Dim_Tiempo.';

-- Trigger para insertar datos en Dim_Ciudad (cuando se crea o actualiza un cliente) (NUEVO)
PROMPT Creando trigger trg_upsert_dim_ciudad...
CREATE OR REPLACE TRIGGER trg_upsert_dim_ciudad
AFTER INSERT OR UPDATE OF Ciudad ON Clientes
FOR EACH ROW
DECLARE
    v_count NUMBER;
BEGIN
    IF :NEW.Ciudad IS NOT NULL THEN
        SELECT COUNT(*) INTO v_count FROM Dim_Ciudad WHERE NombreCiudad = :NEW.Ciudad;
        IF v_count = 0 THEN
            INSERT INTO Dim_Ciudad (CiudadID, NombreCiudad)
            VALUES (seq_Dim_Ciudad_CiudadID.NEXTVAL, :NEW.Ciudad);
        END IF;
    END IF;
EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN -- En caso de carrera si dos sesiones insertan la misma ciudad casi al mismo tiempo
        NULL; -- La ciudad ya fue insertada por otra sesión, no hacer nada.
END;
/
COMMENT ON TRIGGER trg_upsert_dim_ciudad IS 'Asegura que la ciudad de un cliente exista en Dim_Ciudad.';

-- Trigger para insertar datos en Hecho_Ventas (cuando se crea un detalle de pedido)
PROMPT Creando trigger trg_insert_hecho_ventas...
CREATE OR REPLACE TRIGGER trg_insert_hecho_ventas
AFTER INSERT ON DetallesPedidos
FOR EACH ROW
DECLARE
    v_cliente_id    Pedidos.ClienteID%TYPE;
    v_fecha_pedido  Pedidos.FechaPedido%TYPE;
    v_fecha_id      Dim_Tiempo.FechaID%TYPE;
BEGIN
    -- Obtener ClienteID y FechaPedido del pedido asociado
    SELECT p.ClienteID, p.FechaPedido
    INTO v_cliente_id, v_fecha_pedido
    FROM Pedidos p
    WHERE p.PedidoID = :NEW.PedidoID;

    -- Obtener FechaID de Dim_Tiempo
    SELECT dt.FechaID
    INTO v_fecha_id
    FROM Dim_Tiempo dt
    WHERE dt.Fecha = TRUNC(v_fecha_pedido); -- Asegurar comparación con fecha truncada

    -- Insertar en Hecho_Ventas
    INSERT INTO Hecho_Ventas (
        VentaID, PedidoID, DetalleID, ClienteID, ProductoID, FechaID,
        Cantidad, PrecioUnitario, TotalDetalle
    ) VALUES (
        seq_Hecho_Ventas_VentaID.NEXTVAL,
        :NEW.PedidoID,
        :NEW.DetalleID,
        v_cliente_id,
        :NEW.ProductoID,
        v_fecha_id,
        :NEW.Cantidad,
        :NEW.PrecioUnitario,
        :NEW.Cantidad * :NEW.PrecioUnitario
    );
END;
/
COMMENT ON TRIGGER trg_insert_hecho_ventas IS 'Puebla Hecho_Ventas cuando se inserta un nuevo detalle de pedido.';

-- Trigger para insertar datos en Fact_Pedidos (cuando se crea un pedido) (NUEVO)
PROMPT Creando trigger trg_insert_fact_pedidos...
CREATE OR REPLACE TRIGGER trg_insert_fact_pedidos
AFTER INSERT ON Pedidos
FOR EACH ROW
DECLARE
    v_ciudad_id     Dim_Ciudad.CiudadID%TYPE := NULL;
    v_fecha_id      Dim_Tiempo.FechaID%TYPE;
    v_cliente_ciudad Clientes.Ciudad%TYPE;
BEGIN
    -- Obtener CiudadID
    IF :NEW.ClienteID IS NOT NULL THEN
        SELECT c.Ciudad INTO v_cliente_ciudad FROM Clientes c WHERE c.ClienteID = :NEW.ClienteID;
        IF v_cliente_ciudad IS NOT NULL THEN
            BEGIN
                SELECT dc.CiudadID INTO v_ciudad_id FROM Dim_Ciudad dc WHERE dc.NombreCiudad = v_cliente_ciudad;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_ciudad_id := NULL; -- Ciudad no encontrada en Dim_Ciudad (debería haber sido insertada por trg_upsert_dim_ciudad)
            END;
        END IF;
    END IF;

    -- Obtener FechaID
    BEGIN
        SELECT dt.FechaID INTO v_fecha_id FROM Dim_Tiempo dt WHERE dt.Fecha = TRUNC(:NEW.FechaPedido);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            -- Esto no debería ocurrir si trg_ensure_dim_tiempo funciona correctamente
            RAISE_APPLICATION_ERROR(-20001, 'FechaID no encontrado en Dim_Tiempo para la fecha del pedido: ' || TO_CHAR(:NEW.FechaPedido, 'YYYY-MM-DD'));
    END;

    INSERT INTO Fact_Pedidos (
        FactPedidoID, PedidoID, ClienteID, CiudadID, FechaID, TotalPedido, CantidadTotalItems
    ) VALUES (
        seq_Fact_Pedidos_FactID.NEXTVAL,
        :NEW.PedidoID,
        :NEW.ClienteID,
        v_ciudad_id,
        v_fecha_id,
        :NEW.Total, -- Asume que Pedidos.Total es el valor final del pedido
        0 -- CantidadTotalItems se inicializa en 0, podría actualizarse por otro trigger o ETL
    );
END;
/
COMMENT ON TRIGGER trg_insert_fact_pedidos IS 'Puebla Fact_Pedidos cuando se inserta un nuevo pedido. CantidadTotalItems se inicializa en 0.';

-- -----------------------------------------------------------------------------
-- COMMIT FINAL
-- -----------------------------------------------------------------------------

PROMPT Aplicando cambios (COMMIT)...
COMMIT;

PROMPT Script finalizado. Base de datos 'curso_topicos' configurada y mejorada.
