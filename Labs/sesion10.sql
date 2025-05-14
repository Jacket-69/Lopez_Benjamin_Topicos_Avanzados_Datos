--Parte 1
CREATE OR REPLACE PROCEDURE actualizar_total_pedidos (
    p_ClienteID          IN Clientes.ClienteID%TYPE,
    p_porcentaje_aumento IN NUMBER DEFAULT 10
)
IS
    v_nuevo_total Pedidos.Total%TYPE;
    v_factor_aumento NUMBER;

    CURSOR c_pedidos_cliente IS
        SELECT PedidoID, Total
        FROM Pedidos
        WHERE ClienteID = p_ClienteID
        FOR UPDATE OF Total;
BEGIN
    IF p_porcentaje_aumento < 0 THEN
        DBMS_OUTPUT.PUT_LINE('Error: El porcentaje de aumento no puede ser negativo.');
        RETURN;
    END IF;

    v_factor_aumento := 1 + (p_porcentaje_aumento / 100);

    FOR pedido_rec IN c_pedidos_cliente LOOP
        v_nuevo_total := pedido_rec.Total * v_factor_aumento;

        UPDATE Pedidos
        SET Total = v_nuevo_total
        WHERE CURRENT OF c_pedidos_cliente;

        DBMS_OUTPUT.PUT_LINE('PedidoID ' || pedido_rec.PedidoID || ' actualizado. Total anterior: ' || pedido_rec.Total || ', Nuevo Total: ' || v_nuevo_total);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Actualización de totales completada para ClienteID: ' || p_ClienteID || ' con un aumento del ' || p_porcentaje_aumento || '%.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al actualizar los totales de los pedidos para el ClienteID ' || p_ClienteID || ': ' || SQLERRM);
END actualizar_total_pedidos;
/


-- Ejemplo 1: Aumentar un 10%
BEGIN
    actualizar_total_pedidos(p_ClienteID => 1);
END;
/

-- Ejemplo 2: Aumentar un 15.5%
BEGIN
    actualizar_total_pedidos(p_ClienteID => 1, p_porcentaje_aumento => 15.5);
END;
 /

 --Parte 2

 CREATE OR REPLACE PROCEDURE calcular_costo_detalle (
    p_DetalleID   IN  DetallesPedidos.DetalleID%TYPE,
    p_costo_total OUT NUMBER
)
IS
    v_cantidad      DetallesPedidos.Cantidad%TYPE;
    v_precio        Productos.Precio%TYPE;
    v_producto_id   DetallesPedidos.ProductoID%TYPE;

    detalle_no_encontrado EXCEPTION;
    PRAGMA EXCEPTION_INIT(detalle_no_encontrado, -20002);

BEGIN
    p_costo_total := NULL;

    BEGIN
        SELECT dp.Cantidad, dp.ProductoID
        INTO v_cantidad, v_producto_id
        FROM DetallesPedidos dp
        WHERE dp.DetalleID = p_DetalleID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: DetalleID ' || p_DetalleID || ' no encontrado en la tabla DetallesPedidos.');
            RAISE detalle_no_encontrado;
    END;

    BEGIN
        SELECT pr.Precio
        INTO v_precio
        FROM Productos pr
        WHERE pr.ProductoID = v_producto_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: ProductoID ' || v_producto_id || ' (asociado al DetalleID ' || p_DetalleID || ') no encontrado en la tabla Productos.');
            RAISE detalle_no_encontrado;
    END;

    p_costo_total := v_cantidad * v_precio;

    DBMS_OUTPUT.PUT_LINE('Costo calculado para DetalleID ' || p_DetalleID || ': ' || p_costo_total);

EXCEPTION
    WHEN detalle_no_encontrado THEN
        p_costo_total := NULL;
        DBMS_OUTPUT.PUT_LINE('El cálculo del costo no pudo completarse debido a que el detalle o producto no fue encontrado.');
    WHEN OTHERS THEN
        p_costo_total := NULL;
        DBMS_OUTPUT.PUT_LINE('Error inesperado al calcular el costo para DetalleID ' || p_DetalleID || ': ' || SQLERRM);
END calcular_costo_detalle;
/

-- Ejemplo 1:
 DECLARE
     v_id_detalle DetallesPedidos.DetalleID%TYPE := 1;
     v_costo_calculado NUMBER;
 BEGIN
     calcular_costo_detalle(p_DetalleID => v_id_detalle, p_costo_total => v_costo_calculado);

     IF v_costo_calculado IS NOT NULL THEN
         DBMS_OUTPUT.PUT_LINE('El costo total para el DetalleID ' || v_id_detalle || ' es: ' || v_costo_calculado);
     ELSE
         DBMS_OUTPUT.PUT_LINE('No se pudo calcular el costo para el DetalleID ' || v_id_detalle || '. Verifique los mensajes de error.');
     END IF;
END;
/

-- Ejemplo 2:
 DECLARE
     v_id_detalle_inexistente DetallesPedidos.DetalleID%TYPE := 99999;
     v_costo_calculado NUMBER;
 BEGIN
     calcular_costo_detalle(p_DetalleID => v_id_detalle_inexistente, p_costo_total => v_costo_calculado);

     IF v_costo_calculado IS NOT NULL THEN
         DBMS_OUTPUT.PUT_LINE('El costo total para el DetalleID ' || v_id_detalle_inexistente || ' es: ' || v_costo_calculado);
     ELSE
         DBMS_OUTPUT.PUT_LINE('No se pudo calcular el costo para el DetalleID ' || v_id_detalle_inexistente || '.');
     END IF;
 END;
/