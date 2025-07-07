------ PARTE 1
--Pregunta 1
/*
Una transacción es una secuencia de una o más operaciones SQL que se ejecutan
como una única unidad de trabajo atómica. Esto significa que todas las
operaciones dentro de la transacción deben completarse con éxito (COMMIT) para
que sus cambios sean permanentes en la base de datos. Si una sola operación
falla, la transacción completa se deshace (ROLLBACK), devolviendo la base de
datos al estado en que se encontraba antes de que la transacción comenzara.

Los SAVEPOINT son marcadores dentro de una transacción que permiten revertir
el trabajo a un punto específico sin deshacer la transacción completa. Son
útiles para manejar errores parciales. Por ejemplo, si un procedimiento
realiza varias inserciones y la segunda falla, podemos usar un `SAVEPOINT`
para revertir solo esa inserción fallida y continuar con la transacción.
*/

--Ejemplo:

CREATE OR REPLACE PROCEDURE registrar_horas_con_savepoint (
    p_asignacion_id IN NUMBER,
    p_fecha         IN DATE,
    p_horas         IN NUMBER
) AS
    v_horas_totales_dia NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Iniciando registro para asignación: ' || p_asignacion_id);

    SAVEPOINT inicio_registro_horas;

    INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas)
    VALUES (p_asignacion_id, p_fecha, p_horas);
    DBMS_OUTPUT.PUT_LINE('Registro de tiempo insertado temporalmente.');

    SELECT SUM(HorasTrabajadas)
    INTO v_horas_totales_dia
    FROM RegistrosTiempo
    WHERE AsignacionID = p_asignacion_id AND TRUNC(Fecha) = TRUNC(p_fecha);

    IF v_horas_totales_dia > 8 THEN
        ROLLBACK TO inicio_registro_horas;
        RAISE_APPLICATION_ERROR(-20001, 'El total de horas para el día no puede exceder 8.');
    ELSE
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Horas registradas y transacción confirmada.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
        ROLLBACK;
        RAISE;
END;
/


--Pregunta 2
/*

Un Data Warehouse es un sistema diseñado para el analisis de datos y la generacion de informes.
Su proposito vendria a ser consolidad grandes volumenes de datos historicos para facilitar
la toma de decisiones.
Se diferencia de una BD transaccional en aspectos como el proposito de cada uno, la estructura; 
una esta normalizada y la DW esta desnomralizada (esquema de estrella o de copo de nieve)
Para diseñar una tabla de hechos que analice las horas trabajadas por proyecto,
necesitamos identificar las dimensiones (el contexto) y las medidas (los datos a analizar).

Dimensiones: Proyecto, Empleado, Tiempo.
Medida: HorasTrabajadas.

*/
--Pregunta 3

/*
La herencia se implementa usando tipos de objeto, se define un tipo como superclase
y como NOT FINAL para que otros tipos hereden de el.
Tambien se crean subtipos usando UNDER que heredan los atributos y metodos del
tipo base
*/

-- Ejemplo de jerarquía Empleado -> Desarrollador:

-- 1. Eliminar la tabla Empleados original para evitar conflictos de nombre
DROP TABLE Empleados CASCADE CONSTRAINTS;

-- 2. Crear el tipo base
CREATE OR REPLACE TYPE Tipo_Empleado AS OBJECT (
    EmpleadoID NUMBER,
    Nombre VARCHAR2(100),
    Salario NUMBER(10,2),
    MEMBER FUNCTION calcular_bono RETURN NUMBER
) NOT FINAL;
/

CREATE OR REPLACE TYPE BODY Tipo_Empleado AS
    MEMBER FUNCTION calcular_bono RETURN NUMBER IS
    BEGIN
        RETURN self.Salario * 0.10; -- EJEMPLINHO
    END;
END;
/

-- 3. Crear el subtipo
CREATE OR REPLACE TYPE Tipo_Desarrollador UNDER Tipo_Empleado (
    LenguajePrincipal VARCHAR2(50),
    OVERRIDING MEMBER FUNCTION calcular_bono RETURN NUMBER
);
/

