DECLARE
    v_precio NUMBER;
    bias NUMBER := 1;
    precio_bajo EXCEPTION;
    memory_overflow EXCEPTION;
    PRAGMA EXCEPTION_INIT(memory_overflow, -20001);
BEGIN
    SELECT Precio INTO v_precio 
    FROM Productos 
    WHERE ProductoID = bias;
    
    IF v_precio < 50 THEN
        RAISE precio_bajo;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Precio válido: ' || v_precio);

EXCEPTION
    WHEN precio_bajo THEN
        DBMS_OUTPUT.PUT_LINE('El precio es demasiado bajo: ' || v_precio);
    WHEN memory_overflow THEN
        DBMS_OUTPUT.PUT_LINE('Error de memoria: ' || SQLERRM);
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No se encontró el producto con ID: ' || bias);
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/

-- 1. Bloque PL/SQL que verifica un valor numérico y lanza excepción personalizada
DECLARE
    v_precio_producto PRODUCTOS.Precio%TYPE;
    bias NUMBER := 100;
    ex_precio_bajo EXCEPTION;
    PRAGMA EXCEPTION_INIT(ex_precio_bajo, -8000);
BEGIN
    SELECT Precio INTO v_precio_producto
    FROM Productos
    WHERE ProductoID = 1;

    IF v_precio_producto < bias THEN
        RAISE ex_precio_bajo;
    END IF;

	DBMS_OUTPUT.PUT_LINE('Procesando datos masivos...');
	DBMS_OUTPUT.PUT_LINE('Precio valido: ' || v_precio_producto);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Producto ID 1 no existe.');
    WHEN ex_precio_bajo THEN
        DBMS_OUTPUT.PUT_LINE('Error: Precio (' || v_precio_producto || ') es menor a ' || bias);
END;
/

-- 2. Bloque PL/SQL para manejar inserción con ID duplicado

DECLARE
    v_cliente_id CLIENTES.ClienteID%TYPE := 1;
BEGIN
    INSERT INTO Clientes (ClienteID, Nombre, Ciudad, FechaNacimiento)
    VALUES (v_cliente_id, 'Willyrex', 'Madrid', TO_DATE('09-05-1993','DD/MM/YYYY'));

    DBMS_OUTPUT.PUT_LINE('Éxito: Cliente insertado.'); 

EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
        DBMS_OUTPUT.PUT_LINE('Error: ID ' || v_cliente_id || ' ya existe.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
END;
/