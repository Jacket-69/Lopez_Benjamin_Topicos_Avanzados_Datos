----------- EJERCICIO 1
-- 1. función calcular_total_con_descuento
CREATE OR REPLACE FUNCTION calcular_total_con_descuento (
    p_pedido_id IN NUMBER
) RETURN NUMBER
AS
    v_total_actual NUMBER;
    v_total_con_descuento NUMBER;
BEGIN
    -- Obtener el total actual del pedido
    SELECT Total
    INTO v_total_actual
    FROM Pedidos
    WHERE PedidoID = p_pedido_id;

    -- Verificar si el total supera 1000 para aplicar descuento
    IF v_total_actual > 1000 THEN
        v_total_con_descuento := v_total_actual * 0.90; -- Aplicar 10% de descuento
    ELSE
        v_total_con_descuento := v_total_actual; -- No se aplica descuento
    END IF;

    RETURN v_total_con_descuento;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Manejar la excepción si el pedido no existe
        RAISE_APPLICATION_ERROR(-20011, 'Pedido con ID ' || p_pedido_id || ' no encontrado en la función.');
        RETURN NULL;
    WHEN OTHERS THEN
        -- Manejar cualquier otra excepción
        RAISE_APPLICATION_ERROR(-20012, 'Error inesperado en la función calcular_total_con_descuento: ' || SQLERRM);
        RETURN NULL;
END calcular_total_con_descuento;
/

-- 2. crear aplicar_descuento_pedido
CREATE OR REPLACE PROCEDURE aplicar_descuento_pedido (
    p_pedido_id IN NUMBER
)
AS
    v_nuevo_total NUMBER;
BEGIN
    -- Calcular el nuevo total usando la función
    v_nuevo_total := calcular_total_con_descuento(p_pedido_id);

    -- IF Si la función devolvió un valor
    IF v_nuevo_total IS NOT NULL THEN
        -- Actualizar el total del pedido en la tabla Pedidos
        UPDATE Pedidos
        SET Total = v_nuevo_total
        WHERE PedidoID = p_pedido_id;

        -- Verificar si la actualización fue exitosa
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Pedido con ID ' || p_pedido_id || ' no encontrado al intentar actualizar.');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Total del pedido ' || p_pedido_id || ' actualizado a: ' || v_nuevo_total);
            COMMIT;
        END IF;
    ELSE
        DBMS_OUTPUT.PUT_LINE('No se pudo calcular el nuevo total para el pedido ' || p_pedido_id || '. No se realizó la actualización.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en el procedimiento aplicar_descuento_pedido: ' || SQLERRM);
        ROLLBACK; -- Revertir cambios en caso de error
END aplicar_descuento_pedido;
/

-- pruebas:

DECLARE
    v_pedido_con_descuento NUMBER := 101;
    v_pedido_sin_descuento NUMBER := 102;
    v_pedido_no_existente NUMBER := 999;
    v_total_original NUMBER;
    v_total_actualizado NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Probando pedido con descuento (' || v_pedido_con_descuento || ') ---');
    -- Primero, verifica el total original
    SELECT Total INTO v_total_original FROM Pedidos WHERE PedidoID = v_pedido_con_descuento;
    DBMS_OUTPUT.PUT_LINE('Total original del pedido ' || v_pedido_con_descuento || ': ' || v_total_original);
    aplicar_descuento_pedido(v_pedido_con_descuento);
    -- Verifica el total actualizado
    SELECT Total INTO v_total_actualizado FROM Pedidos WHERE PedidoID = v_pedido_con_descuento;
    DBMS_OUTPUT.PUT_LINE('Total actualizado del pedido ' || v_pedido_con_descuento || ': ' || v_total_actualizado);

    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Probando pedido sin descuento (' || v_pedido_sin_descuento || ') ---');
    SELECT Total INTO v_total_original FROM Pedidos WHERE PedidoID = v_pedido_sin_descuento;
    DBMS_OUTPUT.PUT_LINE('Total original del pedido ' || v_pedido_sin_descuento || ': ' || v_total_original);
    aplicar_descuento_pedido(v_pedido_sin_descuento);
    SELECT Total INTO v_total_actualizado FROM Pedidos WHERE PedidoID = v_pedido_sin_descuento;
    DBMS_OUTPUT.PUT_LINE('Total actualizado del pedido ' || v_pedido_sin_descuento || ': ' || v_total_actualizado);


    DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Probando pedido no existente (' || v_pedido_no_existente || ') ---');
    aplicar_descuento_pedido(v_pedido_no_existente);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en el bloque anónimo de prueba: ' || SQLERRM);
