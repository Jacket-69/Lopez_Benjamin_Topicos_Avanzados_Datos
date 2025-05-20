----------- EJERCICIO 1
-- 1. función calcular_total_con_descuento
CREATE OR REPLACE FUNCTION calcular_total_con_descuento (
    p_pedido_id IN NUMBER
) RETURN NUMBER
AS
    v_total_actual NUMBER;
    v_total_con_descuento NUMBER;
BEGIN
    -- Obtener el total actual del pedido
    SELECT Total
    INTO v_total_actual
    FROM Pedidos
    WHERE PedidoID = p_pedido_id;

    -- Verificar si el total supera 1000 para aplicar descuento
    IF v_total_actual > 1000 THEN
        v_total_con_descuento := v_total_actual * 0.90; -- Aplicar 10% de descuento
    ELSE
        v_total_con_descuento := v_total_actual; -- No se aplica descuento
    END IF;

    RETURN v_total_con_descuento;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Manejar la excepción si el pedido no existe
        RAISE_APPLICATION_ERROR(-20011, 'Pedido con ID ' || p_pedido_id || ' no encontrado en la función.');
        RETURN NULL;
    WHEN OTHERS THEN
        -- Manejar cualquier otra excepción
        RAISE_APPLICATION_ERROR(-20012, 'Error inesperado en la función calcular_total_con_descuento: ' || SQLERRM);
        RETURN NULL;
END calcular_total_con_descuento;
/

-- 2. crear aplicar_descuento_pedido
CREATE OR REPLACE PROCEDURE aplicar_descuento_pedido (
    p_pedido_id IN NUMBER
)
AS
    v_nuevo_total NUMBER;
BEGIN
    -- Calcular el nuevo total usando la función
    v_nuevo_total := calcular_total_con_descuento(p_pedido_id);

    -- IF Si la función devolvió un valor
    IF v_nuevo_total IS NOT NULL THEN
        -- Actualizar el total del pedido en la tabla Pedidos
        UPDATE Pedidos
        SET Total = v_nuevo_total
        WHERE PedidoID = p_pedido_id;

        -- Verificar si la actualización fue exitosa
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Pedido con ID ' || p_pedido_id || ' no encontrado al intentar actualizar.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total del pedido ' || p_pedido_id || ' actualizado a: ' || v_nuevo_total);
            COMMIT;
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('No se pudo calcular el nuevo total para el pedido ' || p_pedido_id || '. No se realizó la actualización.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en el procedimiento aplicar_descuento_pedido: ' || SQLERRM);
        ROLLBACK; -- Revertir cambios en caso de error
END aplicar_descuento_pedido;
/

-- pruebas:

DECLARE
    v_pedido_con_descuento NUMBER := 101;
    v_pedido_sin_descuento NUMBER := 102;
    v_pedido_no_existente NUMBER := 999;
    v_total_original NUMBER;
    v_total_actualizado NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Probando pedido con descuento (' || v_pedido_con_descuento || ') ---');
    -- Primero, verifica el total original
    SELECT Total INTO v_total_original FROM Pedidos WHERE PedidoID = v_pedido_con_descuento;
    DBMS_OUTPUT.PUT_LINE('Total original del pedido ' || v_pedido_con_descuento || ': ' || v_total_original);
    aplicar_descuento_pedido(v_pedido_con_descuento);
    -- Verifica el total actualizado
    SELECT Total INTO v_total_actualizado FROM Pedidos WHERE PedidoID = v_pedido_con_descuento;
    DBMS_OUTPUT.PUT_LINE('Total actualizado del pedido ' || v_pedido_con_descuento || ': ' || v_total_actualizado);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Probando pedido sin descuento (' || v_pedido_sin_descuento || ') ---');
    SELECT Total INTO v_total_original FROM Pedidos WHERE PedidoID = v_pedido_sin_descuento;
    DBMS_OUTPUT.PUT_LINE('Total original del pedido ' || v_pedido_sin_descuento || ': ' || v_total_original);
    aplicar_descuento_pedido(v_pedido_sin_descuento);
    SELECT Total INTO v_total_actualizado FROM Pedidos WHERE PedidoID = v_pedido_sin_descuento;
    DBMS_OUTPUT.PUT_LINE('Total actualizado del pedido ' || v_pedido_sin_descuento || ': ' || v_total_actualizado);


    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Probando pedido no existente (' || v_pedido_no_existente || ') ---');
    aplicar_descuento_pedido(v_pedido_no_existente);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en el bloque anónimo de prueba: ' || SQLERRM);
END;
/

-- Verificar los cambios
SELECT * FROM Pedidos

----------- EJERCICIO 2
CREATE OR REPLACE TRIGGER validar_cantidad_detalle
BEFORE INSERT OR UPDATE ON DetallesPedidos -- se ejecuta antes de insertar o actualizar
FOR EACH ROW -- se ejecuta para cada fila afectada
DECLARE
    -- no use ninguna variable jaja
BEGIN
    -- :NEW es el nuevo valor de la columna que se está insertando o actualizando
    IF :NEW.Cantidad <= 0 THEN
        -- Si la cantidad no es mayor que 0, lanzar un error.
        RAISE_APPLICATION_ERROR(-20021, 'La cantidad del detalle del pedido debe ser mayor que 0. Valor proporcionado: ' || :NEW.Cantidad);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Error inesperado en el trigger validar_cantidad_detalle: ' || SQLERRM);
END validar_cantidad_detalle;
/

--- Ejemplo 1
-- Intento de INSERT con cantidad INVÁLIDA
BEGIN
    INSERT INTO DetallesPedidos (DetalleID, PedidoID, ProductoID, Cantidad)
    VALUES (1, 101, 1, -5);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al insertar ' || SQLERRM);
END;
/
--- Ejemplo 2 
-- Intento de INSERT con cantidad VÁLIDA
BEGIN
    INSERT INTO DetallesPedidos (DetalleID, PedidoID, ProductoID, Cantidad)
    VALUES (3, 101, 2, 10);
    DBMS_OUTPUT.PUT_LINE('Detalle con ID 3 insertado correctamente.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al insertar cantidad 10: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Verificar
SELECT * FROM DetallesPedidos

