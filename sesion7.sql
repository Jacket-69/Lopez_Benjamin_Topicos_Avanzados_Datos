---- 1. Procedimiento Almacenado para aumentar el precio de un producto por un numero.
CREATE OR REPLACE PROCEDURE aumentar_precio_producto (
   -- Parámetros de ENTRADA
   p_producto_id   IN Productos.ProductoID%TYPE,
   p_porcentaje    IN NUMBER
)
AS
  -- No necesitamos variables locales adicionales para esta lógica específica,
  -- pero podrían declararse aquí si fueran necesarias.
BEGIN
  -- Asegurarse de que el porcentaje no sea nulo o negativo.
  IF p_porcentaje IS NULL OR p_porcentaje < 0 THEN
    -- Lanzamos un error personalizado si el porcentaje es inválido.
    RAISE_APPLICATION_ERROR(-20001, 'El porcentaje de aumento (' || p_porcentaje || ') no puede ser nulo o negativo.');
  END IF;
  -- Se actualiza el precio del producto sumándole el porcentaje indicado.
    UPDATE Productos
    SET Precio = Precio * (1 + p_porcentaje / 100)
    WHERE ProductoID = p_producto_id; -- Solo para el producto especificado

  -- **Manejo de Excepción/Validación (Producto No Existe):**

    IF SQL%NOTFOUND THEN -- TRUE si el UPDATE no afectó a ninguna fila.
    -- Lanzamos un error personalizado indicando que el producto no fue encontrado.
      RAISE_APPLICATION_ERROR(-20002, 'El producto con ID ' || p_producto_id || ' no existe. No se pudo actualizar el precio.');
    ELSE
      DBMS_OUTPUT.PUT_LINE('Precio del producto ID ' || p_producto_id || ' aumentado en un ' || p_porcentaje || '%.');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Error inesperado al actualizar producto ID ' || p_producto_id || ': ' || SQLCODE || ' - ' || SQLERRM);
      RAISE;
  END aumentar_precio_producto;
/

-- Si llamamos al procedimiento:
BEGIN
  aumentar_precio_producto(p_producto_id => 1, p_porcentaje => 15);
  -- Como el procedimiento no hace COMMIT, hay que hacerlo aquí para guardar:
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error al llamar al procedimiento: ' || SQLERRM);
        -- Si hubo un error, deshacemos.
    ROLLBACK;
END;
/


---- 2. Procedimiento Almacenado para contar la cantidad de pedidos por cliente.
CREATE OR REPLACE PROCEDURE contar_pedidos_cliente (
   -- Parámetro de ENTRADA: El ID del cliente a consultar
   p_cliente_id        IN  Clientes.ClienteID%TYPE,
   -- Parámetro de SALIDA: Variable que contendrá el número de pedidos encontrados
   p_cantidad_pedidos  OUT NUMBER
)
AS 
  -- Variable local para verificar si el cliente existe
  v_cliente_existe    NUMBER := 0;
BEGIN
  -- Verificamos si el cliente existe
    SELECT COUNT(*)
    INTO v_cliente_existe
    FROM Clientes             -- Consultamos AHORA la tabla Clientes
    WHERE ClienteID = p_cliente_id;

  -- Si el cliente NO existe, lanzar un error
  IF v_cliente_existe = 0 THEN
    RAISE_APPLICATION_ERROR(-20003, 'El cliente con ID ' || p_cliente_id || ' NO EXISTE en la tabla Clientes.');
    -- La ejecución del procedimiento se detiene aquí si se lanza el error.
  END IF;
  -- Si el cliente SÍ existe, contar sus pedidos
    SELECT COUNT(*) 
    INTO p_cantidad_pedidos --Asigna el resultado del COUNT a la variable de salida
    FROM Pedidos
    WHERE ClienteID = p_cliente_id;

    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado al contar pedidos para Cliente ID ' || p_cliente_id || ': ' || SQLCODE || ' - ' || SQLERRM);
        p_cantidad_pedidos := NULL;
        RAISE;

END contar_pedidos_cliente;
/
--- Llamamos al procedimiento 
DECLARE
  v_id_cliente    Clientes.ClienteID%TYPE := 1;
  v_total_pedidos NUMBER;                      -- Variable local para RECIBIR el valor OUT
BEGIN
  -- Llamar al procedimiento pasando ambas variables
  contar_pedidos_cliente(
      p_cliente_id       => v_id_cliente,      -- Pasamos el ID del cliente (IN)
      p_cantidad_pedidos => v_total_pedidos  -- Pasamos la variable donde se guardará el resultado (OUT)
  );

  -- Después de la llamada, v_total_pedidos contendrá el valor calculado por el procedimiento.
  IF v_total_pedidos IS NULL THEN
    DBMS_OUTPUT.PUT_LINE('No se pudo obtener la cantidad de pedidos debido a un error.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('El cliente con ID ' || v_id_cliente || ' tiene ' || v_total_pedidos || ' pedido(s).');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error al ejecutar el bloque de llamada: ' || SQLERRM);
END;
/


