-----------------EJERCICIO 1

CREATE OR REPLACE PACKAGE gestion_clientes AS
    g_clientes_registrados NUMBER := 0;

    e_fecha_nacimiento_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fecha_nacimiento_invalida, -20001);

    PROCEDURE registrar_cliente (
        p_cliente_id      IN Clientes.ClienteID%TYPE,
        p_nombre          IN Clientes.Nombre%TYPE,
        p_ciudad          IN Clientes.Ciudad%TYPE,
        p_fecha_nacimiento IN Clientes.FechaNacimiento%TYPE
    );

    FUNCTION obtener_edad (
        p_cliente_id      IN Clientes.ClienteID%TYPE
    ) RETURN NUMBER;
END gestion_clientes;
/

CREATE OR REPLACE PACKAGE BODY gestion_clientes AS

    PROCEDURE registrar_cliente (
        p_cliente_id      IN Clientes.ClienteID%TYPE,
        p_nombre          IN Clientes.Nombre%TYPE,
        p_ciudad          IN Clientes.Ciudad%TYPE,
        p_fecha_nacimiento IN Clientes.FechaNacimiento%TYPE
    ) IS
    BEGIN
        IF p_fecha_nacimiento >= TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20001, 'La fecha de nacimiento (' || TO_CHAR(p_fecha_nacimiento, 'YYYY-MM-DD') || ') debe ser anterior a la fecha actual (' || TO_CHAR(TRUNC(SYSDATE), 'YYYY-MM-DD') || ').');
        END IF;

        INSERT INTO Clientes (ClienteID, Nombre, Ciudad, FechaNacimiento)
        VALUES (p_cliente_id, p_nombre, p_ciudad, p_fecha_nacimiento);

        g_clientes_registrados := g_clientes_registrados + 1;

        DBMS_OUTPUT.PUT_LINE('Cliente ' || p_nombre || ' (ID: ' || p_cliente_id || ') registrado exitosamente.');
        DBMS_OUTPUT.PUT_LINE('Total de clientes registrados en esta sesión: ' || g_clientes_registrados);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Error: Ya existe un cliente con el ID ' || p_cliente_id || '.');
            RAISE;
        WHEN e_fecha_nacimiento_invalida THEN
             DBMS_OUTPUT.PUT_LINE('Error al registrar cliente: La fecha de nacimiento debe ser anterior a la fecha actual.');
             RAISE;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado al registrar cliente: ' || SQLERRM);
            RAISE;
    END registrar_cliente;

    FUNCTION obtener_edad (
        p_cliente_id      IN Clientes.ClienteID%TYPE
    ) RETURN NUMBER IS
        v_fecha_nacimiento  Clientes.FechaNacimiento%TYPE;
        v_edad              NUMBER;
    BEGIN
        SELECT FechaNacimiento
        INTO v_fecha_nacimiento
        FROM Clientes
        WHERE ClienteID = p_cliente_id;

        IF v_fecha_nacimiento IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Advertencia: El cliente ID ' || p_cliente_id || ' no tiene fecha de nacimiento registrada.');
            RETURN NULL;
        END IF;
        
        v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nacimiento) / 12);

        RETURN v_edad;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: No se encontró ningún cliente con el ID ' || p_cliente_id || '.');
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado al obtener la edad del cliente: ' || SQLERRM);
            RAISE;
    END obtener_edad;
END gestion_clientes;
/
-- Pruebassss
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 1: Registrar cliente válido ---');
    gestion_clientes.registrar_cliente(
        p_cliente_id      => 1234567890,
        p_nombre          => 'Ana Torres',
        p_ciudad          => 'La Serena',
        p_fecha_nacimiento => TO_DATE('1990-05-15', 'YYYY-MM-DD')
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en Prueba 1: ' || SQLERRM);
        ROLLBACK;
END;
/

-----------------EJERCICIO 2

CREATE OR REPLACE PACKAGE gestion_clientes AS
    g_clientes_registrados NUMBER := 0;

    e_fecha_nacimiento_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fecha_nacimiento_invalida, -20001);

    e_edad_invalida EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_edad_invalida, -20002);

    PROCEDURE registrar_cliente (
        p_cliente_id      IN Clientes.ClienteID%TYPE,
        p_nombre          IN Clientes.Nombre%TYPE,
        p_ciudad          IN Clientes.Ciudad%TYPE,
        p_fecha_nacimiento IN Clientes.FechaNacimiento%TYPE
    );

    FUNCTION obtener_edad (
        p_cliente_id      IN Clientes.ClienteID%TYPE
    ) RETURN NUMBER;
