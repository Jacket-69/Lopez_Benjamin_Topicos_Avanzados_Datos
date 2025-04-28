--PARTE 1
/*
Pregungta 1.- 
La relación muchos a muchos implica que varias entidades pueden
poseer varias de otras entidades. En la base de datos actual vendria
a ser que varios empleados distintos podrian tener varias asignaciones
distintas.

--------
Pregunta 2.-
Una vista sirve para facilitar el trabajo de traer información de una
base de datos, se hace una consulta inicial, tan compleja como tenga
que ser y luego utilizando vistas, se arreglan ciertos parametros
para que se pueda utilizar haciendo solo la llamada a la vista
y cambiar los parametros a buscar. 

*/

CREATE VIEW HorasVista AS
	SELECT Proyectos.Nombre, Asignaciones.Horas FROM Asignaciones
	JOIN Proyectos
	ON Asignaciones.ProyectoID = Proyectos.ProyectoID;

/*
Pregunta 3.-
Es un 'error' que se lanza cuando se cumplen ciertas condiciones dentro
de la ejecución de un codigo.
Una forma de manejar las exepciones seria esta: 

    EXCEPTION
    	WHEN NO_DATA_FOUND THEN
    		DBMS_OUTPUT.PUT_LINE('** ERROR NO_DATA_FOUND: ' || SQLCODE || ' - ' || SQLERRM || '**');
    		DBMS_OUTPUT.PUT_LINE('*** No se encontraron datos ***');
    		DBMS_OUTPUT.PUT_LINE('*** Revirtiando cualquier cambio... ***');
    		ROLLBACK;
    		RAISE;

Este bloque de codigo le da a enteder al usuario que 
no se encontraron datos de lo que sea que fuere que
estuviese buscando.

Pregunta 4.-
Un cursor explicito sirve para seleccionar cierta información de
una base datos de tal forma, que se pueda reutilizar el codigo
mas adelante si es que se llega a necesitar el mismo tipo de
información. Un atributo es %TYPE que lo utilizaba para cuando
queria crear una variable dentro de un cursor pero que conservara el 
tipo de la variable dentro de la base de datos, por ejemplo si
quiero traer una edad y es de tipo VARCHAR, utilizando %TYPE la
nueva variable seria de tipo VARCHAR
Otro atributo seria %ISOPEN, que verificaria si un cursor explicito
sigue abierto o no.
*/

--PARTE 2

--Pregunta 1.

DECLARE
CURSOR d_salario_filtrado IS
	SELECT Departamentos.Nombre AS NombreDpto, 
		SUM(Empleados.Salario)/COUNT(*) AS Promedio
	FROM Empleados
	INNER JOIN Departamentos
	ON Empleados.DepartamentoID = Departamentos.DepartamentoID
	GROUP BY Departamentos.Nombre
	HAVING (SUM(Empleados.Salario)/COUNT(*)) > 600000;

BEGIN
	FOR registro_salario IN d_salario_filtrado LOOP
		DBMS_OUTPUT.PUT_LINE('Departamento:  ' || registro_salario.NombreDpto ||
							' - Promedio de salarios: ' || TO_CHAR(registro_salario.Promedio));
	END LOOP;
	DBMS_OUTPUT.PUT_LINE('--- Fin de la lista ---');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || ' **');
END;
/

--Pregunta 2.
DECLARE
	v_umbral NUMBER := 1500000;
	v_porcentaje_reduccion NUMBER := 5;

	CURSOR c_actualizar_presupuesto IS
		SELECT Proyectos.Nombre AS NombreProyecto, 
				Proyectos.Presupuesto AS Presupuesto
		FROM Proyectos
		WHERE Proyectos.Presupuesto > v_umbral
		FOR UPDATE OF Proyectos.Presupuesto;

	v_filas_actualizadas NUMBER := 0;

	BEGIN
	DBMS_OUTPUT.PUT_LINE('--- Iniciando disminucion de precios (-5%) para presupuestos < ' || v_umbral || ' ---');
	FOR rec_presupuesto IN c_actualizar_presupuesto LOOP
		DBMS_OUTPUT.PUT_LINE('Actualizando: ' || rec_presupuesto.NombreProyecto);
		DBMS_OUTPUT.PUT_LINE(' Valor Original: ' || rec_presupuesto.Presupuesto);
	UPDATE Proyectos
	SET Proyectos.Presupuesto = Proyectos.Presupuesto * (1 - v_porcentaje_reduccion/100)
	WHERE CURRENT OF c_actualizar_presupuesto;

	v_filas_actualizadas := v_filas_actualizadas + 1;

	DBMS_OUTPUT.PUT_LINE('  Valor Nuevo   : ' || TO_CHAR(rec_presupuesto.Presupuesto * (1 - v_porcentaje_reduccion / 100), '9999999.99'));
    END LOOP;

    IF v_filas_actualizadas > 0 THEN
    	COMMIT;
    	DBMS_OUTPUT.PUT_LINE('--- Actualización completada. ' || v_filas_actualizadas || ' presupuesto(s) actualizados(s). ---');
    ELSE
    	DBMS_OUTPUT.PUT_LINE('--- No se cumplen los criterios para actualizar');
    END IF;

    EXCEPTION
    	WHEN OTHERS THEN
    		DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || '**');
    		DBMS_OUTPUT.PUT_LINE('*** Revirtiando cualquier cambio... ***');
    		ROLLBACK;
    		RAISE;

END;
/

--Pregunta 3.

CREATE OR REPLACE TYPE empleado_obj AS OBJECT (
	empleado_id NUMBER,
	nombre VARCHAR2(50),

	MEMBER FUNCTION get_info RETURN VARCHAR2
);

/

CREATE OR REPLACE TYPE BODY empleado_obj AS
	MEMBER FUNCTION get_info RETURN VARCHAR2 IS
	BEGIN
		RETURN 'ID Empleado: ' || SELF.empleado_id || ', Nombre: ' || SELF.nombre;
	END get_info;
END;
/


CREATE TABLE empleado_obj_tab OF empleado_obj(
	CONSTRAINT pk_empleado_obj_tab PRIMARY KEY (empleado_id)
);
/ 

INSERT INTO empleado_obj_tab (empleado_id, nombre)
SELECT EmpleadoID, Nombre
FROM Empleados;

COMMIT;


--prueba de que funciona
SELECT empleado.get_info() FROM empleado_obj_tab empleado;


DECLARE
	CURSOR c_empleado_objeto IS
		SELECT VALUE(empleado) AS empleado_instancia
		FROM empleado_obj_tab empleado;

	v_info_empleado VARCHAR2(200);

	BEGIN
		DBMS_OUTPUT.PUT_LINE('--- Información Empleados ---');

		FOR rec_empleado IN c_empleado_objeto LOOP

		v_info_empleado := rec_empleado.empleado_instancia.get_info();

		DBMS_OUTPUT.PUT_LINE(v_info_empleado);

	END LOOP;

    EXCEPTION
    	WHEN OTHERS THEN
    		DBMS_OUTPUT.PUT_LINE('** ERROR INESPERADO: ' || SQLCODE || ' - ' || SQLERRM || '**');
    		DBMS_OUTPUT.PUT_LINE('*** Revirtiando cualquier cambio... ***');
    		ROLLBACK;
    		RAISE;
END;
/