CREATE OR REPLACE TYPE BODY Tipo_Desarrollador AS
    OVERRIDING MEMBER FUNCTION calcular_bono RETURN NUMBER IS
    BEGIN
        -- Los desarrolladores tienen un bono mayor hehe
        RETURN self.Salario * 0.15;
    END;
END;
/

-- 4. Crear la tabla de objetos
CREATE TABLE Empleados OF Tipo_Empleado (
    EmpleadoID PRIMARY KEY
);

--Pregunta 4

/*

INDICES:

Ventajas:
Aceleran las consultas y evitan escaneos completos de tabla
Mejoran el rendimientos de los JOINS
Son obligatorios para aplicar restricciones como UNIQUE y PRIMAREY KEY

Desventajas:
Relentizan las operaciones tipo INSERT, UPDATE Y DELETE
Consumen espacio adicional

PARTICIONES:

Ventajas:
Mejoran el rendimiento en tablas muy grandes
Facilitan la gestión de datos (ej. archivar o eliminar datos antiguos borrando una partición entera, lo cual es muy rápido).
Permiten realizar operaciones de mantenimiento en una parte de la tabla sin afectar al resto.

Desventajas:
Pueden degradar el rendimiento si la clave de partición no se elige correctamente o no se usa en las consultas.
Aumentan la complejidad del diseño y la administración de la base de datos.

Para mejorar el rendimiento en RegistrosTiempo:
Índice: Crearia un indice compuesto en (AsignacionID, Fecha).
Esto optimizaria las busquedas de horas para una asignación especifica en un rango de fechas,
una consulta muy común en este modelo.
Partición: Particionaria la tabla RegistrosTiempo por rango en la columna Fecha. 
Por ejemplo, una partición por cada mes. 
Esto permitiria que las consultas que filtran por un mes o un rango de fechas 
solo lean los datos de las particiones relevantes, mejorando enormemente el rendimiento.

*/

------ PARTE 2

----------------- Ejercicio 1

CREATE OR REPLACE PROCEDURE registrar_tiempo (
    p_asignacion_id   IN RegistrosTiempo.AsignacionID%TYPE,
    p_fecha           IN RegistrosTiempo.Fecha%TYPE,
    p_horas_trabajadas IN RegistrosTiempo.HorasTrabajadas%TYPE
) AS
    v_total_horas_dia NUMBER;
BEGIN
    SAVEPOINT sp_antes_de_insertar;

    INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas)
    VALUES (p_asignacion_id, p_fecha, p_horas_trabajadas);

    SELECT SUM(HorasTrabajadas)
    INTO v_total_horas_dia
    FROM RegistrosTiempo
    WHERE AsignacionID = p_asignacion_id AND TRUNC(Fecha) = TRUNC(p_fecha);

    IF v_total_horas_dia > 8 THEN
        ROLLBACK TO sp_antes_de_insertar;
        RAISE_APPLICATION_ERROR(-20003, 'Limite de 8 horas diarias');
    END IF;


    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Registro de tiempo insertado correctamente.');

EXCEPTION
    WHEN OTHERS THEN

        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
        RAISE;
END;
/

-- pruebassss
BEGIN
    registrar_tiempo(p_asignacion_id => 1, p_fecha => TO_DATE('2025-03-01', 'YYYY-MM-DD'), p_horas_trabajadas => 1);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caso 1 falló inesperadamente: ' || SQLERRM);
END;
/

BEGIN
    registrar_tiempo(p_asignacion_id => 1, p_fecha => TO_DATE('2025-03-01', 'YYYY-MM-DD'), p_horas_trabajadas => 1);
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Caso 2 falló como se esperaba: ' || SQLERRM);
END;
/

----------------- Ejercicio 2

CREATE TABLE Dim_Proyecto (
    ProyectoID NUMBER PRIMARY KEY,
    Nombre VARCHAR2(100),
    Presupuesto NUMBER(15,2)
);


CREATE TABLE Dim_Tiempo (
    FechaID NUMBER PRIMARY KEY,
    Fecha DATE UNIQUE,
    Mes NUMBER,
    Anio NUMBER,
    Trimestre VARCHAR2(2)
);