END gestion_clientes;
/

CREATE OR REPLACE PACKAGE BODY gestion_clientes AS

    PROCEDURE registrar_cliente (
        p_cliente_id      IN Clientes.ClienteID%TYPE,
        p_nombre          IN Clientes.Nombre%TYPE,
        p_ciudad          IN Clientes.Ciudad%TYPE,
        p_fecha_nacimiento IN Clientes.FechaNacimiento%TYPE
    ) IS
        v_edad_calculada NUMBER;
    BEGIN
        IF p_fecha_nacimiento >= TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20001, 'La fecha de nacimiento (' || TO_CHAR(p_fecha_nacimiento, 'YYYY-MM-DD') || ') debe ser anterior a la fecha actual (' || TO_CHAR(TRUNC(SYSDATE), 'YYYY-MM-DD') || ').');
        END IF;

        v_edad_calculada := TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), TRUNC(p_fecha_nacimiento)) / 12);

        IF v_edad_calculada < 18 THEN
            RAISE e_edad_invalida;
        END IF;

        INSERT INTO Clientes (ClienteID, Nombre, Ciudad, FechaNacimiento)
        VALUES (p_cliente_id, p_nombre, p_ciudad, p_fecha_nacimiento);

        g_clientes_registrados := g_clientes_registrados + 1;

        DBMS_OUTPUT.PUT_LINE('Cliente ' || p_nombre || ' (ID: ' || p_cliente_id || ') registrado exitosamente. Edad: ' || v_edad_calculada);
        DBMS_OUTPUT.PUT_LINE('Total de clientes registrados en esta sesión: ' || g_clientes_registrados);

    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Error al registrar cliente: Ya existe un cliente con el ID ' || p_cliente_id || '.');
            RAISE;
        WHEN e_edad_invalida THEN
             DBMS_OUTPUT.PUT_LINE('Error al registrar cliente: El cliente debe tener al menos 18 años. Edad calculada: ' || v_edad_calculada);
             RAISE;
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                DBMS_OUTPUT.PUT_LINE('Error al registrar cliente: ' || SQLERRM);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error inesperado al registrar cliente: ' || SQLCODE || ' - ' || SQLERRM);
            END IF;
            RAISE;
    END registrar_cliente;

    FUNCTION obtener_edad (
        p_cliente_id      IN Clientes.ClienteID%TYPE
    ) RETURN NUMBER IS
        v_fecha_nacimiento  Clientes.FechaNacimiento%TYPE;
        v_edad              NUMBER;
    BEGIN
        SELECT FechaNacimiento
        INTO v_fecha_nacimiento
        FROM Clientes
        WHERE ClienteID = p_cliente_id;

        IF v_fecha_nacimiento IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Advertencia: El cliente ID ' || p_cliente_id || ' no tiene fecha de nacimiento registrada.');
            RETURN NULL;
        END IF;
        
        v_edad := TRUNC(MONTHS_BETWEEN(TRUNC(SYSDATE), TRUNC(v_fecha_nacimiento)) / 12);

        RETURN v_edad;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Error: No se encontró ningún cliente con el ID ' || p_cliente_id || '.');
            RETURN NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error inesperado al obtener la edad del cliente: ' || SQLERRM);
            RAISE;
    END obtener_edad;
END gestion_clientes;
/
---pruebasss
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Prueba 1: Registrar cliente adulto válido ---');
    gestion_clientes.registrar_cliente(
        p_cliente_id      => 1234567891,
        p_nombre          => 'Laura adulta Paz',
        p_ciudad          => 'Valparaíso',
        p_fecha_nacimiento => TO_DATE('1995-07-20', 'YYYY-MM-DD') 
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error en Prueba 1: ' || SQLERRM);
        ROLLBACK;
END;
/