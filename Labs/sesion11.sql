--EJERCICIO 1
CREATE OR REPLACE FUNCTION calcular_edad_cliente (
    p_cliente_id IN Clientes.ClienteID%TYPE -- Parámetro de entrada: ID del cliente
)
RETURN NUMBER -- Devuelve la edad como un número
IS
    v_fecha_nacimiento Clientes.FechaNacimiento%TYPE; -- Variable para almacenar la fecha de nacimiento
    v_edad NUMBER; -- Variable para almacenar la edad calculada
BEGIN
    -- 1. Buscar la fecha de nacimiento del cliente
    SELECT FechaNacimiento
    INTO v_fecha_nacimiento -- Guardar el resultado en la variable local
    FROM Clientes
    WHERE ClienteID = p_cliente_id; -- Filtrar por el ID de cliente proporcionado
    -- 2. Calcular la edad en años
    v_edad := TRUNC(MONTHS_BETWEEN(SYSDATE, v_fecha_nacimiento) / 12);
    -- 3. Devolver la edad calculada
    RETURN v_edad;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado en calcular_edad_cliente para ClienteID ' || p_cliente_id || ': ' || SQLERRM);
        RETURN NULL;
END calcular_edad_cliente;
/

-- Obtener la edad de un cliente específico
SELECT nombre, calcular_edad_cliente(ClienteID) AS Edad
FROM Clientes
WHERE ClienteID = 1;

-- Obtener la edad de todos los clientes
SELECT ClienteID, Nombre, FechaNacimiento, calcular_edad_cliente(ClienteID) AS Edad
FROM Clientes;

-- Probar el caso de un cliente que no existe (debería devolver NULL para Edad)
SELECT calcular_edad_cliente(9999) AS Edad FROM dual;

---------------------------------

--EJERCICIO 2
CREATE OR REPLACE FUNCTION obtener_precio_promedio
RETURN NUMBER -- Especifica que la función devolverá un valor numérico
IS
  v_precio_promedio Productos.Precio%TYPE; -- Variable para almacenar el resultado del promedio
BEGIN
  -- Calcula el valor promedio de la columna Precio en la tabla Productos
  SELECT AVG(Precio)
  INTO v_precio_promedio -- Guarda el resultado en la variable local
  FROM Productos;
  -- Devuelve el precio promedio calculado
  RETURN v_precio_promedio;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error al calcular el precio promedio: ' || SQLERRM);
    RETURN NULL;
END obtener_precio_promedio;
/

--Consulta SQL para probar la función

SELECT
  ProductoID,
  Nombre,
  Precio
FROM
  Productos
WHERE
  Precio > obtener_precio_promedio();