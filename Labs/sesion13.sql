----------- EJERCICIO 1

CREATE OR REPLACE PROCEDURE actualizar_inventario_pedido (
    p_PedidoID IN Pedidos.PedidoID%TYPE
)
AS
    v_ProductoID        DetallesPedidos.ProductoID%TYPE;
    v_CantidadPedida    DetallesPedidos.Cantidad%TYPE;
    v_CantidadActual    Inventario.CantidadProductos%TYPE;
    v_NombreProducto    Productos.Nombre%TYPE;
    v_error_en_pedido   BOOLEAN := FALSE;

    CURSOR c_detalles_pedido IS
        SELECT dp.ProductoID, dp.Cantidad, p.Nombre AS NombreProducto
        FROM DetallesPedidos dp
        JOIN Productos p ON dp.ProductoID = p.ProductoID
        WHERE dp.PedidoID = p_PedidoID;

BEGIN
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
    DBMS_OUTPUT.PUT_LINE('Iniciando actualización de inventario para el PedidoID: ' || p_PedidoID);

    FOR rec_detalle IN c_detalles_pedido LOOP
        SAVEPOINT sp_antes_producto;

        v_ProductoID := rec_detalle.ProductoID;
        v_CantidadPedida := rec_detalle.Cantidad;
        v_NombreProducto := rec_detalle.NombreProducto;

        DBMS_OUTPUT.PUT_LINE('Procesando Producto: ' || v_NombreProducto || ' (ID: ' || v_ProductoID || '), Cantidad Pedida: ' || v_CantidadPedida);

        BEGIN
            SELECT CantidadProductos
            INTO v_CantidadActual
            FROM Inventario
            WHERE ProductoID = v_ProductoID
            FOR UPDATE;

            IF v_CantidadActual >= v_CantidadPedida THEN
                UPDATE Inventario
                SET CantidadProductos = CantidadProductos - v_CantidadPedida
                WHERE ProductoID = v_ProductoID;

                DBMS_OUTPUT.PUT_LINE('Inventario actualizado para ProductoID: ' || v_ProductoID || '. Stock anterior: ' || v_CantidadActual || ', Stock nuevo: ' || (v_CantidadActual - v_CantidadPedida));
            ELSE
                DBMS_OUTPUT.PUT_LINE('ERROR: Inventario insuficiente para ProductoID: ' || v_ProductoID || ' (' || v_NombreProducto || '). Stock actual: ' || v_CantidadActual || ', Cantidad pedida: ' || v_CantidadPedida);
                v_error_en_pedido := TRUE;
                ROLLBACK TO sp_antes_producto;
                DBMS_OUTPUT.PUT_LINE('Rollback realizado al savepoint sp_antes_producto para ProductoID: ' || v_ProductoID);
            END IF;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('ERROR: ProductoID: ' || v_ProductoID || ' (' || v_NombreProducto || ') no encontrado en la tabla Inventario. Se asume stock 0.');
                v_error_en_pedido := TRUE;
                ROLLBACK TO sp_antes_producto;
                DBMS_OUTPUT.PUT_LINE('Rollback realizado al savepoint sp_antes_producto para ProductoID: ' || v_ProductoID);
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error inesperado procesando ProductoID: ' || v_ProductoID || ' (' || v_NombreProducto || ') - SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
                v_error_en_pedido := TRUE;
                ROLLBACK TO sp_antes_producto;
                DBMS_OUTPUT.PUT_LINE('Rollback realizado al savepoint sp_antes_producto para ProductoID: ' || v_ProductoID);
        END;
    END LOOP;

    IF v_error_en_pedido THEN
        DBMS_OUTPUT.PUT_LINE('Proceso de actualización de inventario para PedidoID: ' || p_PedidoID || ' completado con uno o más errores de stock. Se confirman las actualizaciones posibles.');
        COMMIT;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Inventario actualizado correctamente para todos los productos del PedidoID: ' || p_PedidoID);
        COMMIT;
    END IF;
    DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error general en el procedimiento actualizar_inventario_pedido para PedidoID: ' || p_PedidoID || '. SQLCODE: ' || SQLCODE || ' SQLERRM: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Se ha realizado un ROLLBACK total de la transacción para este pedido.');
        DBMS_OUTPUT.PUT_LINE('--------------------------------------------------------------------');
        RAISE;
END actualizar_inventario_pedido;
/



--pruebasss

BEGIN
    actualizar_inventario_pedido(p_PedidoID => 1);
END;
/

SELECT p.Nombre, i.CantidadProductos
FROM Inventario i
JOIN Productos p ON i.ProductoID = p.ProductoID;

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