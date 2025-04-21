CREATE OR REPLACE PROCEDURE aumentar_precio_producto(
  p_producto_id IN NUMBER) AS 

  DECLARE
  -- Variables para almacenar los datos del producto
  v_precio_original Productos.Precio%TYPE;
  v_precio_nuevo    Productos.Precio%TYPE;

  CURSOR cur_producto (cp_prod_id Productos.ProductoID%TYPE) IS
    SELECT Nombre, Precio
    FROM Productos
    WHERE ProductoID = cp_prod_id
    FOR UPDATE OF Precio;

BEGIN
  OPEN cur_producto(p_producto_id);
  FETCH cur_producto INTO v_nombre_prod, v_precio_original;
  IF cur_producto%FOUND THEN
    v_precio_nuevo := v_precio_original * 1.10;
    UPDATE Productos
    SET Precio = v_precio_nuevo
    WHERE CURRENT OF cur_producto;
    DBMS_OUTPUT.PUT_LINE('Precio Original   : ' || TO_CHAR(v_precio_original));
    DBMS_OUTPUT.PUT_LINE('Precio Nuevo (10%): ' || TO_CHAR(v_precio_nuevo));

    COMMIT;

  ELSE
    DBMS_OUTPUT.PUT_LINE('Producto con ID ' || p_producto_id || ' no encontrado.');
  END IF;

  CLOSE cur_producto;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Ocurrió un error: ' || SQLERRM);
    ROLLBACK;
    IF cur_producto%ISOPEN THEN
      CLOSE cur_producto;
    END IF;
END;
/

-- 1. Procedimiento Almacenado para aumentar el precio de un producto por un numero.
CREATE OR REPLACE PROCEDURE aumentar_precio_producto(
  p_producto_id IN NUMBER, p_aumento IN NUMBER) AS 
  BEGIN
    UPDATE Productos
    SET Precio = Precio * p_aumento
    WHERE ProductoID = p_producto_id;
    IF SQL%ROWCOUNT = 0 THEN
      RAISE_APPLICATION_ERROR(-20001, 'Producto con ID ' || p_producto_id || ' no encontrado.');
    END IF;
  DBMS_OUTPUT.PUT_LINE('Precio del producto ' || p_producto_id || ' actualizado');
  COMMIT;
  EXCEPTION
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Error: El precio debe ser un valor válido.');
  WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/
EXEC actualizar_precio_producto(1, 1.10);
EXEC actualizar_precio_producto(999, 1.10);

-- 2. Procedimiento Almacenado para contar la cantidad de pedidos por cliente.
CREATE OR REPLACE PROCEDURE  contar_pedidos_cliente(
  p_cliente_id IN NUMBER, p_total_pedidos OUT NUMBER) AS 
  BEGIN
    SELECT COUNT(ClienteID) INTO p_total_pedidos 
    FROM Pedidos
    WHERE ClienteID = p_cliente_id;
    IF p_total_pedidos IS NULL THEN
      p_total_pedidos := 0;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('Cliente con ID ' || p_cliente_id || ' no encontrado.');
END;
/  
-- Ejecutar el procedimiento
DECLARE
  p_total_pedidos NUMBER;
BEGIN
  contar_pedidos_cliente(999, p_total_pedidos);
  DBMS_OUTPUT.PUT_LINE('Total de pedidos del cliente: ' || p_total_pedidos);
END;
/