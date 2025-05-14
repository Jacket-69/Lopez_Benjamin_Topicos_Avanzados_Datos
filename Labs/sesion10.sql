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


-- Ejemplo 1: Aumentar un 10% (usando el valor por defecto)
BEGIN
    actualizar_total_pedidos(p_ClienteID => 1);
END;
/

-- Ejemplo 2: Aumentar un 15.5%
BEGIN
    actualizar_total_pedidos(p_ClienteID => 1, p_porcentaje_aumento => 15.5);
END;
 /