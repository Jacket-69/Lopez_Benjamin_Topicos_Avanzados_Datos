-----------PARTE 1
/*

1.-
Procedimiento Almacenado:
Es un bloque de codigo PL/SQL para 
realizar multiples operaciones
en un mismo procedimiento.
Utiliza IN, OUT y IN OUT para operar.
IN: Recibe un valor pero no lo modifica perse.
OUT: Devuelve un valor que se trabaja.
IN OUT: Recibe un valor, lo modifica y lo devuelve.
Trabaja con transacciones, y se confirman utilizando
COMMIT y si hay errores con ROLLBACK.
Tambien se puden hacer operaciones de INSERT, UPDATE
y DELETE.
Lo usaria cuando tengo que hacer varias operaciones
y modificar la BD con transacciones.
En la BD de la prueba, lo usaria para aplicar descuentos
globalmente, quiza por una fecha navideña, o por otro lado
si divido a los clientes en base a compras previas, asignarles
un descuento a los que mas han comprado.

Funcion Almacenada:
Tambien es un bloque de codigo PL/SQL pero
realiza operaciones que retornan un unico valor.
Utiliza RETURN para devolver el valor que tiene que ser
definido en la cabecera.
No se pueden hacer operaciones de INSERT, UPDATE
y DELETE. Empero, se pueden utilizar las funciones
con SELECT * tipo_de_dato.
Lo usaria cuando tengo que trabajar un valor(es)
de una tabla(s) buscandolo con un SELECT y utilizar
el valor que retorna para una u otras operaciones.
En la BD de la prueba si es que quiero asignarle un nivel
a cada producto dependiendo del precio, si es <=150000
es un producto 'Articulo Caro' pero si es >=80000 seria un
producto 'Articulo Barato'. Esto retorna, cuando se llame a la funcion
un 'nivel'.
-------------------------------
2.- 
Utilizaria IN OUT cuando necesite trabajar un valor dentro
de un procedimiento, quiza haciendo algun INSERT, UPDATE
o incluso DELETE, y necesite que devuelva el resultado.
*/
--Ejemplo
CREATE OR REPLACE PROCEDURE cantidad_Inventario (
	p_InventarioID IN Inventario.InventarioID%TYPE,
	p_cantidad_total OUT NUMBER
	
)
IS
	v_cantidad 		Inventario.Cantidad%TYPE;
	v_inventario_id 	Inventario.InventarioID%TYPE;

BEGIN
	p_cantidad_total := NULL;

	BEGIN 
	SELECT i.Cantidad, i.InventarioID
	INTO v_cantidad, v_inventario_id
	FROM Inventario i
	WHERE i.InventarioID = p_InventarioID;
END;

p_cantidad_total := v_cantidad - 1;
DBMS_OUTPUT.PUT_LINE('Cantidad Actualizada del Producto' || p_InventarioID || ': ' || p_cantidad_total);


END cantidad_Inventario;
/
--------------------------------------
/*
3.-
La funcion almacenada dentro de una consulta podria ser utilizada asi:
SELECT tipo_de_dato FROM dato
WHERE tipo_de_dato = x;
funcion_almacenada := y;

DBMS_OUTPUT.PUT_LINE('--- la funcion almacenada dio como resultado: ' || funcion_almacenada);
*/

CREATE OR REPLACE FUNCTION valor_total_producto_inventario(
	p_producto_id IN Productos.ProductoID%TYPE
) 
RETURN NUMBER 
IS
	v_precio_inventario Productos.Precio%TYPE;
	v_cantidad_inventario Inventario.Cantidad%TYPE;
	v_total_inventario NUMBER;
BEGIN
	SELECT Inventario.Cantidad 
	INTO v_cantidad_inventario
	FROM Inventario
	WHERE Inventario.ProductoID = p_producto_id;

	SELECT Productos.Precio 
	INTO v_precio_inventario
	FROM Productos
	WHERE Productos.ProductoID = p_producto_id;

	v_total_inventario := (v_precio_inventario * v_cantidad_inventario);

	RETURN v_total_inventario;
END valor_total_producto_inventario;
/

SELECT Productos.Nombre, valor_total_producto_inventario(ProductoID) AS Total
FROM Productos
WHERE ProductoID = 101;
----------------------------------------

/*
4.-
Un trigger funciona cuando ocurren ciertos eventos
dentro de una BD, ya sea un INSERT, UPDATE o DELETE.
Cuando ocurre uno de estos eventos el trigger
hace una acción en concreto dependiendo el evento que haya ocurrido.
Es invisible para el usuario y funciona dentro de la BD.
Por ejemplo si se hace INSERT de un producto puede haber un trigger que
lo inserte tambien a una DWH. Se utiliza  en auditoria,
cada vez que se hace DELETE de algo, se suma a la tabla de Auditoria mediante
triggers.

*/

CREATE OR REPLACE TRIGGER trg_actualizar_movimientos
AFTER INSERT ON Movimientos
FOR EACH ROW
DECLARE
BEGIN
	UPDATE Inventario
	SET Cantidad = NVL(Cantidad, 0) + (:NEW.Cantidad)
	WHERE ProductoID = :NEW.ProductoID;
END trg_actualizar_movimientos;
/

