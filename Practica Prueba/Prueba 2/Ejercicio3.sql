---EJERCICIO 1
CREATE OR REPLACE FUNCTION precio_promedio_por_pedido (
    p_producto_id IN Productos.ProductoID%TYPE
) RETURN NUMBER AS
    v_promedio NUMBER;
BEGIN
    SELECT AVG(total_detalle)
    INTO v_promedio
    FROM (
        SELECT dp.PedidoID, (dp.PrecioUnitario * dp.Cantidad) AS total_detalle
        FROM DetallesPedidos dp
        WHERE dp.ProductoID = p_producto_id
    );

    RETURN NVL(v_promedio, 0);
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END precio_promedio_por_pedido;
/

CREATE OR REPLACE PROCEDURE actualizar_precios_por_categoria (
    p_porcentaje_aumento IN NUMBER
) AS
    CURSOR c_productos IS
        SELECT ProductoID, Nombre, Precio
        FROM Productos;

    v_precio_promedio NUMBER;
    v_aumento_invalido EXCEPTION;
    v_productos_actualizados NUMBER := 0;

BEGIN
    IF p_porcentaje_aumento IS NULL OR p_porcentaje_aumento <= 0 THEN
        RAISE v_aumento_invalido;
    END IF;

    FOR rec_producto IN c_productos LOOP
        v_precio_promedio := precio_promedio_por_pedido(rec_producto.ProductoID);

        IF v_precio_promedio > 500 THEN
            UPDATE Productos
            SET Precio = ROUND(rec_producto.Precio * (1 + (p_porcentaje_aumento / 100)), 2)
            WHERE ProductoID = rec_producto.ProductoID;
            
            v_productos_actualizados := v_productos_actualizados + 1;
        END IF;
    END LOOP;

    IF v_productos_actualizados > 0 THEN
        COMMIT;
    END IF;

EXCEPTION
    WHEN v_aumento_invalido THEN
        DBMS_OUTPUT.PUT_LINE('Error: El porcentaje de aumento debe ser un número positivo.');
        ROLLBACK;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado en el procedimiento: ' || SQLERRM);
        ROLLBACK;
END actualizar_precios_por_categoria;
/

---pruebasss

--valores iniciales

SELECT ProductoID, Nombre, Precio FROM Productos WHERE ProductoID = 1;

--inflación afecta a la empanada de pino

DECLARE
    v_porcentaje NUMBER := 10;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Ejecutando prueba de actualización de precios ---');
    actualizar_precios_por_categoria(p_porcentaje_aumento => v_porcentaje);
END;
/

--valores finales
SELECT ProductoID, Nombre, Precio FROM Productos WHERE ProductoID = 1;