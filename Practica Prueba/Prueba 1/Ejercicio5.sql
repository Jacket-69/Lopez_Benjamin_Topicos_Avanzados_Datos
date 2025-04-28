-- 1. Especificación del Tipo
CREATE OR REPLACE TYPE cliente_obj AS OBJECT (
  -- Atributos
  cliente_id NUMBER,
  nombre     VARCHAR2(50),
  -- Declaración del Método Miembro
  MEMBER FUNCTION get_info RETURN VARCHAR2
);
/

-- 2. Cuerpo del Tipo (Implementación del método)
CREATE OR REPLACE TYPE BODY cliente_obj AS
  -- Implementación de la función get_info
  MEMBER FUNCTION get_info RETURN VARCHAR2 IS
  BEGIN
    -- SELF se refiere a la instancia actual del objeto sobre la que se llama el método.
    -- Concatenamos los atributos para formar la cadena de salida.
    RETURN 'ID Cliente: ' || SELF.cliente_id || ', Nombre: ' || SELF.nombre;
  END get_info;
END;
/

-- 3. Crear la tabla basada en el tipo de objeto
CREATE TABLE clientes_obj_tab OF cliente_obj (
  CONSTRAINT pk_clientes_obj_tab PRIMARY KEY (cliente_id)
);
/

-- 4. Insertar datos desde la tabla Clientes usando el constructor del objeto
INSERT INTO clientes_obj_tab (cliente_id, nombre)
SELECT clienteid, nombre
FROM Clientes;

-- 5. Confirmar la transacción de la carga de datos
COMMIT;

-- Verificar
SELECT c.get_info() FROM clientes_obj_tab c;

SET SERVEROUTPUT ON;

DECLARE
  -- 6. Cursor explícito para recorrer la tabla de objetos
  CURSOR c_clientes_objeto IS
    SELECT VALUE(c) AS cliente_instancia -- VALUE(alias) devuelve la instancia del objeto de la fila
    FROM clientes_obj_tab c; -- 'c' es el alias de la tabla

  -- Variable para almacenar la información devuelta por el método
  v_info_cliente VARCHAR2(200);

BEGIN
  DBMS_OUTPUT.PUT_LINE('--- Información de Clientes (desde Tabla de Objetos usando Método) ---');

  -- 7. Abrir y recorrer el cursor
  FOR rec_cliente IN c_clientes_objeto LOOP
    -- rec_cliente.cliente_instancia contiene el objeto cliente_obj para la fila actual

    -- 8. Llamar al método get_info() sobre la instancia del objeto
    v_info_cliente := rec_cliente.cliente_instancia.get_info();

    -- 9. Mostrar la cadena devuelta por el método
    DBMS_OUTPUT.PUT_LINE(v_info_cliente);

  END LOOP;

  DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');

EXCEPTION
  -- 10. Manejo básico de excepciones
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
    RAISE;
END;
/