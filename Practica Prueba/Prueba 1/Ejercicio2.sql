DECLARE
  v_precio_limite NUMBER := 1000;
  v_porcentaje_aumento NUMBER := 15;

  CURSOR c_productos_a_actualizar IS
    SELECT ProductoID, Nombre, Precio
    FROM Productos
    WHERE Precio < v_precio_limite
    FOR UPDATE OF Precio;

  v_filas_actualizadas NUMBER := 0;

  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Iniciando aumento de precios (15%) para productos < ' || v_precio_limite || ' ---');
    FOR rec_producto IN c_productos_a_actualizar LOOP
        -- Mostrar info del producto que se va a actualizar
        DBMS_OUTPUT.PUT_LINE('Actualizando Producto: ' || rec_producto.Nombre || ' (ID: ' || rec_producto.ProductoID || ')');
        DBMS_OUTPUT.PUT_LINE('  Precio Original: ' || rec_producto.Precio);

    UPDATE Productos
    SET Precio = Precio * (1 + v_porcentaje_aumento / 100)
    WHERE CURRENT OF c_productos_a_actualizar;

    v_filas_actualizadas := v_filas_actualizadas + 1;

    DBMS_OUTPUT.PUT_LINE('  Precio Nuevo   : ' || TO_CHAR(rec_producto.Precio * (1 + v_porcentaje_aumento / 100), '99999.99'));
    END LOOP;

    IF v_filas_actualizadas > 0 THEN
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('--- Actualización completada. ' || v_filas_actualizadas || ' producto(s) actualizado(s). ---');
    ELSE
      DBMS_OUTPUT.PUT_LINE('--- No se encontraron productos con precio inferior a ' || v_precio_limite || '. No se realizaron cambios. ---');
    END IF;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
    DBMS_OUTPUT.PUT_LINE('** Revirtiendo cualquier cambio pendiente (ROLLBACK)... **');
    ROLLBACK;
    RAISE;
END;
/

    