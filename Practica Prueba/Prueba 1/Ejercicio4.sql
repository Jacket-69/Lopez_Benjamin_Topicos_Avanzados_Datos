DECLARE
  v_fecha_limite DATE := DATE '2025-03-02';
  CURSOR c_detalles_a_actualizar IS
    SELECT dp.DetalleID, dp.Cantidad
    FROM DetallesPedidos dp
    INNER JOIN Pedidos p ON dp.PedidoID = p.PedidoID
    WHERE p.FechaPedido < v_fecha_limite
    FOR UPDATE OF dp.Cantidad;

v_filas_actualizadas NUMBER := 0;

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Iniciando actualización de Cantidad en DetallesPedidos ---');
  FOR rec_detalle IN c_detalles_a_actualizar LOOP
      DBMS_OUTPUT.PUT_LINE('Actualizando DetalleID: ' || rec_detalle.DetalleID ||
                        ' - Cantidad Original: ' || rec_detalle.Cantidad);
    UPDATE DetallesPedidos
    SET Cantidad = Cantidad + 1 -- Aumentar la cantidad en 1
    WHERE CURRENT OF c_detalles_a_actualizar;    

    v_filas_actualizadas := v_filas_actualizadas + 1; -- Incrementar contador

    DBMS_OUTPUT.PUT_LINE('  -> Cantidad Nueva: ' || (rec_detalle.Cantidad + 1));
  END LOOP;
  IF v_filas_actualizadas > 0 THEN
      COMMIT;
      DBMS_OUTPUT.PUT_LINE('--- Actualización completada. ' || v_filas_actualizadas || ' fila(s) modificada(s). Cambios confirmados (COMMIT). ---');
    ELSE
      DBMS_OUTPUT.PUT_LINE('--- No se encontraron detalles de pedidos que cumplieran la condición. No se realizaron cambios. ---');
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
    DBMS_OUTPUT.PUT_LINE('** Revirtiendo cualquier cambio pendiente (ROLLBACK)... **');
    ROLLBACK;
    RAISE;
END;
/