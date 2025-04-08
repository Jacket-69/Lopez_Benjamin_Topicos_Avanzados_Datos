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

-- Commit para asegurar los cambios
COMMIT;