END;
/

-- Verificar los cambios
SELECT * FROM Pedidos

----------- EJERCICIO 2
CREATE OR REPLACE TRIGGER validar_cantidad_detalle
BEFORE INSERT OR UPDATE ON DetallesPedidos -- se ejecuta antes de insertar o actualizar
FOR EACH ROW -- se ejecuta para cada fila afectada
DECLARE
    -- no use ninguna variable jaja
BEGIN
    -- :NEW es el nuevo valor de la columna que se está insertando o actualizando
    IF :NEW.Cantidad <= 0 THEN
        -- Si la cantidad no es mayor que 0, lanzar un error.
        RAISE_APPLICATION_ERROR(-20021, 'La cantidad del detalle del pedido debe ser mayor que 0. Valor proporcionado: ' || :NEW.Cantidad);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20022, 'Error inesperado en el trigger validar_cantidad_detalle: ' || SQLERRM);
END validar_cantidad_detalle;
/

--- Ejemplo 1
-- Intento de INSERT con cantidad INVÁLIDA
BEGIN
    INSERT INTO DetallesPedidos (DetalleID, PedidoID, ProductoID, Cantidad)
    VALUES (1, 101, 1, -5);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al insertar ' || SQLERRM);
END;
/
--- Ejemplo 2 
-- Intento de INSERT con cantidad VÁLIDA
BEGIN
    INSERT INTO DetallesPedidos (DetalleID, PedidoID, ProductoID, Cantidad)
    VALUES (3, 101, 2, 10);
    DBMS_OUTPUT.PUT_LINE('Detalle con ID 3 insertado correctamente.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error al insertar cantidad 10: ' || SQLERRM);
        ROLLBACK;
END;
/

-- Verificar
SELECT * FROM DetallesPedidos


----------- EJERCICIO 2

-- 1. Crear la tabla de dimension Dim_Ciudad
CREATE TABLE Dim_Ciudad (
    CiudadID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    NombreCiudad VARCHAR2(50) NOT NULL UNIQUE
);

-- 2. Crear la tabla de Dimensión Dim_Tiempo
-- También comente la nueva tabla
CREATE TABLE Dim_Tiempo (
    TiempoID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    FechaCompleta DATE NOT NULL UNIQUE,
    Anio NUMBER NOT NULL,
    Mes NUMBER NOT NULL,
    Dia NUMBER NOT NULL
);

-- 3. Crear la tabla de Hechos Fact_Pedidos

CREATE TABLE Fact_Pedidos (
    FacturaID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    PedidoID_NK NUMBER NOT NULL, -- Clave Natural del Pedido
    ClienteID_NK NUMBER NOT NULL, -- Clave Natural del Cliente
    CiudadID NUMBER,
    TiempoID NUMBER,
    TotalPedido NUMBER,
    CantidadTotalItems NUMBER,
    CONSTRAINT fk_fact_ciudad FOREIGN KEY (CiudadID) REFERENCES Dim_Ciudad(CiudadID),
    CONSTRAINT fk_fact_tiempo FOREIGN KEY (TiempoID) REFERENCES Dim_Tiempo(TiempoID)
);

-- 4. Poblar Dim_Ciudad
-- para insertar ciudades únicas desde la tabla Clientes.
BEGIN
    INSERT INTO Dim_Ciudad (NombreCiudad)
    SELECT DISTINCT Ciudad
    FROM Clientes
    WHERE Ciudad IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Dim_Ciudad dc WHERE dc.NombreCiudad = Clientes.Ciudad);
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' ciudades insertadas en Dim_Ciudad.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error poblando Dim_Ciudad: ' || SQLERRM);
        ROLLBACK;
END;
/

-- 5. Poblar Dim_Tiempo
-- insertar fechas únicas de los pedidos y sus componentes.

