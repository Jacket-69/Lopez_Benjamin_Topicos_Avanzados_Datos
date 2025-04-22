---- 1. Bloque anónimo con cursor explícito y objetos para bases de datos que lista 2 atributos ordenados
-- Crear el tipo de objeto para representar un Producto
CREATE OR REPLACE TYPE t_producto_obj AS OBJECT (
  nombre VARCHAR2(50),
  precio NUMBER
);
/
DECLARE
  -- 1. Declaración del cursor
  CURSOR c_lista_productos_obj IS
    SELECT t_producto_obj(p.Nombre, p.Precio) AS producto_objeto -- Damos un alias a la columna objeto
    FROM Productos p
    ORDER BY p.Nombre;
  -- La variable del bucle (registro_prod) contendrá el objeto.
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Lista de Productos (Objetos con FOR LOOP) ---');
  -- 2. Bucle FOR de cursor
  -- registro_prod será un registro que contiene un campo llamado 'producto_objeto'
  -- y ese campo es de tipo t_producto_obj
  FOR registro_prod IN c_lista_productos_obj LOOP
    -- Accedemos a los atributos a través de la variable del bucle y el alias del objeto
    DBMS_OUTPUT.PUT_LINE('Producto: ' || registro_prod.producto_objeto.nombre || ' - Precio: ' || TO_CHAR(registro_prod.producto_objeto.precio));
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');
END;
/

---- 2. Bloque anónimo con cursor y objeto parametrizado para actualizar valores (+10%):
--Primero creamos un objeto que represente un pedido
CREATE OR REPLACE TYPE t_pedido_obj AS OBJECT (
  pedido_id   NUMBER,
  cliente_id  NUMBER,
  total       NUMBER
);
/

DECLARE
  -- 1. Parámetro de entrada: ID del PEDIDO específico cuyo Total queremos aumentar.
  v_pedido_id_param   Pedidos.PedidoID%TYPE := 101;
  -- 2. Cursor explícito con PARÁMETRO y FOR UPDATE
  --    Selecciona una INSTANCIA DEL OBJETO t_pedido_obj.
  --    IMPORTANTE: FOR UPDATE sigue bloqueando la FILA DE LA TABLA 'Pedidos' subyacente.
  CURSOR c_pedido_obj_a_actualizar (p_pedido_id IN Pedidos.PedidoID%TYPE) IS
    SELECT t_pedido_obj(PedidoID, ClienteID, Total) -- Construye el objeto en el SELECT
    FROM Pedidos
    WHERE PedidoID = p_pedido_id       -- Filtra por el PedidoID
    FOR UPDATE OF Total;               -- Bloquea la fila de la TABLA, con intención de actualizar Total
  -- 3. Variable para almacenar la INSTANCIA DE OBJETO recuperada por el cursor
  v_pedido_obj_actual   t_pedido_obj; -- La variable es del tipo objeto
  -- 4. Variable para el nuevo total calculado (aún necesaria para el UPDATE)
  v_total_nuevo         Pedidos.Total%TYPE;
BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Intentando actualizar Total del Pedido ID: ' || v_pedido_id_param || ' (Usando Objetos) ---');
  -- 5. Abrir el cursor, pasando el PedidoID. La fila de la tabla Pedidos se bloquea.
  OPEN c_pedido_obj_a_actualizar(v_pedido_id_param);
  -- 6. Leer (FETCH) la instancia del OBJETO en la variable objeto.
  FETCH c_pedido_obj_a_actualizar INTO v_pedido_obj_actual;
  -- 7. Verificar si se encontró el objeto (y por tanto, la fila subyacente)
  IF c_pedido_obj_a_actualizar%FOUND THEN
    -- Sí se encontró. Accedemos a los datos a través de los atributos del objeto.
    DBMS_OUTPUT.PUT_LINE('Pedido encontrado. Pertenece al Cliente ID: ' || v_pedido_obj_actual.cliente_id); -- Acceso con punto
    DBMS_OUTPUT.PUT_LINE('--- Valores Originales (desde Objeto) ---');
    DBMS_OUTPUT.PUT_LINE('Pedido ID : ' || v_pedido_obj_actual.pedido_id);   -- Acceso con punto
    DBMS_OUTPUT.PUT_LINE('Total Orig: ' || TO_CHAR(v_pedido_obj_actual.total)); -- Acceso con punto
    -- Calcular el nuevo total usando el atributo del objeto
    v_total_nuevo := v_pedido_obj_actual.total * 1.10;
    -- Mostrar el valor calculado
    DBMS_OUTPUT.PUT_LINE('--- Valores Actualizados ---');
    DBMS_OUTPUT.PUT_LINE('Total Nuevo Calculado: ' || TO_CHAR(v_total_nuevo));
    -- 8. Realizar la ACTUALIZACIÓN en la TABLA 'Pedidos' usando WHERE CURRENT OF.
    --    Aunque leímos un objeto, el cursor mantiene el bloqueo sobre la fila de la tabla,
    --    y es esa fila la que actualizamos.
    UPDATE Pedidos
    SET Total = v_total_nuevo -- Usamos la variable con el valor calculado
    WHERE CURRENT OF c_pedido_obj_a_actualizar; -- Referencia al cursor que bloqueó la fila
    DBMS_OUTPUT.PUT_LINE('Actualización del Total realizada en la tabla Pedidos.');
    -- 9. Confirmar la transacción (guardar cambios y liberar bloqueo)
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transacción confirmada (COMMIT).');
  ELSE
    -- No se encontró un pedido (ni objeto) con el ID proporcionado
    DBMS_OUTPUT.PUT_LINE('ERROR: No se encontró ningún pedido con ID: ' || v_pedido_id_param);
    DBMS_OUTPUT.PUT_LINE('No se realizó ninguna actualización.');
  END IF;
  -- 10. Cerrar el cursor (libera recursos)
  CLOSE c_pedido_obj_a_actualizar;
  DBMS_OUTPUT.PUT_LINE('--- Proceso finalizado ---');
EXCEPTION
  WHEN OTHERS THEN
    -- Manejo básico de errores inesperados
    DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM);
    IF c_pedido_obj_a_actualizar%ISOPEN THEN
      CLOSE c_pedido_obj_a_actualizar;
    END IF;
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Transacción revertida (ROLLBACK) debido a error.');
END;
/