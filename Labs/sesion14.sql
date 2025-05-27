--------- EJERCICIO 1

-- 1. Crear el supertipo Vehiculo
CREATE OR REPLACE TYPE Vehiculo AS OBJECT (
    Marca VARCHAR2(50),
    Anio NUMBER,
    MEMBER FUNCTION obtener_antiguedad RETURN NUMBER
) NOT FINAL; -- NOT FINAL permite que otros tipos hereden de Vehiculo
/

CREATE OR REPLACE TYPE BODY Vehiculo AS
    MEMBER FUNCTION obtener_antiguedad RETURN NUMBER IS
        v_anio_actual NUMBER;
    BEGIN
        v_anio_actual := EXTRACT(YEAR FROM SYSDATE);
        RETURN (v_anio_actual - SELF.Anio);
    END obtener_antiguedad;
END;
/

-- 2. Crear el subtipo Automovil que hereda de Vehiculo
CREATE OR REPLACE TYPE Automovil UNDER Vehiculo (
    NumeroPuertas NUMBER,
    MEMBER FUNCTION descripcion RETURN VARCHAR2
);
/

CREATE OR REPLACE TYPE BODY Automovil AS
    MEMBER FUNCTION descripcion RETURN VARCHAR2 IS
        v_antiguedad NUMBER;
    BEGIN
        -- Llamamos al método del supertipo para obtener la antiguedad
        v_antiguedad := SELF.obtener_antiguedad(); 
        
        RETURN 'Marca: ' || SELF.Marca || 
               ', Anio: ' || SELF.Anio || 
               ', Puertas: ' || SELF.NumeroPuertas ||
               ', Antiguedad: ' || v_antiguedad || ' anios(s).';
    END descripcion;
END;
/


-- pruebas

DESC Vehiculo;
DESC Automovil;

DECLARE
    mi_auto Automovil;
    mi_otro_auto Automovil;
BEGIN
    -- ej1
    mi_auto := Automovil('Toyota', 2020, 4);
    DBMS_OUTPUT.PUT_LINE('--- Ejemplo 1 ---');
    DBMS_OUTPUT.PUT_LINE('Marca: ' || mi_auto.Marca);
    DBMS_OUTPUT.PUT_LINE('Año: ' || mi_auto.Anio);
    DBMS_OUTPUT.PUT_LINE('Puertas: ' || mi_auto.NumeroPuertas);
    DBMS_OUTPUT.PUT_LINE('Antiguedad del auto: ' || mi_auto.obtener_antiguedad() || ' años.');
    DBMS_OUTPUT.PUT_LINE('Descripción: ' || mi_auto.descripcion());
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ej2
    mi_otro_auto := Automovil('Mazda', EXTRACT(YEAR FROM SYSDATE) - 1, 2);
    DBMS_OUTPUT.PUT_LINE('--- Ejemplo 2 ---');
    DBMS_OUTPUT.PUT_LINE('Marca: ' || mi_otro_auto.Marca);
    DBMS_OUTPUT.PUT_LINE('Año: ' || mi_otro_auto.Anio);
    DBMS_OUTPUT.PUT_LINE('Puertas: ' || mi_otro_auto.NumeroPuertas);
    DBMS_OUTPUT.PUT_LINE('Antiguedad del auto: ' || mi_otro_auto.obtener_antiguedad() || ' años.');
    DBMS_OUTPUT.PUT_LINE('Descripción: ' || mi_otro_auto.descripcion());
END;
/

--------- EJERCICIO 2


