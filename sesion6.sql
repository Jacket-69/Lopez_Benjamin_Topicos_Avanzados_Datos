SET SERVEROUTPUT ON;

-- 1. Bloque anónimo con cursor explícito para listar 2 atributos ordenados
DECLARE
  v_nombre  Clientes.Nombre%TYPE;
  v_ciudad  Clientes.Ciudad%TYPE;

  CURSOR cur_clientes IS
    SELECT Nombre, Ciudad
    FROM Clientes
    ORDER BY Nombre;

BEGIN
  OPEN cur_clientes;
  LOOP
    FETCH cur_clientes INTO v_nombre, v_ciudad;
    EXIT WHEN cur_clientes%NOTFOUND;
    DBMS_OUTPUT.PUT_LINE('Nombre: ' || v_nombre || ', Ciudad: ' || v_ciudad);
  END LOOP;
  CLOSE cur_clientes;
END;
/
-- 2. Bloque anónimo con cursor explícito para aumentar un 10% del total de ventas
DECLARE
  -- Variable para pasar el ID del producto que queremos actualizar
  p_producto_id     Productos.ProductoID%TYPE := 1;

  -- Variables para almacenar los datos del producto
  v_nombre_prod     Productos.Nombre%TYPE;
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

    DBMS_OUTPUT.PUT_LINE('Producto Actualizado: ' || v_nombre_prod || ' (ID: ' || p_producto_id || ')');
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