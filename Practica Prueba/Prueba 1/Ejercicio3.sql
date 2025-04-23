DECLARE
  v_umbral_total NUMBER := 1000;

  CURSOR c_clientes_alto_valor IS
    SELECT
      c.Nombre AS nombreCliente,
      SUM(p.Total) AS totalPedido
    FROM Clientes c
    INNER JOIN Pedidos p ON c.ClienteID = p.ClienteID
    GROUP BY c.ClienteID, c.Nombre
    HAVING SUM(p.Total) > v_umbral_total;

  BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Clientes con Total de Pedidos > ' || v_umbral_total || ' ---');
    FOR registro_cliente IN c_clientes_alto_valor LOOP
    DBMS_OUTPUT.PUT_LINE('Cliente: ' || registro_cliente.nombreCliente || ' - Total Pedidos: ' || TO_CHAR(registro_cliente.totalPedido));
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');

EXCEPTION
  -- Manejo básico de excepciones (recomendado)
  WHEN OTHERS THEN
     DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
     RAISE; -- Opcional: relanzar para que el llamador sepa del error
END;
/