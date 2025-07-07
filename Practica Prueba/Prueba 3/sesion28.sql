--------- Ejercicio 1 -----------
----Enunciado
/*
Define qué es una transacción en una base de datos y explica
cómo las propiedades ACID garantizan su integridad.
Proporciona un ejemplo de un procedimiento que registre un
pedido en la tabla Pedidos, usando savepoints para revertir
la operación si el cliente no existe.
*/

----Respuesta

/*
Una transacción en una base de datos es una secuencia de una o más
operaciones que se ejecutan como una única unidad de trabajo lógico. 
Para que la base de datos se mantenga consistente, la transacción debe 
ejecutarse en su totalidad o no ejecutarse en absoluto.

Atomicidad (Atomicity): Asegura que todas las operaciones dentro de la transacción se
completen con éxito. Si una sola operación falla, la transacción completa se revierte 
(rollback), y la base de datos queda en el estado en que se encontraba antes de que la
transacción comenzara. Es un "todo o nada".

Consistencia (Consistency): Garantiza que la base de datos permanezca en un estado
válido antes y después de la transacción. La transacción solo puede llevar la base de datos
de un estado válido a otro, respetando todas las reglas y restricciones definidas (como 
llaves primarias, foráneas, etc.).

Aislamiento (Isolation): Asegura que las transacciones concurrentes (que se ejecutan al
mismo tiempo) no interfieran entre sí. El resultado de ejecutar múltiples transacciones
simultáneamente debe ser el mismo que si se ejecutaran una tras otra en serie.

Durabilidad (Durability): Una vez que una transacción ha sido confirmada (commit), sus
cambios son permanentes y sobrevivirán a cualquier fallo posterior del sistema, como un
corte de energía o un reinicio del servidor.
*/

-- Ejemplo

CREATE OR REPLACE PROCEDURE registrar_pedido (
    p_cliente_id IN NUMBER,
    p_total IN NUMBER,
    p_fecha_pedido IN DATE
) AS
    v_cliente_existe NUMBER;
BEGIN
    -- Inicia la transacción

    SAVEPOINT inicio_pedido; -- Se establece un punto de guardado antes de cualquier operación.

    -- 1. Validar que el cliente existe
    SELECT COUNT(*)
    INTO v_cliente_existe
    FROM Clientes
    WHERE ClienteID = p_cliente_id;

    -- 2. Si el cliente no existe, revertir al savepoint y lanzar un error
    IF v_cliente_existe = 0 THEN
        ROLLBACK TO inicio_pedido; -- Se revierte cualquier cambio hecho después del savepoint.
        RAISE_APPLICATION_ERROR(-20001, 'Error: El cliente con ID ' || p_cliente_id || ' no existe.');
    END IF;

    -- 3. Si el cliente existe, insertar el pedido
    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES ((SELECT NVL(MAX(PedidoID), 0) + 1 FROM Pedidos), p_cliente_id, p_total, p_fecha_pedido);

    -- 4. Confirmar la transacción completa
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Pedido registrado exitosamente.');

EXCEPTION
    WHEN OTHERS THEN
        -- Si ocurre cualquier otro error, revertir toda la transacción
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM || '. Operación revertida.');
END;
/


----pruebasss

BEGIN
    registrar_pedido(
        p_cliente_id => 1,
        p_total => 250.50,
        p_fecha_pedido => SYSDATE
    );
END;
/

SELECT * FROM Pedidos WHERE ClienteID = 1;

--------- Ejercicio 2 -----------
----Enunciado
/*
¿Qué es un Data Warehouse y cómo se diferencia de una base
de datos operativa en términos de propósito y estructura?
Diseña una tabla de hechos Fact_Inventario para analizar el
movimiento de productos (entradas y salidas) en la base de
datos, incluyendo claves foráneas y medidas adecuadas.
*/
----Respuesta
/*
Un Data Warehouse (DW) es un sistema de almacenamiento de datos diseñado específicamente
para el análisis y la generación de informes. Su propósito principal es consolidar y
almacenar grandes volúmenes de datos históricos de diversas fuentes para facilitar la toma de
decisiones estratégicas en una empresa.
Una base de datos operativa es el corazón de las operaciones diarias de una empresa. 
Su objetivo es procesar un gran volumen de transacciones cortas y rápidas en tiempo real.
Para garantizar la integridad y evitar la duplicación de datos, su estructura está altamente normalizada.
Esto la optimiza para operaciones de escritura (INSERT, UPDATE), asegurando que los datos actuales del 
negocio sean consistentes y precisos.

Un DW no está diseñado para el día a día, sino para el análisis estratégico.
Su propósito es consolidar y almacenar grandes cantidades de datos históricos 
provenientes de una o más bases de datos operativas.
El objetivo es permitir a los analistas y directivos hacer
preguntas complejas para identificar tendencias, patrones y 
obtener información valiosa para la toma de decisiones, como
"¿cuál fue nuestro producto más vendido en cada región durante los últimos cinco años?".

Para facilitar este tipo de consultas masivas, la estructura de un Data Warehouse es
intencionadamente desnormalizada. Se organiza en un esquema de estrella o copo de nieve,
con tablas de hechos que contienen métricas numéricas y tablas de dimensiones
que proveen el contexto descriptivo. Esta arquitectura está optimizada para la lectura y
agregación rápida de datos, sacrificando la eficiencia de la escritura en favor de 
la velocidad de las consultas analíticas.
*/