-- 1. Crear el subtipo Camion que herede de Vehiculo
CREATE OR REPLACE TYPE Camion UNDER Vehiculo (
    CapacidadCarga NUMBER, -- en toneladas
    OVERRIDING MEMBER FUNCTION obtener_antiguedad RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY Camion AS
    OVERRIDING MEMBER FUNCTION obtener_antiguedad RETURN NUMBER IS
        v_anio_actual NUMBER;
        v_antiguedad_base NUMBER;
    BEGIN
        --se llama al metodo del supertipo
        v_antiguedad_base := (SELF AS Vehiculo).obtener_antiguedad();
        RETURN v_antiguedad_base + 2;

    END obtener_antiguedad;
END;
/

-- 2. se crear una tabla de objetos vehiculos
-- esta tabla va a almacenar vehiculo y sus subtipos (automovil, camion)

DECLARE
    v_table_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_table_exists FROM user_tables WHERE table_name = 'VEHICULOS';
    IF v_table_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE TABLE Vehiculos OF Vehiculo'; -- [cite: 39, 40]
        DBMS_OUTPUT.PUT_LINE('Tabla VEHICULOS creada.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Tabla VEHICULOS ya existe.');
    END IF;
END;
/

-- 3. se inserta un camion en la tabla vehiculos
INSERT INTO Vehiculos
VALUES (
    Camion(
        'Volvo',                     -- Marca
        2020,                        -- Año
        25                           -- CapacidadCarga en toneladas
    )
);

INSERT INTO Vehiculos
VALUES (
    Automovil(
        'Mazda',                     -- Marca
        1995                         -- Año
        2                            -- NumeroPuertas
    )
);

COMMIT;

-- 4. consultar la antiguedad y descripción de los camioncitos
SET SERVEROUTPUT ON;
DBMS_OUTPUT.PUT_LINE(CHR(10) || '--- Consulta de Camiones ---');

DECLARE
    CURSOR c_camiones IS
        SELECT VALUE(v) AS obj_vehiculo -- se obtiene el objeto completo
        FROM Vehiculos v
        WHERE VALUE(v) IS OF (ONLY Camion); -- Filtra solo para objetos que son Camion
    
    v_camion_obj Camion;
    v_marca VARCHAR2(50);
    v_anio NUMBER;
    v_capacidad_carga NUMBER;
    v_antiguedad NUMBER;

BEGIN
    FOR rec IN c_camiones LOOP
        v_camion_obj := TREAT(rec.obj_vehiculo AS Camion); -- Convertir el objeto Vehiculo a Camion para acceder a atributos específicos

        v_marca := v_camion_obj.Marca;
        v_anio := v_camion_obj.Anio;
        v_capacidad_carga := v_camion_obj.CapacidadCarga;
        v_antiguedad := v_camion_obj.obtener_antiguedad(); -- Llama al metodo sobrescrito de Camion

        DBMS_OUTPUT.PUT_LINE('Descripción del Camión:');
        DBMS_OUTPUT.PUT_LINE('  Marca: ' || v_marca);
        DBMS_OUTPUT.PUT_LINE('  Año: ' || v_anio);
        DBMS_OUTPUT.PUT_LINE('  Capacidad de Carga: ' || v_capacidad_carga || ' toneladas');
        DBMS_OUTPUT.PUT_LINE('  Antiguedad Calculada (con ajuste): ' || v_antiguedad || ' años');
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
END;
/

-- pruebassss

SELECT
    v.Marca,
    v.Anio,
    CASE
        WHEN VALUE(v) IS OF (ONLY Automovil) THEN 'Automóvil'
        WHEN VALUE(v) IS OF (ONLY Camion) THEN 'Camión'
        ELSE 'Vehículo Genérico'
    END AS TipoVehiculo,
    CASE
        WHEN VALUE(v) IS OF (ONLY Automovil) THEN TREAT(VALUE(v) AS Automovil).NumeroPuertas
        ELSE NULL
    END AS NumeroPuertas,
    CASE
        WHEN VALUE(v) IS OF (ONLY Camion) THEN TREAT(VALUE(v) AS Camion).CapacidadCarga
        ELSE NULL
    END AS CapacidadCarga,
    v.obtener_antiguedad() AS Antiguedad_Calculada
FROM Vehiculos v;
