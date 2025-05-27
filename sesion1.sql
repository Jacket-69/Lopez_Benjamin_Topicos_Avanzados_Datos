-- sesion1.sql: Script para la Sesión 1

-- Detener la ejecución si ocurre un error
WHENEVER SQLERROR EXIT SQL.SQLCODE;

-- Cambiar al PDB XEPDB1
ALTER SESSION SET CONTAINER = XEPDB1;

-- Crear un nuevo usuario (esquema) para el curso en el PDB
CREATE USER curso_topicos IDENTIFIED BY curso2025;

-- Otorgar privilegios necesarios al usuario
GRANT CONNECT, RESOURCE, CREATE SESSION TO curso_topicos;
GRANT CREATE TABLE, CREATE TYPE, CREATE PROCEDURE TO curso_topicos;
GRANT UNLIMITED TABLESPACE TO curso_topicos;

-- Confirmar creación
SELECT username FROM dba_users WHERE username = 'CURSO_TOPICOS';

-- Cambiar al esquema curso_topicos
ALTER SESSION SET CURRENT_SCHEMA = curso_topicos;

-- Habilitar salida de mensajes para PL/SQL
SET SERVEROUTPUT ON;

-- Crear tabla Clientes
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Clientes...');
    EXECUTE IMMEDIATE 'CREATE TABLE Clientes (
        ClienteID NUMBER PRIMARY KEY,
        Nombre VARCHAR2(50),
        Ciudad VARCHAR2(50),
        FechaNacimiento DATE
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Clientes creada.');
END;
/

-- Crear tabla Pedidos
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Pedidos...');
    EXECUTE IMMEDIATE 'CREATE TABLE Pedidos (
        PedidoID NUMBER PRIMARY KEY,
        ClienteID NUMBER,
        Total NUMBER,
        FechaPedido DATE,
        CONSTRAINT fk_pedido_cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Pedidos creada.');
END;
/

-- Crear tabla Productos
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Productos...');
    EXECUTE IMMEDIATE 'CREATE TABLE Productos (
        ProductoID NUMBER PRIMARY KEY,
        Nombre VARCHAR2(50),
        Precio NUMBER
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Productos creada.');
END;
/


-- Confirmar los datos insertados antes de continuar
COMMIT;

-- Confirmar creación e inserción de datos
BEGIN
    DBMS_OUTPUT.PUT_LINE('Tablas creadas y datos insertados correctamente.');
END;
/


-- Crear tabla DetallesPedidos
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla DetallesPedidos...');
    EXECUTE IMMEDIATE 'CREATE TABLE DetallesPedidos (
        DetalleID NUMBER PRIMARY KEY,
        PedidoID NUMBER,
        ProductoID NUMBER,
        Cantidad NUMBER,
        PrecioUnitario NUMBER(10,2),
        CONSTRAINT fk_detalle_pedido FOREIGN KEY (PedidoID) REFERENCES Pedidos(PedidoID),
        CONSTRAINT fk_detalle_producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla DetallesPedidos creada.');
END;
/


-- Crear tabla Inventario
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Inventario...');
    EXECUTE IMMEDIATE 'CREATE TABLE Inventario (
    ProductoID NUMBER PRIMARY KEY,
    CantidadProductos NUMBER,
    CONSTRAINT fk_inventario_producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Inventario creada.');
END;
/

--Creando Tabla Dimensión Cliente
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Dim_Cliente...');
    EXECUTE IMMEDIATE 'CREATE TABLE Dim_Cliente (
        ClienteID NUMBER PRIMARY KEY,
        Nombre VARCHAR2(50),
        Ciudad VARCHAR2(50)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Dim_Cliente creada.');
END;
/


--Creando Tabla Dimensión Producto
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Dim_Producto...');
    EXECUTE IMMEDIATE 'CREATE TABLE Dim_Producto (
        ProductoID NUMBER PRIMARY KEY,
        Nombre VARCHAR2(50),
        Precio NUMBER
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Dim_Producto creada.');
END;
/

--Creando Tabla Dimensión Tiempo
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Dim_Tiempo...');
    EXECUTE IMMEDIATE 'CREATE TABLE Dim_Tiempo (
        FechaID NUMBER PRIMARY KEY,
        Fecha DATE,
        Año NUMBER,
        Mes NUMBER,
        Día NUMBER
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Dim_Tiempo creada.');
END;
/

