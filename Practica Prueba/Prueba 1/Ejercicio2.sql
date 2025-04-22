DECLARE
  bias NUMBER := 1000;
  CURSOR c_aumentar_precio IS
    SELECT Productos.Nombre AS nombreProducto, Productos.Precio AS precioProducto
    FROM Productos
    FOR UPDATE OF Productos.Precio;

  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Lista de Productos ---');
    FOR registro_productos IN c_aumentar_precio LOOP
      IF registro_productos.precioProducto <= bias THEN
        DBMS_OUTPUT.PUT_LINE('Producto: ' || registro_productos.nombreProducto || ' - Precio Actual: ' || TO_CHAR(registro_productos.precioProducto));
        registro_productos.precioProducto := registro_productos.precioProducto * 1.15;
        DBMS_OUTPUT.PUT_LINE('Producto: ' || registro_productos.nombreProducto || ' - Precio Nuevo: ' || TO_CHAR(registro_productos.precioProducto));
      ELSE
        DBMS_OUTPUT.PUT_LINE('ERROR: No se encontró ningún pedido con valor inferior a 1000');
        DBMS_OUTPUT.PUT_LINE('No se realizó ninguna actualización.');
      END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');

  EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM);
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('Transacción revertida (ROLLBACK) debido a error.');

  END;
/
