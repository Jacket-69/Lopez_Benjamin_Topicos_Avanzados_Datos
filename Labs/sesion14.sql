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
        -- Llamamos al método del supertipo para obtener la antigüedad
        v_antiguedad := SELF.obtener_antiguedad(); 
        
        RETURN 'Marca: ' || SELF.Marca || 
               ', Anio: ' || SELF.Anio || 
               ', Puertas: ' || SELF.NumeroPuertas ||
               ', Antigüedad: ' || v_antiguedad || ' anios(s).';
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
    DBMS_OUTPUT.PUT_LINE('Antigüedad del auto: ' || mi_auto.obtener_antiguedad() || ' años.');
    DBMS_OUTPUT.PUT_LINE('Descripción: ' || mi_auto.descripcion());
    DBMS_OUTPUT.PUT_LINE(' ');

    -- ej2
    mi_otro_auto := Automovil('Mazda', EXTRACT(YEAR FROM SYSDATE) - 1, 2);
    DBMS_OUTPUT.PUT_LINE('--- Ejemplo 2 ---');
    DBMS_OUTPUT.PUT_LINE('Marca: ' || mi_otro_auto.Marca);
    DBMS_OUTPUT.PUT_LINE('Año: ' || mi_otro_auto.Anio);
    DBMS_OUTPUT.PUT_LINE('Puertas: ' || mi_otro_auto.NumeroPuertas);
    DBMS_OUTPUT.PUT_LINE('Antigüedad del auto: ' || mi_otro_auto.obtener_antiguedad() || ' años.');
    DBMS_OUTPUT.PUT_LINE('Descripción: ' || mi_otro_auto.descripcion());
END;
/

--------- EJERCICIO 2

