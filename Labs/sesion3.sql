--Escribe un bloque anónimo que calcule el total de alguna entidad y lo clasifique en 3 categorías: Alto, Medio o Bajo
DECLARE
	v_total_pedidos NUMBER;
	v_cliente_id NUMBER := 1;
BEGIN
	SELECT SUM(Total) INTO V_total_pedidos
	FROM Pedidos
	WHERE ClienteID = v_cliente_id;
--El valor del pedido es mayor a 1000 es grande
IF v_total_pedidos > 1000 THEN
 DBMS_OUTPUT.PUT_LINE('Pedido grande: ' || v_total_pedidos);
--El valor del pedido es mayor a 500 es mediano
ELSIF v_total_pedidos > 500 THEN
 DBMS_OUTPUT.PUT_LINE('Pedido mediano: ' || v_total_pedidos);
ELSE
--El valor del pedido es pequeño en cualquier otro caso
 DBMS_OUTPUT.PUT_LINE('Pedido pequeño: ' || v_total_pedidos);
END IF;
END;
/