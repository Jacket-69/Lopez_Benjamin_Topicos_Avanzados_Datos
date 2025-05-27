---------EJERCICIO 1

SELECT c.Nombre, COUNT(p.PedidoID) AS TotalPedidos
FROM Clientes c, Pedidos p
WHERE c.ClienteID = p.ClienteID
AND c.Ciudad = 'Santiago'
AND p.FechaPedido >= TO_DATE('2025-03-01', 'YYYY-MM-DD')
GROUP BY c.Nombre;