-- Ejemplo

CREATE TABLE Fact_Inventario (
    FactID              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- Clave única del hecho
    ProductoID          NUMBER,         -- FK a Dim_Producto
    FechaID             NUMBER,         -- FK a Dim_Tiempo
    CantidadMovimiento  NUMBER,         -- La medida principal: cuántas unidades se movieron
    TipoMovimiento      VARCHAR2(10),   -- 'Entrada' o 'Salida'
    CONSTRAINT fk_fact_inventario_producto FOREIGN KEY (ProductoID) REFERENCES Dim_Producto (ProductoID),
    CONSTRAINT fk_fact_inventario_tiempo FOREIGN KEY (FechaID) REFERENCES Dim_Tiempo (FechaID)
);

-- Inserta el producto 10 en la dimensión de productos
INSERT INTO Dim_Producto (ProductoID, Nombre, Precio)
SELECT ProductoID, Nombre, Precio FROM Productos WHERE ProductoID = 10;

-- Inserta la fecha del movimiento en la dimensión de tiempo
INSERT INTO Dim_Tiempo (FechaID, Fecha, Año, Mes, Día)
VALUES (
    seq_Dim_Tiempo_FechaID.NEXTVAL,
    TO_DATE('2025-07-10', 'YYYY-MM-DD'),
    2025,
    7,
    10
);

COMMIT;


-- Insertar una ENTRADA de inventario
INSERT INTO Fact_Inventario (ProductoID, FechaID, CantidadMovimiento, TipoMovimiento)
VALUES (10, (SELECT FechaID FROM Dim_Tiempo WHERE Fecha = TO_DATE('2025-07-10', 'YYYY-MM-DD')), 100, 'Entrada');

-- Insertar una SALIDA de inventario
INSERT INTO Fact_Inventario (ProductoID, FechaID, CantidadMovimiento, TipoMovimiento)
VALUES (10, (SELECT FechaID FROM Dim_Tiempo WHERE Fecha = TO_DATE('2025-07-11', 'YYYY-MM-DD')), -20, 'Salida');

COMMIT;

-- pruebasss
SELECT
    p.Nombre,
    SUM(fi.CantidadMovimiento) AS Stock_Neto_Actual
FROM
    Fact_Inventario fi
JOIN
    Dim_Producto p ON fi.ProductoID = p.ProductoID
GROUP BY
    p.Nombre
ORDER BY
    Stock_Neto_Actual DESC;

--------- Ejercicio 3 -----------
----Enunciado
/*

Explica cómo se implementa la herencia en Oracle utilizando
tipos de objetos y la cláusula UNDER. Diseña una jerarquía
de tipos para modelar clientes (Cliente → ClientePremium) y
crea un índice en la tabla Clientes para optimizar consultas
por Ciudad. Justifica tu elección.

*/

----Respuesta
/*
La herencia en Oracle se implementa a través de tipos de objeto.
Creas un tipo base (superclase)y luego defines uno o más subtipos (subclases) 
que heredan sus atributos y métodos usando la cláusula UNDER.
Para que un tipo pueda tener descendientes, debe declararse como NOT FINAL.

Los subtipos pueden añadir sus propios atributos y también pueden
sobreescribir los métodos heredados para proporcionar una implementación
especializada, lo que se conoce como polimorfismo.

*/
-- Ejemplo

-- Definición del tipo base
CREATE TYPE Tipo_Cliente AS OBJECT (
    ClienteID NUMBER,
    Nombre VARCHAR2(50),
    Ciudad VARCHAR2(50),
    MEMBER FUNCTION getDescuento RETURN NUMBER
) NOT FINAL; -- Permite que otros tipos hereden de este
/

-- Cuerpo del tipo base con la implementación del método
CREATE TYPE BODY Tipo_Cliente AS
    MEMBER FUNCTION getDescuento RETURN NUMBER IS
    BEGIN
        RETURN 0; -- Los clientes estándar no tienen descuento
    END;
END;
/

-- Definición del subtipo que hereda de Tipo_Cliente
CREATE TYPE Tipo_ClientePremium UNDER Tipo_Cliente (
    DescuentoAdicional NUMBER, -- Atributo propio del subtipo
    OVERRIDING MEMBER FUNCTION getDescuento RETURN NUMBER -- Indica que se sobreescribirá el método
);
/