CREATE TABLE Fact_HorasTrabajadas (
    HechoID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ProyectoID NUMBER,
    EmpleadoID NUMBER,
    FechaID NUMBER,
    HorasTrabajadas NUMBER(5,2),
    CONSTRAINT fk_fact_proyecto FOREIGN KEY (ProyectoID) REFERENCES Dim_Proyecto(ProyectoID),
    CONSTRAINT fk_fact_empleado FOREIGN KEY (EmpleadoID) REFERENCES Dim_Empleado(EmpleadoID),
    CONSTRAINT fk_fact_tiempo FOREIGN KEY (FechaID) REFERENCES Dim_Tiempo(FechaID)
);

SELECT
    dp.Nombre AS Nombre_Proyecto,
    dt.Anio,
    dt.Mes,
    SUM(fht.HorasTrabajadas) AS Total_Horas_Trabajadas
FROM
    Fact_HorasTrabajadas fht
JOIN
    Dim_Proyecto dp ON fht.ProyectoID = dp.ProyectoID
JOIN
    Dim_Tiempo dt ON fht.FechaID = dt.FechaID
GROUP BY
    dp.Nombre,
    dt.Anio,
    dt.Mes
ORDER BY
    dp.Nombre,
    dt.Anio,
    dt.Mes;

--no se me ocurrio como probarlas ojala esten buenas jaja

----------------- Ejercicio 3

DROP TABLE RegistrosTiempo;

CREATE INDEX idx_registrostiempo ON RegistrosTiempo(AsignacionID, Fecha);

CREATE TABLE RegistrosTiempo (
    RegistroID NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    AsignacionID NUMBER,
    Fecha DATE,
    HorasTrabajadas NUMBER(5,2),
    CONSTRAINT fk_asignacion FOREIGN KEY (AsignacionID) REFERENCES Asignaciones(AsignacionID),
    CONSTRAINT chk_horas CHECK (HorasTrabajadas >= 0 AND HorasTrabajadas <= 24)
)
PARTITION BY RANGE (Fecha)
(
    PARTITION p_registros_01_2025 VALUES LESS THAN (TO_DATE ('01-02-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_02_2025 VALUES LESS THAN (TO_DATE ('01-03-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_03_2025 VALUES LESS THAN (TO_DATE ('01-04-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_04_2025 VALUES LESS THAN (TO_DATE ('01-05-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_05_2025 VALUES LESS THAN (TO_DATE ('01-06-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_06_2025 VALUES LESS THAN (TO_DATE ('01-07-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_07_2025 VALUES LESS THAN (TO_DATE ('01-08-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_08_2025 VALUES LESS THAN (TO_DATE ('01-09-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_09_2025 VALUES LESS THAN (TO_DATE ('01-10-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_10_2025 VALUES LESS THAN (TO_DATE ('01-11-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_11_2025 VALUES LESS THAN (TO_DATE ('01-12-2025', 'DD-MM-YYYY')),
    PARTITION p_registros_12_2025 VALUES LESS THAN (MAXVALUE)
);


INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (1, TO_DATE('2025-03-01', 'YYYY-MM-DD'), 6.5);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (1, TO_DATE('2025-03-02', 'YYYY-MM-DD'), 7.0);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (2, TO_DATE('2025-03-01', 'YYYY-MM-DD'), 5.0);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (3, TO_DATE('2025-03-02', 'YYYY-MM-DD'), 4.5);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (4, TO_DATE('2025-03-03', 'YYYY-MM-DD'), 8.0);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (4, TO_DATE('2025-04-01', 'YYYY-MM-DD'), 6.0);
INSERT INTO RegistrosTiempo (AsignacionID, Fecha, HorasTrabajadas) VALUES (5, TO_DATE('2025-03-01', 'YYYY-MM-DD'), 7.5);

--Consulta

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(USER, 'RegistrosTiempo');
END;
/

EXPLAIN PLAN FOR
SELECT 
    AsignacionID,
    SUM(HorasTrabajadas) as Total_Mensual
FROM RegistrosTiempo
WHERE Fecha BETWEEN TO_DATE('28-02-2025', 'DD-MM-YYYY') AND TO_DATE('31-03-2025', 'DD-MM-YYYY')
GROUP BY AsignacionID;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);