--Selecciona los nombres y ciudades de los clientes que viven en Santiago
SELECT Nombre, Ciudad FROM Clientes WHERE Ciudad =
'Santiago' ORDER BY Nombre;

--Selecciona los pedidos con un total mayor a 500, ordenados por total de forma descendente
SELECT PedidoID, Total FROM Pedidos WHERE Total >
500 ORDER BY Total DESC;


--Selecciona el nombre donde el cliente tiene un pedido con un total mayor al promedio de todos los pedidos
SELECT Nombre FROM Clientes WHERE ClienteID IN (
SELECT ClienteID FROM Pedidos WHERE Total >
(SELECT AVG(Total) FROM Pedidos));


--Selecciona el nombre del producto con el precio más alto
SELECT Nombre
FROM Productos
WHERE Precio = (SELECT MAX(Precio) FROM Productos);


-------Funciones de Agregación-------

--Cuenta el número de clientes por ciudad donde el total de clientes es MAYOR a 1
SELECT Ciudad, COUNT(*) AS TotalClientes
FROM Clientes
GROUP BY Ciudad
HAVING COUNT(*) > 1;

--Muestra el nombre de los clientes y el total gastado por cada uno, junto con el promedio de gasto por pedido
SELECT c.Nombre, SUM(p.Total) AS TotalGastado,
AVG(p.Total) AS PromedioPorPedido
FROM Clientes c
LEFT JOIN Pedidos p ON c.ClienteID = p.ClienteID
GROUP BY c.Nombre;


------Expresiones regulares------

SELECT Nombre FROM Clientes
WHERE REGEXP_LIKE(Nombre, '^J');

SELECT Nombre FROM Clientes
WHERE REGEXP_LIKE(Nombre, '^A');

SELECT Nombre, Ciudad FROM Clientes 
WHERE REGEXP_LIKE(Ciudad, 'ai');

SELECT Nombre, Ciudad FROM Clientes 
WHERE REGEXP_LIKE(Ciudad, 'go');


---- Crear Vistas -----
CREATE VIEW nombre_vista AS
SELECT Nombre FROM Clientes;

SELECT * FROM nombre_vista;

CREATE VIEW PedidosCaros AS
SELECT c.Nombre, p.Total
FROM Clientes c
JOIN Pedidos p ON c.ClienteID = p.ClienteID
WHERE p.Total > 500;

SELECT * FROM PedidosCaros;

-- Commit para asegurar los cambios
COMMIT;