BEGIN
    INSERT INTO Dim_Tiempo (FechaCompleta, Anio, Mes, Dia)
    SELECT DISTINCT
        TRUNC(p.FechaPedido) AS FechaCompleta,
        EXTRACT(YEAR FROM p.FechaPedido) AS Anio,
        EXTRACT(MONTH FROM p.FechaPedido) AS Mes,
        EXTRACT(DAY FROM p.FechaPedido) AS Dia
    FROM Pedidos p
    WHERE TRUNC(p.FechaPedido) IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM Dim_Tiempo dt WHERE dt.FechaCompleta = TRUNC(p.FechaPedido));
    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' registros de tiempo insertados en Dim_Tiempo.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error poblando Dim_Tiempo: ' || SQLERRM);
        ROLLBACK;
END;
/

-- 6. Poblar Fact_Pedidos
BEGIN
    INSERT INTO Fact_Pedidos (
        PedidoID_NK,
        ClienteID_NK,
        CiudadID,
        TiempoID,
        TotalPedido,
        CantidadTotalItems
    )
    SELECT
        p.PedidoID,
        p.ClienteID,
        dc.CiudadID,
        dt.TiempoID,
        p.Total,
        (SELECT SUM(dp.Cantidad) FROM DetallesPedidos dp WHERE dp.PedidoID = p.PedidoID) AS CantidadTotalItems
    FROM
        Pedidos p
    JOIN
        Clientes c ON p.ClienteID = c.ClienteID
    JOIN
        Dim_Ciudad dc ON c.Ciudad = dc.NombreCiudad -- Unir por nombre de ciudad
    JOIN
        Dim_Tiempo dt ON TRUNC(p.FechaPedido) = dt.FechaCompleta; -- Unir por fecha truncada

    DBMS_OUTPUT.PUT_LINE(SQL%ROWCOUNT || ' registros insertados en Fact_Pedidos.');
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error poblando Fact_Pedidos: ' || SQLERRM);
        ROLLBACK;
END;
/

-- 7. Consulta
-- Mostrar el total de ventas (TotalPedido) por ciudad y año.

DECLARE
    CURSOR c_ventas_ciudad_anio IS
        SELECT
            dc.NombreCiudad,
            dt.Anio,
            SUM(fp.TotalPedido) AS SumaTotalVentas,
            SUM(fp.CantidadTotalItems) AS SumaCantidadItems,
            COUNT(DISTINCT fp.PedidoID_NK) AS NumeroDePedidos
        FROM
            Fact_Pedidos fp
        JOIN
            Dim_Ciudad dc ON fp.CiudadID = dc.CiudadID
        JOIN
            Dim_Tiempo dt ON fp.TiempoID = dt.TiempoID
        GROUP BY
            dc.NombreCiudad,
            dt.Anio
        ORDER BY
            dc.NombreCiudad,
            dt.Anio;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- INFORME DE VENTAS POR CIUDAD Y AÑO ---');
    DBMS_OUTPUT.PUT_LINE(RPAD('Ciudad', 25) || ' | ' || RPAD('Año', 5) || ' | ' || RPAD('Total Ventas', 15) || ' | ' || RPAD('Total Items', 15) || ' | ' || 'Nro Pedidos');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 25, '-') || ' | ' || RPAD('-', 5, '-') || ' | ' || RPAD('-', 15, '-') || ' | ' || RPAD('-', 15, '-') || ' | ' || RPAD('-', 11, '-'));

    FOR rec IN c_ventas_ciudad_anio LOOP
        DBMS_OUTPUT.PUT_LINE(
            RPAD(rec.NombreCiudad, 25) || ' | ' ||
            RPAD(rec.Anio, 5) || ' | ' ||
            TO_CHAR(rec.SumaTotalVentas, '999,999,990.00') || ' | ' ||
            RPAD(rec.SumaCantidadItems, 15) || ' | ' ||
            rec.NumeroDePedidos
        );
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('--- FIN DEL INFORME ---');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en la consulta analítica: ' || SQLERRM);
END;
/

-- verificar los datos

SELECT * FROM Dim_Ciudad;
SELECT * FROM Dim_Tiempo ORDER BY FechaCompleta;
SELECT * FROM Fact_Pedidos;