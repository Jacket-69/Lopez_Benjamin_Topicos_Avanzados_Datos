--1. Bloque anónimo con cursor explícito para listar 2 atributos ordenados:
DECLARE
    CURSOR c_productos IS
        SELECT Nombre, Precio
        FROM Productos
        ORDER BY Precio DESC;
    
    v_nombre Productos.Nombre%TYPE;
    v_precio Productos.Precio%TYPE;
BEGIN
    OPEN c_productos;
    LOOP
        FETCH c_productos INTO v_nombre, v_precio;
        EXIT WHEN c_productos%NOTFOUND;
        
        DBMS_OUTPUT.PUT_LINE('Producto: ' || RPAD(v_nombre, 20) || 
                            ' | Precio: $' || TO_CHAR(v_precio, '999,999'));
    END LOOP;
    CLOSE c_productos;
END;
/
--2. Bloque anónimo con cursor parametrizado para actualizar valores (+10%):

DECLARE
    CURSOR c_pedidos (p_pedido_id Pedidos.PedidoID%TYPE) IS
        SELECT Total
        FROM Pedidos
        WHERE PedidoID = p_pedido_id
        FOR UPDATE OF Total NOWAIT;
    
    v_total_original Pedidos.Total%TYPE;
    v_total_actualizado Pedidos.Total%TYPE;
    v_pedido_id Pedidos.PedidoID%TYPE := 101;
BEGIN
    OPEN c_pedidos(v_pedido_id);
    FETCH c_pedidos INTO v_total_original;
    
    IF c_pedidos%FOUND THEN
        v_total_actualizado := v_total_original * 1.10;
        
        UPDATE Pedidos
        SET Total = v_total_actualizado
        WHERE CURRENT OF c_pedidos;
        
        DBMS_OUTPUT.PUT_LINE('Pedido ID: ' || v_pedido_id);
        DBMS_OUTPUT.PUT_LINE('Total original: $' || TO_CHAR(v_total_original, '999,999'));
        DBMS_OUTPUT.PUT_LINE('Total actualizado: $' || TO_CHAR(v_total_actualizado, '999,999'));
        
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('No existe el pedido ID: ' || v_pedido_id);
    END IF;
    
    CLOSE c_pedidos;
END;
/