INSERT INTO Movimientos VALUES (11, 101, 'Entrada', 10, SYSDATE);
SELECT * FROM Movimientos;


----------------------PARTE 2

-- 1.-
CREATE OR REPLACE PROCEDURE registrar_movimiento (
    p_productoid    IN NUMBER,
    p_tipomovimiento IN VARCHAR2,
    p_cantidad      IN NUMBER
) IS
    v_cantidad_actual   NUMBER;
    v_producto_count    NUMBER;
    e_stock_insuficiente EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_producto_count FROM Productos WHERE ProductoID = p_productoid;

    IF v_producto_count = 0 THEN
        RAISE NO_DATA_FOUND;
    END IF;

    INSERT INTO Movimientos (
        MovimientoID,
        ProductoID,
        TipoMovimiento,
        Cantidad,
        FechaMovimiento
    ) VALUES (
        (SELECT NVL(MAX(MovimientoID), 0) + 1 FROM Movimientos),
        p_productoid,
        p_tipomovimiento,
        p_cantidad,
        SYSDATE
    );

    SELECT Cantidad INTO v_cantidad_actual FROM Inventario WHERE ProductoID = p_productoid;

    IF p_tipomovimiento = 'Entrada' THEN
        UPDATE Inventario
        SET
            Cantidad = Cantidad + p_cantidad,
            FechaActualizacion = SYSDATE
        WHERE
            ProductoID = p_productoid;
    ELSIF p_tipomovimiento = 'Salida' THEN
        IF v_cantidad_actual - p_cantidad < 0 THEN
            RAISE e_stock_insuficiente;
        END IF;
        UPDATE Inventario
        SET
            Cantidad = Cantidad - p_cantidad,
            FechaActualizacion = SYSDATE
        WHERE
            ProductoID = p_productoid;
    END IF;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: El producto con ID ' || p_productoid || ' no existe.');
        ROLLBACK;
    WHEN e_stock_insuficiente THEN
        DBMS_OUTPUT.PUT_LINE('Error: Stock insuficiente para el producto con ID ' || p_productoid);
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado😵‍💫: ' || SQLERRM);
        ROLLBACK;
END;
/

BEGIN registrar_movimiento()



-- 2.-
CREATE OR REPLACE FUNCTION calcular_valor_inventario_proveedor (
    p_proveedorid IN NUMBER
) RETURN NUMBER IS
    v_valor_total NUMBER := 0;
BEGIN
    SELECT
        SUM(p.Precio * i.Cantidad)
    INTO v_valor_total
    FROM
        Productos p
        JOIN Inventario i ON p.ProductoID = i.ProductoID
    WHERE
        p.ProveedorID = p_proveedorid;

    RETURN NVL(v_valor_total, 0);
END;
/

CREATE OR REPLACE PROCEDURE mostrar_valor_proveedor
IS
    CURSOR c_proveedores IS SELECT ProveedorID, Nombre FROM Proveedores;
    v_proveedor_id   Proveedores.ProveedorID%TYPE;
    v_proveedor_nombre Proveedores.Nombre%TYPE;
    v_valor_inventario NUMBER;

BEGIN
	DBMS_OUTPUT.PUT_LINE('--- VALOR TOTAL DEL INVENTARIO 🐸---');
    OPEN c_proveedores;
    LOOP
    	FETCH c_proveedores INTO v_proveedor_id, v_proveedor_nombre;
    	EXIT WHEN c_proveedores%NOTFOUND;

    	v_valor_inventario := calcular_valor_inventario_proveedor(v_proveedor_id);
		DBMS_OUTPUT.PUT_LINE('Proveedor: ' || v_proveedor_nombre || ' - Valor Total: $' || v_valor_inventario);
	END LOOP;
	CLOSE c_proveedores;
END;
/

-- 3.-
-- tabla de auditoría.
CREATE TABLE AuditoriaMovimientos (
    AuditoriaID     NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    MovimientoID    NUMBER,
    ProductoID      NUMBER,
    TipoMovimiento  VARCHAR2(10),
    Cantidad        NUMBER,
    Accion          VARCHAR2(10),
    Fecha           DATE
);
/

CREATE OR REPLACE TRIGGER auditar_movimientos
AFTER INSERT OR DELETE ON Movimientos
FOR EACH ROW
DECLARE
    v_accion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_accion := 'INSERT';
        INSERT INTO AuditoriaMovimientos (MovimientoID, ProductoID, TipoMovimiento, Cantidad, Accion, Fecha)
        VALUES (:NEW.MovimientoID, :NEW.ProductoID, :NEW.TipoMovimiento, :NEW.Cantidad, v_accion, SYSDATE);
    ELSIF DELETING THEN
        v_accion := 'DELETE';
        INSERT INTO AuditoriaMovimientos (MovimientoID, ProductoID, TipoMovimiento, Cantidad, Accion, Fecha)
        VALUES (:OLD.MovimientoID, :OLD.ProductoID, :OLD.TipoMovimiento, :OLD.Cantidad, v_accion, SYSDATE);
    END IF;
END;
/

SELECT * FROM AuditoriaMovimientos;
SELECT * FROM Movimientos;

INSERT INTO Movimientos VALUES (12, 101, 'Entrada', 10, SYSDATE);
INSERT INTO Movimientos VALUES (13, 102, 'Salida', 10, SYSDATE);




