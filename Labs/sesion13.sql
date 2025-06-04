----------- EJERCICIO 1

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