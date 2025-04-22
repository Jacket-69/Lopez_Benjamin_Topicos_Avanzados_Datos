DECLARE
  bias NUMBER := 1000;
  CURSOR c_total_pedidos IS
    SELECT Clientes.Nombre AS nombreCliente, Pedidos.Total AS totalPedido
    FROM Pedidos
    INNER JOIN Clientes
    ON Pedidos.ClienteID = Clientes.ClienteID;

  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Lista de Pedidos de Clientes ---');
    FOR registro_pedidos IN c_total_pedidos LOOP
      IF registro_pedidos.totalPedido >= bias THEN
      DBMS_OUTPUT.PUT_LINE('Cliente: ' || registro_pedidos.nombreCliente || ' - Total: ' || TO_CHAR(registro_pedidos.totalPedido));
      ELSE
      DBMS_OUTPUT.PUT_LINE('Cliente: ' || registro_pedidos.nombreCliente || ' - No hay pedidos que cumplan el bias. ');
      END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');
  END;
/
