---ESCENARIO 2


-- 1. funcion que determina el nivel del cliente
CREATE OR REPLACE FUNCTION determinar_nivel_cliente (
    p_cliente_id IN Clientes.ClienteID%TYPE
) RETURN VARCHAR2 AS
    v_total_compras Pedidos.Total%TYPE;
BEGIN
    SELECT SUM(Total)
    INTO v_total_compras
    FROM Pedidos
    WHERE ClienteID = p_cliente_id;

    IF NVL(v_total_compras, 0) > 2000 THEN
        RETURN 'Premium';
    ELSIF NVL(v_total_compras, 0) > 1000 THEN
        RETURN 'Regular';
    ELSE
        RETURN 'Básico';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'Básico';
END determinar_nivel_cliente;
/

-- 2. funcion para calcular el total CON descuento 👍

CREATE OR REPLACE FUNCTION calcular_total_con_descuento (
    p_cliente_id IN Clientes.ClienteID%TYPE
) RETURN NUMBER AS
    v_total_actual    Pedidos.Total%TYPE;
    v_nivel_cliente   VARCHAR2(20);
    v_porcentaje_dcto NUMBER;
BEGIN
    SELECT SUM(Total)
    INTO v_total_actual
    FROM Pedidos
    WHERE ClienteID = p_cliente_id;
    
    IF v_total_actual IS NULL OR v_total_actual = 0 THEN
        RETURN 0;
    END IF;

    v_nivel_cliente := determinar_nivel_cliente(p_cliente_id);

    IF v_nivel_cliente = 'Premium' THEN
        v_porcentaje_dcto := 0.15;
    ELSIF v_nivel_cliente = 'Regular' THEN
        v_porcentaje_dcto := 0.05;
    ELSE
        v_porcentaje_dcto := 0;
    END IF;

    RETURN v_total_actual * (1 - v_porcentaje_dcto);
EXCEPTION
    WHEN OTHERS THEN
        RETURN NVL(v_total_actual, 0);
END calcular_total_con_descuento;
/

-- 3. procedimiento para aplicar el descuento

CREATE OR REPLACE PROCEDURE aplicar_descuento_cliente (
    p_cliente_id IN Clientes.ClienteID%TYPE
) AS
    v_total_original      NUMBER;
    v_total_con_descuento NUMBER;
    v_factor_descuento    NUMBER;

    CURSOR c_pedidos_cliente IS
        SELECT PedidoID, Total
        FROM Pedidos
        WHERE ClienteID = p_cliente_id
        FOR UPDATE OF Total;
BEGIN
    SELECT SUM(Total)
    INTO v_total_original
    FROM Pedidos
    WHERE ClienteID = p_cliente_id;
    
    IF NVL(v_total_original, 0) = 0 THEN
        DBMS_OUTPUT.PUT_LINE('El cliente ' || p_cliente_id || ' no tiene pedidos o su total es cero. No se aplica descuento.');
        RETURN;
    END IF;

    v_total_con_descuento := calcular_total_con_descuento(p_cliente_id);

    v_factor_descuento := v_total_con_descuento / v_total_original;
    
    FOR rec_pedido IN c_pedidos_cliente LOOP
        UPDATE Pedidos
        SET Total = rec_pedido.Total * v_factor_descuento
        WHERE CURRENT OF c_pedidos_cliente;
    END LOOP;
    
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END aplicar_descuento_cliente;
/

---pruebassss
--antes del descuento
DECLARE
    v_total_sin_dcto NUMBER;
    v_total_con_dcto NUMBER;
BEGIN
    SELECT SUM(Total) INTO v_total_sin_dcto FROM Pedidos WHERE ClienteID = 1;
    v_total_con_dcto := calcular_total_con_descuento(1);
    DBMS_OUTPUT.PUT_LINE('--- ESTADO INICIAL ---');
    DBMS_OUTPUT.PUT_LINE('Nivel del cliente: ' || determinar_nivel_cliente(1));
    DBMS_OUTPUT.PUT_LINE('Total actual: ' || v_total_sin_dcto);
    DBMS_OUTPUT.PUT_LINE('Total con descuento calculado: ' || v_total_con_dcto);
END;
/
--despues del descuento

BEGIN
    aplicar_descuento_cliente(p_cliente_id => 1);
END;
/

DECLARE
    v_total_final NUMBER;
BEGIN
    SELECT SUM(Total) INTO v_total_final FROM Pedidos WHERE ClienteID = 1;
    DBMS_OUTPUT.PUT_LINE('--- ESTADO FINAL ---');
    DBMS_OUTPUT.PUT_LINE('Total final de los pedidos del cliente: ' || v_total_final);
END;
/