-- Cuerpo del subtipo con la nueva implementación
CREATE TYPE BODY Tipo_ClientePremium AS
    OVERRIDING MEMBER FUNCTION getDescuento RETURN NUMBER IS
    BEGIN
        RETURN self.DescuentoAdicional; -- Devuelve el descuento específico del cliente premium
    END;
END;
/

CREATE TABLE Clientes OF Tipo_Cliente;

CREATE INDEX idx_clientes_ciudad ON Clientes (Ciudad);

/*
Justificación:
Un índice es una estructura de datos que mejora la velocidad de las
operaciones de consulta en una tabla. El tipo de índice por defecto en Oracle es el
B-Tree, que es ideal para columnas que se usan frecuentemente en cláusulas
WHERE con operadores de igualdad (=) o de rango (BETWEEN, >).

Sin este índice, cualquier consulta que filtre por Ciudad 
(ej. SELECT * FROM Clientes WHERE Ciudad = 'La Serena')
obligaría a la base de datos a realizar un Full Table Scan,
es decir, leer cada una de las filas de la tabla para encontrar las que coinciden.
Con el índice idx_clientes_ciudad, la base de datos puede localizar directamente
las filas correspondientes a una ciudad específica, reduciendo drásticamente
el tiempo de respuesta, especialmente en tablas con un gran número de registros.
*/


--pruebass

DROP TABLE Clientes CASCADE CONSTRAINTS;

CREATE TABLE Clientes OF Tipo_Cliente;

-- Insertar un cliente estándar
INSERT INTO Clientes VALUES (
    Tipo_Cliente(1, 'Ana Rojas', 'La Serena')
);

-- Insertar un cliente premium
INSERT INTO Clientes VALUES (
    Tipo_ClientePremium(2, 'Pedro Lara', 'Coquimbo', 0.15) -- 15% de descuento
);

COMMIT;

-- probar indice
SELECT c.Nombre, c.Ciudad
FROM Clientes c
WHERE c.Ciudad = 'La Serena';

--probar polimorfismo
SELECT c.Nombre, c.getDescuento() AS Descuento
FROM Clientes c;


--------- Ejercicio 4 -----------
----Enunciado
/*
¿? Asumo que es sobre particionamiento de tablas jaja
*/
----Respuesta
/*
La partición es una técnica que consiste en dividir una tabla o un índice grande en
piezas más pequeñas y manejables llamadas particiones. Aunque la tabla se divide
físicamente, para los desarrolladores y usuarios sigue siendo un único objeto lógico.
Esta división se realiza en base a un valor en una o más columnas, conocido como la
clave de partición.

El principal beneficio es la mejora del rendimiento. Cuando una consulta incluye una 
condición sobre la clave de partición (por ejemplo, un rango de fechas), Oracle puede
aplicar un proceso llamado partition pruning (poda de particiones), donde solo lee las
particiones relevantes en lugar de escanear la tabla completa. Además, facilita la
gestión de datos, como archivar o eliminar datos antiguos simplemente manipulando
particiones enteras.
*/
-- Ejemplo

-- Elimina las tablas que dependen de Pedidos y la tabla Pedidos misma
DROP TABLE DetallesPedidos CASCADE CONSTRAINTS;
DROP TABLE Pedidos CASCADE CONSTRAINTS;
DROP TABLE Clientes CASCADE CONSTRAINTS;

CREATE TABLE Clientes OF Tipo_Cliente;
ALTER TABLE Clientes ADD CONSTRAINT pk_clientes PRIMARY KEY (ClienteID);


--Creamos las tablas ya particionadas
CREATE TABLE Pedidos (
    PedidoID        NUMBER CONSTRAINT pk_pedidos PRIMARY KEY,
    ClienteID       NUMBER NOT NULL,
    Total           NUMBER(12,2) DEFAULT 0,
    FechaPedido     DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
)
PARTITION BY RANGE (FechaPedido) (
    PARTITION p_q1_2025 VALUES LESS THAN (TO_DATE('2025-04-01', 'YYYY-MM-DD')),
    PARTITION p_q2_2025 VALUES LESS THAN (TO_DATE('2025-07-01', 'YYYY-MM-DD')),
    PARTITION p_q3_2025 VALUES LESS THAN (TO_DATE('2025-10-01', 'YYYY-MM-DD')),
    PARTITION p_q4_2025 VALUES LESS THAN (MAXVALUE)
);

CREATE INDEX idx_pedidos_cliente_total ON Pedidos (ClienteID, Total);


--pruebass

-- Prerrequisito: Insertar clientes si la tabla está vacía
INSERT INTO Clientes VALUES (Tipo_Cliente(1, 'Julio Cesar', 'Santiago'));
INSERT INTO Clientes VALUES (Tipo_ClientePremium(2, 'Calamin Calamon', 'Calama', 0.10));
INSERT INTO Clientes VALUES (Tipo_Cliente(3, 'Tralalero Tralala', 'Arica'));
COMMIT;