--Creando Tabla Hecho Ventas
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando tabla Hecho_Ventas...');
    EXECUTE IMMEDIATE 'CREATE TABLE Hecho_Ventas (
    VentaID NUMBER PRIMARY KEY,
    PedidoID NUMBER,
    ClienteID NUMBER,
    ProductoID NUMBER,
    FechaID NUMBER,
    Cantidad NUMBER,
    Total NUMBER,
    CONSTRAINT fk_venta_cliente FOREIGN KEY (ClienteID) REFERENCES Dim_Cliente(ClienteID),
    CONSTRAINT fk_venta_producto FOREIGN KEY (ProductoID) REFERENCES Dim_Producto(ProductoID),
    CONSTRAINT fk_venta_tiempo FOREIGN KEY (FechaID) REFERENCES Dim_Tiempo(FechaID)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla Hecho_Ventas creada.');
END;
/

CREATE SEQUENCE Dim_Tiempo_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE Hecho_Ventas_seq START WITH 1 INCREMENT BY 1;


-- Trigger para insertar datos en Dim_Cliente

BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando trigger para insertar en Dim_Cliente...');
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER trg_insert_dim_cliente
    AFTER INSERT ON Clientes
    FOR EACH ROW
    BEGIN
        INSERT INTO Dim_Cliente (ClienteID, Nombre, Ciudad)
        VALUES (:NEW.ClienteID, :NEW.Nombre, :NEW.Ciudad);
    END;';
    DBMS_OUTPUT.PUT_LINE('Trigger creado.');
END;
/

-- Trigger para insertar datos en Dim_Producto

BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando trigger para insertar en Dim_Producto...');
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER trg_insert_dim_producto
    AFTER INSERT ON Productos
    FOR EACH ROW
    BEGIN
        INSERT INTO Dim_Producto (ProductoID, Nombre, Precio)
        VALUES (:NEW.ProductoID, :NEW.Nombre, :NEW.Precio);
    END;';
    DBMS_OUTPUT.PUT_LINE('Trigger creado.');
END;
/


-- Trigger para Dim_Tiempo

BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando trigger para insertar en Dim_Tiempo...');
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER trg_insert_dim_tiempo
    AFTER INSERT ON Pedidos
    FOR EACH ROW
    DECLARE
        v_fecha_id NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_fecha_id FROM Dim_Tiempo WHERE Fecha = :NEW.FechaPedido;
  
        IF v_fecha_id = 0 THEN
        INSERT INTO Dim_Tiempo (FechaID, Fecha, Año, Mes, Día)
        VALUES (
        Dim_Tiempo_seq.NEXTVAL,
        :NEW.FechaPedido,
        EXTRACT(YEAR FROM :NEW.FechaPedido),
        EXTRACT(MONTH FROM :NEW.FechaPedido),
        EXTRACT(DAY FROM :NEW.FechaPedido)
    );
  END IF;
END;';
    DBMS_OUTPUT.PUT_LINE('Trigger creado.');
END;
/

-- Trigger para Hecho_Ventas
BEGIN
    DBMS_OUTPUT.PUT_LINE('Creando trigger para insertar en Hecho_Ventas...');
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER trg_insert_hecho_ventas
    AFTER INSERT ON DetallesPedidos
    FOR EACH ROW
    DECLARE
        v_fecha DATE;
        v_fecha_id NUMBER;
        v_precio NUMBER;
    BEGIN
        SELECT FechaPedido INTO v_fecha FROM Pedidos WHERE PedidoID = :NEW.PedidoID;

        SELECT FechaID INTO v_fecha_id FROM Dim_Tiempo WHERE Fecha = v_fecha;

        SELECT Precio INTO v_precio FROM Productos WHERE ProductoID = :NEW.ProductoID;

        INSERT INTO Hecho_Ventas (
        VentaID, PedidoID, ClienteID, ProductoID, FechaID, Cantidad, Total
        ) VALUES (
        Hecho_Ventas_seq.NEXTVAL,
        :NEW.PedidoID,
        (SELECT ClienteID FROM Pedidos WHERE PedidoID = :NEW.PedidoID),
        :NEW.ProductoID,
        v_fecha_id,
        :NEW.Cantidad,
        v_precio * :NEW.Cantidad
    );END;';
    DBMS_OUTPUT.PUT_LINE('Trigger creado.');
END;
/


-- Commit final
COMMIT;