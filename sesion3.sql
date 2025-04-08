--Escribe un bloque anónimo que calcule el total de alguna entidad y lo clasifique en 3 categorías: Alto, Medio o Bajo
DECLARE
v_total NUMBER := 600;
BEGIN
IF v_total > 1000 THEN
 DBMS_OUTPUT.PUT_LINE('Pedido grande: ' || v_total);
ELSIF v_total > 500 THEN
 DBMS_OUTPUT.PUT_LINE('Pedido mediano: ' || v_total);
ELSE
 DBMS_OUTPUT.PUT_LINE('Pedido pequeño: ' || v_total);
END IF;
END;
/