-- Insertar pedidos de ejemplo
BEGIN
    -- Pedido en Q1 2025 (caerá en la partición p_q1_2025)
    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES (101, 1, 75000, TO_DATE('2025-02-15', 'YYYY-MM-DD'));

    -- Pedido en Q2 2025 (caerá en la partición p_q2_2025)
    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES (102, 2, 120000, TO_DATE('2025-05-20', 'YYYY-MM-DD'));

    -- Otro pedido en Q1 2025 para el mismo cliente
    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES (103, 1, 15000, TO_DATE('2025-03-10', 'YYYY-MM-DD'));

    -- Pedido en Q3 2025 (caerá en la partición p_q3_2025)
    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES (104, 3, 89990, TO_DATE('2025-08-01', 'YYYY-MM-DD'));
END;
/

-- Confirmamos los cambios
COMMIT;

SELECT PedidoID, ClienteID, Total, FechaPedido
FROM Pedidos
WHERE FechaPedido >= TO_DATE('2025-01-01', 'YYYY-MM-DD')
  AND FechaPedido <  TO_DATE('2025-04-01', 'YYYY-MM-DD')
  AND ClienteID = 1
  AND Total > 50000;

--------- Ejercicio 5 -----------
----Enunciado
/*
Crea un índice compuesto en DetallesPedidos para PedidoID y
ProductoID. Particiona Pedidos por rango de FechaPedido
(mensual para 2025). Escribe una consulta que sume Total por
ClienteID en enero de 2025.
*/

-- Ejemplo
-- Es necesario dropear las tablas dependientes primero
DROP TABLE DetallesPedidos CASCADE CONSTRAINTS;
DROP TABLE Pedidos CASCADE CONSTRAINTS;

-- Se recrea la tabla Pedidos con la nueva partición mensual
CREATE TABLE Pedidos (
    PedidoID        NUMBER CONSTRAINT pk_pedidos PRIMARY KEY,
    ClienteID       NUMBER NOT NULL,
    Total           NUMBER(12,2) DEFAULT 0,
    FechaPedido     DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_pedidos_cliente FOREIGN KEY (ClienteID) REFERENCES Clientes(ClienteID)
)
PARTITION BY RANGE (FechaPedido) (
    PARTITION p_jan_2025 VALUES LESS THAN (TO_DATE('2025-02-01', 'YYYY-MM-DD')),
    PARTITION p_feb_2025 VALUES LESS THAN (TO_DATE('2025-03-01', 'YYYY-MM-DD')),
    PARTITION p_mar_2025 VALUES LESS THAN (TO_DATE('2025-04-01', 'YYYY-MM-DD')),
    -- (Aquí irían las particiones para los demás meses de 2025)
    PARTITION p_max VALUES LESS THAN (MAXVALUE) -- Partición para el resto
);

--pruebass

CREATE TABLE DetallesPedidos (
    DetalleID       NUMBER CONSTRAINT pk_detallespedidos PRIMARY KEY,
    PedidoID        NUMBER NOT NULL,
    ProductoID      NUMBER NOT NULL,
    Cantidad        NUMBER NOT NULL,
    PrecioUnitario  NUMBER(10,2) NOT NULL,
    CONSTRAINT fk_detalle_pedido FOREIGN KEY (PedidoID) REFERENCES Pedidos(PedidoID),
    CONSTRAINT fk_detalle_producto FOREIGN KEY (ProductoID) REFERENCES Productos(ProductoID),
    CONSTRAINT uk_detalle_pedido_producto UNIQUE (PedidoID, ProductoID)
);

CREATE INDEX idx_detalles_pedido_prod ON DetallesPedidos (PedidoID, ProductoID);

-- (Asegúrate de que los clientes 1 y 2 existan en la tabla Clientes)
INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (201, 1, 50000, TO_DATE('2025-01-10', 'YYYY-MM-DD'));

INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (202, 2, 30000, TO_DATE('2025-01-20', 'YYYY-MM-DD'));

INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (203, 1, 25000, TO_DATE('2025-01-25', 'YYYY-MM-DD'));

-- Pedido de otro mes para verificar que no es incluido
INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
VALUES (204, 1, 10000, TO_DATE('2025-03-05', 'YYYY-MM-DD'));

COMMIT;


SELECT
    ClienteID,
    SUM(Total) AS Total_Mensual
FROM
    Pedidos
WHERE
    FechaPedido BETWEEN TO_DATE('2025-01-01', 'YYYY-MM-DD') AND TO_DATE('2025-01-31', 'YYYY-MM-DD')
GROUP BY
    ClienteID;
