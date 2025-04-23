DECLARE
  v_umbral_total NUMBER := 500;
  CURSOR c_pedidos_filtrados IS
    SELECT
      c.Nombre AS nombreCliente,
      p.PedidoID,
      p.Total AS totalPedido
    FROM Pedidos p
    INNER JOIN Clientes c ON p.ClienteID = c.ClienteID
    WHERE p.Total > v_umbral_total;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Lista de Pedidos con Total > ' || v_umbral_total || ' ---');
  FOR registro_pedido IN c_pedidos_filtrados LOOP
      DBMS_OUTPUT.PUT_LINE('Cliente: ' || registro_pedido.nombreCliente ||
                        ' - Pedido ID: ' || registro_pedido.PedidoID ||
                        ' - Total Pedido: ' || TO_CHAR(registro_pedido.totalPedido));
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
END;
/