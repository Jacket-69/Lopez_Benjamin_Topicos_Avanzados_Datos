----1. Bloque anónimo con cursor explícito para listar 2 atributos ordenados:
DECLARE
-- 1. Declaración del cursor explícito
  CURSOR c_lista_productos IS
    SELECT Nombre, Precio
    FROM Productos
    ORDER BY Nombre;
-- No se necesita declarar variables separadas para v_nombre y v_precio
-- La variable del bucle (registro_producto) las contendrá.
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Lista de Productos (Nombre, Precio) ---');
  -- 2. Bucle FOR de cursor (implícitamente abre, lee y cierra el cursor)
  FOR registro_producto IN c_lista_productos LOOP
    DBMS_OUTPUT.PUT_LINE('Producto: ' || registro_producto.Nombre || ' - Precio: ' || TO_CHAR(registro_producto.Precio));
  END LOOP; -- El bucle termina automáticamente cuando no hay más filas
  DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');
END;
/

----2. Bloque anónimo con cursor parametrizado para actualizar valores (+10%):
DECLARE
  -- 1. Parámetro de entrada: ID del PEDIDO específico cuyo Total queremos aumentar.
  v_pedido_id_param   Pedidos.PedidoID%TYPE := 103;

  -- 2. Cursor explícito con PARÁMETRO (p_pedido_id) y FOR UPDATE
  --    Selecciona el pedido específico para bloquearlo y actualizar su Total.
  CURSOR c_pedido_a_actualizar (p_pedido_id IN Pedidos.PedidoID%TYPE) IS
    SELECT PedidoID, ClienteID, Total -- Seleccionamos columnas relevantes
    FROM Pedidos
    WHERE PedidoID = p_pedido_id       -- Filtramos por el PedidoID del parámetro
    FOR UPDATE OF Total;               -- Bloqueamos la fila, con intención de actualizar Total

  -- 3. Variables para almacenar los datos originales del pedido
  v_pedido_id_orig    Pedidos.PedidoID%TYPE;
  v_cliente_id_orig   Pedidos.ClienteID%TYPE; -- Para mostrar a qué cliente pertenece
  v_total_orig        Pedidos.Total%TYPE;

  -- 4. Variable para el nuevo total calculado
  v_total_nuevo       Pedidos.Total%TYPE;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Intentando actualizar Total del Pedido ID: ' || v_pedido_id_param || ' ---');

  -- 5. Abrir el cursor, pasando el PedidoID. La fila (si existe) se bloquea aquí.
  OPEN c_pedido_a_actualizar(v_pedido_id_param);

  -- 6. Leer (FETCH) los datos de la fila bloqueada en las variables
  FETCH c_pedido_a_actualizar INTO v_pedido_id_orig, v_cliente_id_orig, v_total_orig;

  -- 7. Verificar si se encontró (y bloqueó) la fila del pedido
  IF c_pedido_a_actualizar%FOUND THEN
    -- Sí se encontró, procedemos.
    DBMS_OUTPUT.PUT_LINE('Pedido encontrado. Pertenece al Cliente ID: ' || v_cliente_id_orig);
    DBMS_OUTPUT.PUT_LINE('--- Valores Originales ---');
    DBMS_OUTPUT.PUT_LINE('Pedido ID : ' || v_pedido_id_orig);
    DBMS_OUTPUT.PUT_LINE('Total Orig: ' || TO_CHAR(v_total_orig));

    -- Calcular el nuevo total (aumento del 10%)
    v_total_nuevo := v_total_orig * 1.10;

    -- Mostrar el valor calculado
    DBMS_OUTPUT.PUT_LINE('--- Valores Actualizados ---');
    DBMS_OUTPUT.PUT_LINE('Total Nuevo Calculado: ' || TO_CHAR(v_total_nuevo));

    -- 8. Realizar la ACTUALIZACIÓN usando WHERE CURRENT OF
    --    Actualiza la columna Total de la fila actualmente bloqueada por el cursor.
    UPDATE Pedidos
    SET Total = v_total_nuevo
    WHERE CURRENT OF c_pedido_a_actualizar;

    DBMS_OUTPUT.PUT_LINE('Actualización del Total realizada en la tabla Pedidos.');

    -- 9. Confirmar la transacción (guardar cambios y liberar bloqueo)
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transacción confirmada (COMMIT).');

  ELSE
    -- No se encontró un pedido con el ID proporcionado
    DBMS_OUTPUT.PUT_LINE('ERROR: No se encontró ningún pedido con ID: ' || v_pedido_id_param);
    DBMS_OUTPUT.PUT_LINE('No se realizó ninguna actualización.');
  END IF;

  -- 10. Cerrar el cursor (libera recursos)
  CLOSE c_pedido_a_actualizar;

  DBMS_OUTPUT.PUT_LINE('--- Proceso finalizado ---');

EXCEPTION
  WHEN OTHERS THEN
    -- Manejo básico de errores inesperados
    DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM);
    -- Asegurarse de cerrar el cursor si quedó abierto
    IF c_pedido_a_actualizar%ISOPEN THEN
      CLOSE c_pedido_a_actualizar;
    END IF;
    -- Revertir cualquier cambio pendiente
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Transacción revertida (ROLLBACK) debido a error.');
END;
/