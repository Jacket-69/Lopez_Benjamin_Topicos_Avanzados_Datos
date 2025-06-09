------ ESCENARIO 1

CREATE OR REPLACE TRIGGER trg_actualizar_total_pedido
AFTER INSERT ON DetallesPedidos
FOR EACH ROW
BEGIN
    UPDATE Pedidos
    SET Total = NVL(Total, 0) + (:NEW.Cantidad * :NEW.PrecioUnitario)
    WHERE PedidoID = :NEW.PedidoID;
EXCEPTION
    WHEN OTHERS THEN
        RAISE;
END trg_actualizar_total_pedido;
/

CREATE OR REPLACE PROCEDURE proc_crear_pedido_con_detalle (
    p_cliente_id     IN Pedidos.ClienteID%TYPE,
    p_producto_id    IN DetallesPedidos.ProductoID%TYPE,
    p_cantidad       IN DetallesPedidos.Cantidad%TYPE,
    p_precio_unitario IN DetallesPedidos.PrecioUnitario%TYPE,
    p_nuevo_pedido_id  OUT Pedidos.PedidoID%TYPE,
    p_nuevo_detalle_id OUT DetallesPedidos.DetalleID%TYPE
) AS
    v_pedido_id_generado  Pedidos.PedidoID%TYPE;
    v_detalle_id_generado DetallesPedidos.DetalleID%TYPE;
BEGIN
    v_pedido_id_generado  := seq_Pedidos_PedidoID.NEXTVAL;
    v_detalle_id_generado := seq_Detalles_DetalleID.NEXTVAL;

    INSERT INTO Pedidos (PedidoID, ClienteID, Total, FechaPedido)
    VALUES (v_pedido_id_generado, p_cliente_id, 0, SYSDATE);

    INSERT INTO DetallesPedidos (DetalleID, PedidoID, ProductoID, Cantidad, PrecioUnitario)
    VALUES (v_detalle_id_generado, v_pedido_id_generado, p_producto_id, p_cantidad, p_precio_unitario);

    p_nuevo_pedido_id  := v_pedido_id_generado;
    p_nuevo_detalle_id := v_detalle_id_generado;

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Pedido ' || p_nuevo_pedido_id || ' y detalle ' || p_nuevo_detalle_id || ' creados exitosamente.');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error al crear pedido con detalle: ' || SQLERRM || '. Se ha realizado un ROLLBACK.');
        RAISE;
END proc_crear_pedido_con_detalle;
/

--pruebasss

SET SERVEROUTPUT ON;

DECLARE
    v_cliente_id_prueba CONSTANT NUMBER := 1;
    v_producto_id_prueba CONSTANT NUMBER := 1;
    v_precio_prueba     CONSTANT NUMBER := 1200;
    v_cantidad_prueba   CONSTANT NUMBER := 2;

    v_id_pedido_creado  Pedidos.PedidoID%TYPE;
    v_id_detalle_creado DetallesPedidos.DetalleID%TYPE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Ejecutando prueba de creación de pedido ---');
    proc_crear_pedido_con_detalle(
        p_cliente_id     => v_cliente_id_prueba,
        p_producto_id    => v_producto_id_prueba,
        p_cantidad       => v_cantidad_prueba,
        p_precio_unitario => v_precio_prueba,
        p_nuevo_pedido_id  => v_id_pedido_creado,
        p_nuevo_detalle_id => v_id_detalle_creado
    );
    DBMS_OUTPUT.PUT_LINE('Procedimiento ejecutado. Pedido creado con ID: ' || v_id_pedido_creado || ' y Detalle ID: ' || v_id_detalle_creado);
    
    FOR rec IN (SELECT * FROM Pedidos WHERE PedidoID = v_id_pedido_creado) LOOP
        DBMS_OUTPUT.PUT_LINE('Verificación en Pedidos -> ID: ' || rec.PedidoID || ', Total: ' || rec.Total);
    END LOOP;

END;
/

