-- Conectarse como administrador (por ejemplo, SYS con SYSDBA)
-- Esto lo hace el instructor o administrador, no los estudiantes
-- sqlplus sys as sysdba

-- Crear un nuevo usuario (esquema) para el curso
CREATE USER curso_topicos IDENTIFIED BY curso2025;

-- Otorgar privilegios necesarios al usuario
GRANT CONNECT, RESOURCE, CREATE SESSION TO curso_topicos;
GRANT CREATE TABLE, CREATE TYPE, CREATE PROCEDURE TO curso_topicos;
GRANT UNLIMITED TABLESPACE TO curso_topicos;

-- Confirmar creación
SELECT username FROM dba_users WHERE username = 'CURSO_TOPICOS';

-- Conectarse al esquema curso_topicos
-- Los estudiantes deben usar: CONNECT curso_topicos/curso2025

-- Habilitar salida de mensajes para PL/SQL
SET SERVEROUTPUT ON;

-- Crear tabla Clientes
CREATE TABLE Clientes (
    ClienteID NUMBER PRIMARY KEY,
    Nombre VARCHAR2(50),
    Ciudad VARCHAR2(50),
    FechaNacimiento DATE
);

-- Crear tabla Pedidos
CREATE TABLE Pedidos (
    PedidoID NUMBER PRIMARY KEY,
    ClienteID NUMBER,
    Total NUMBER,
    FechaPedido DATE,
    CONSTRAINT fk_pedido_cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
);

-- Crear tabla Productos
CREATE TABLE Productos (
    ProductoID NUMBER PRIMARY KEY,
    Nombre VARCHAR2(50),
    Precio NUMBER
);

-- Insertar datos en Clientes
INSERT INTO Clientes VALUES (1, 'Juan Perez', 'Santiago', TO_DATE('1990-05-15', 'YYYY-MM-DD'));
INSERT INTO Clientes VALUES (2, 'María Gomez', 'Valparaiso', TO_DATE('1985-10-20', 'YYYY-MM-DD'));
INSERT INTO Clientes VALUES (3, 'Ana Lopez', 'Santiago', TO_DATE('1995-03-10', 'YYYY-MM-DD'));

-- Insertar datos en Pedidos
INSERT INTO Pedidos VALUES (101, 1, 600, TO_DATE('2025-03-01', 'YYYY-MM-DD'));
INSERT INTO Pedidos VALUES (102, 1, 300, TO_DATE('2025-03-02', 'YYYY-MM-DD'));
INSERT INTO Pedidos VALUES (103, 2, 800, TO_DATE('2025-03-03', 'YYYY-MM-DD'));

-- Insertar datos en Productos
INSERT INTO Productos VALUES (1, 'Laptop', 1200);
INSERT INTO Productos VALUES (2, 'Mouse', 25);

-- Confirmar creación e inserción de datos
SELECT 'Tablas creadas y datos insertados correctamente.' AS mensaje FROM dual;

-- Verificar datos
SELECT * FROM Clientes;
SELECT * FROM Pedidos;
SELECT * FROM Productos;

-- Commit para asegurar los cambios
COMMIT;