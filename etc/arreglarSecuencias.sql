-- Este es un bloque anónimo de PL/SQL para arreglar la secuencia dinámicamente.
DECLARE
    v_max_id NUMBER;
    v_start_with NUMBER;
BEGIN
    -- 1. Obtener el ID máximo actual de la tabla Pedidos.
    --    Se usa NVL para manejar el caso en que la tabla esté vacía.
    SELECT NVL(MAX(PedidoID), 0) INTO v_max_id FROM Pedidos;
    
    -- 2. Calcular el número inicial para la nueva secuencia.
    --    Será el ID máximo encontrado + 1.
    v_start_with := v_max_id + 1;
    
    DBMS_OUTPUT.PUT_LINE('El PedidoID máximo actual es: ' || v_max_id);
    DBMS_OUTPUT.PUT_LINE('La nueva secuencia para Pedidos comenzará en: ' || v_start_with);
    
    -- 3. Borrar la secuencia existente.
    --    Se usa un bloque EXCEPTION para ignorar el error si la secuencia no existe.
    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE seq_Pedidos_PedidoID';
        DBMS_OUTPUT.PUT_LINE('Secuencia seq_Pedidos_PedidoID anterior eliminada.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2289 THEN -- ORA-02289: sequence does not exist
                DBMS_OUTPUT.PUT_LINE('La secuencia seq_Pedidos_PedidoID no existía, se creará una nueva.');
            ELSE
                RAISE;
            END IF;
    END;

    -- 4. Crear la secuencia nueva y sincronizada.
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_Pedidos_PedidoID START WITH ' || v_start_with || ' NOCACHE';
    
    DBMS_OUTPUT.PUT_LINE('Secuencia seq_Pedidos_PedidoID creada/sincronizada correctamente.');

    -- NOTA: Hacemos lo mismo para DetallesPedidos por si acaso tiene el mismo problema.
    SELECT NVL(MAX(DetalleID), 0) INTO v_max_id FROM DetallesPedidos;
    v_start_with := v_max_id + 1;

    DBMS_OUTPUT.PUT_LINE('El DetalleID máximo actual es: ' || v_max_id);
    DBMS_OUTPUT.PUT_LINE('La nueva secuencia para DetallesPedidos comenzará en: ' || v_start_with);

    BEGIN
        EXECUTE IMMEDIATE 'DROP SEQUENCE seq_Detalles_DetalleID';
        DBMS_OUTPUT.PUT_LINE('Secuencia seq_Detalles_DetalleID anterior eliminada.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -2289 THEN
                DBMS_OUTPUT.PUT_LINE('La secuencia seq_Detalles_DetalleID no existía, se creará una nueva.');
            ELSE
                RAISE;
            END IF;
    END;
    
    EXECUTE IMMEDIATE 'CREATE SEQUENCE seq_Detalles_DetalleID START WITH ' || v_start_with || ' NOCACHE';
    DBMS_OUTPUT.PUT_LINE('Secuencia seq_Detalles_DetalleID creada/sincronizada correctamente.');

END;
/

