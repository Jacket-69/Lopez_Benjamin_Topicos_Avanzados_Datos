-----EJERCICIO 1

/*
Nodo Principal (Primario): Estará ubicado en un centro de datos en Santiago, Chile. 

Este nodo gestionará todas las operaciones de escritura (transacciones, inserciones, actualizaciones).

Nodo Secundario (Standby): Se localizará en un centro de datos en Calama, Chile.

Tener los nodos en ubicaciones geográficas distintas es clave para la recuperación
ante desastres que puedan afectar a una ciudad completa.


Se utilizará replicación física asíncrona a través de Oracle Data Guard. 

Justificación: La replicación asíncrona se elige porque ofrece una menor latencia en el
nodo principal, ya que no tiene que esperar la confirmación del nodo secundario para
completar una transacción. Esta ligera posibilidad de pérdida de datos en caso de un
fallo catastrófico del nodo principal se considera un riesgo aceptable para este sistema
a cambio de un mejor rendimiento transaccional.

Uso de los Nodos Secundarios:
El nodo standby en Calama se configurará con Active Data Guard.

Esto permite que, mientras se mantiene sincronizado con el nodo principal, esté abierto
en modo de solo lectura.

Se utilizará activamente para descargar la carga de 
trabajo de solo lectura, como la ejecución de reportes de
ventas, consultas analíticas y otras tareas de inteligencia de negocio.
Esto mejora el rendimiento general del sistema al liberar recursos en el nodo principal.

Mecanismo de Failover:

Se implementará un failover automático 
utilizando la funcionalidad Fast-Start Failover de Oracle Data Guard.

Funcionamiento: Un tercer componente ligero (el "Observer") monitoreará la
disponibilidad del nodo principal. Si detecta un fallo, iniciará automáticamente el 
proceso para convertir el nodo standby en el nuevo nodo principal, sin necesidad de
intervención manual.

Objetivo: Se establece un Tiempo Medio de Recuperación (MTTR) objetivo de
menos de 5 minutos, lo que significa que el sistema volverá a estar operativo en el 
nodo secundario en ese lapso tras un fallo.
*/

-----EJERCICIO 2

-- Consulta de solo lectura para ejecutar en el nodo standby (Active Data Guard)
-- Objetivo: Generar un reporte del total de ventas por cliente en un período específico.

SELECT
    c.Nombre AS NombreCliente,
    c.Ciudad,
    SUM(p.Total) AS TotalComprado,
    COUNT(p.PedidoID) AS NumeroDePedidos
FROM
    Clientes c
JOIN
    Pedidos p ON c.ClienteID = p.ClienteID
WHERE
    p.FechaPedido BETWEEN TO_DATE('2025-01-01', 'YYYY-MM-DD') AND TO_DATE('2025-12-31', 'YYYY-MM-DD')
GROUP BY
    c.Nombre, c.Ciudad
ORDER BY
    TotalComprado DESC;