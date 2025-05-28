import csv
import random
from faker import Faker
from datetime import datetime, timedelta
import os

# Configuración
NUM_CLIENTES = 10000
NUM_PRODUCTOS = 100
MAX_PEDIDOS_POR_CLIENTE = 5 
MAX_DETALLES_POR_PEDIDO = 4 
PRECIO_MIN_PRODUCTO = 700
PRECIO_MAX_PRODUCTO = 35000
STOCK_MIN_PRODUCTO = 20
STOCK_MAX_PRODUCTO = 500

# Crear directorio para CSVs si no existe
output_dir = "datos_csv_generados"
os.makedirs(output_dir, exist_ok=True)

fake = Faker('es_ES')

ciudades_chilenas = [
    "Santiago", "Valparaíso", "Concepción", "La Serena", "Antofagasta", "Temuco", "Rancagua",
    "Talca", "Arica", "Iquique", "Puerto Montt", "Chillán", "Copiapó", "Valdivia", "Osorno",
    "Curicó", "Punta Arenas", "Coquimbo", "Viña del Mar", "Calama", "Los Ángeles", "Talagante",
    "Peñaflor", "Melipilla", "San Bernardo", "Puente Alto", "Quillota", "San Felipe", "Los Andes"
]

productos_comida_chilena = [
    ("Empanada de Pino", "Empanadas"), ("Pastel de Choclo", "Platos Principales"), ("Humitas", "Platos Principales"),
    ("Porotos Granados", "Platos Principales"), ("Cazuela de Vacuno", "Sopas y Cazuelas"), ("Sopaipillas con Pebre", "Masas y Frituras"),
    ("Pebre Chileno", "Salsas y Condimentos"), ("Mote con Huesillo", "Bebidas y Postres"), ("Curanto en Olla", "Platos Principales"),
    ("Chapalele", "Masas y Frituras"), ("Milcao", "Masas y Frituras"), ("Charquicán", "Platos Principales"),
    ("Lomo a lo Pobre", "Platos Principales"), ("Chorrillana", "Platos Principales"), ("Completo Italiano", "Comida Rápida"),
    ("Barros Luco", "Sándwiches"), ("Chacarero", "Sándwiches"), ("Alfajor Chileno", "Dulces"),
    ("Leche Asada", "Postres"), ("Pan Amasado", "Panadería"), ("Marraqueta (Pan Batido)", "Panadería"),
    ("Paila Marina", "Sopas y Cazuelas"), ("Reineta Frita con Ensalada Chilena", "Pescados y Mariscos"),
    ("Congrio Frito con Papas Mayo", "Pescados y Mariscos"), ("Salmón a la Plancha con Quinoa", "Pescados y Mariscos"),
    ("Merluza Austral al Horno", "Pescados y Mariscos"), ("Vino Tinto Carmenere (Botella)", "Bebidas Alcohólicas"),
    ("Vino Blanco Sauvignon Blanc (Botella)", "Bebidas Alcohólicas"), ("Pisco Sour Peruano (Preparado)", "Bebidas Alcohólicas"), # Un clásico también
    ("Cerveza Artesanal Valdiviana", "Bebidas Alcohólicas"), ("Jugo de Frambuesa Natural", "Bebidas"),
    ("Bebida Gaseosa Bilz", "Bebidas"), ("Agua Mineral Puyehue con Gas", "Bebidas"),
    ("Palta Hass Fuerte (Malla)", "Frutas y Verduras"), ("Tomate Limachino (1kg)", "Frutas y Verduras"),
    ("Cebolla Morada (1kg)", "Frutas y Verduras"), ("Papas Chilotas (Saco)", "Frutas y Verduras"),
    ("Zapallo Camote (Unidad Grande)", "Frutas y Verduras"), ("Choclo Pastelero (Docena)", "Frutas y Verduras"),
    ("Arroz Grado 2 (1kg)", "Abarrotes"), ("Fideos Cabello de Ángel (Paquete)", "Abarrotes"),
    ("Aceite de Maravilla (Litro)", "Abarrotes"), ("Azúcar Granulada (1kg)", "Abarrotes"),
    ("Sal de Cahuil (Bolsa)", "Abarrotes"), ("Harina con Polvos (1kg)", "Abarrotes"),
    ("Lentejas 6mm (Paquete)", "Abarrotes"), ("Garbanzos Nacionales (Paquete)", "Abarrotes"),
    ("Manjar Colun (Pote Grande)", "Dulces"), ("Mermelada de Mora Casera", "Conservas"),
    ("Queso Chanco de Campo (Trozo)", "Lácteos y Fiambres"), ("Jamón Serrano Tipo Chileno (100g)", "Lácteos y Fiambres"),
    ("Yogurt Batido Soprole", "Lácteos y Fiambres"), ("Leche Entera Loncoleche (Caja)", "Lácteos y Fiambres"),
    ("Huevos de Gallina Feliz (Bandeja)", "Huevos"), ("Café de Grano Tostado Medio", "Abarrotes"), ("Té Ceylán en Bolsitas", "Abarrotes"),
    ("Machas Frescas (Kg)", "Pescados y Mariscos"), ("Ostiones Frescos (Docena)", "Pescados y Mariscos"),
    ("Piure (Kg)", "Pescados y Mariscos"), ("Lochas (Kg)", "Pescados y Mariscos"),
    ("Plateada al Horno", "Platos Principales"), ("Costillar de Cerdo Ahumado", "Platos Principales")
]
nombres_productos_genericos = [
    "Pizza Napolitana Familiar", "Hamburguesa Doble con Queso Cheddar", "Papas Fritas Caseras Grandes",
    "Ensalada Griega con Queso Feta", "Pollo Entero a las Finas Hierbas", "Lasaña Vegetariana",
    "Sushi Tempura Roll (10 piezas)", "Tacos de Birria (4 unidades)", "Sándwich Club House Triple",
    "Torta de Chocolate Selva Negra", "Galletas Surtidas Finas", "Helado Artesanal de Pistacho (1/2 Litro)",
    "Limonada Menta Jengibre (Litro)", "Filete de Res Angus (300g)", "Pechuga de Pollo Deshuesada (1kg)",
    "Costillar de Cerdo BBQ (Rack Completo)", "Spaghetti Carbonara Auténtica", "Ceviche de Salmón y Camarón",
    "Quiche Lorraine Individual", "Muffins de Arándanos (6 unidades)"
]

print(f"Generando {NUM_CLIENTES} clientes...")
clientes_data = []
for i in range(1, NUM_CLIENTES + 1):
    nombre = fake.first_name() + " " + fake.last_name()
    if random.random() < 0.7: # 70% de probabilidad de tener segundo apellido
        nombre += " " + fake.last_name()
    ciudad = random.choice(ciudades_chilenas)
    fecha_nacimiento = fake.date_of_birth(minimum_age=18, maximum_age=85)
    clientes_data.append([i, nombre, ciudad, fecha_nacimiento.strftime('%Y-%m-%d')])

with open(os.path.join(output_dir, 'clientes.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['ClienteID', 'Nombre', 'Ciudad', 'FechaNacimiento'])
    writer.writerows(clientes_data)
print(f"clientes.csv generado en {output_dir}.")

print(f"Generando {NUM_PRODUCTOS} productos...")
productos_data_temp = []
lista_nombres_productos_final = [p[0] for p in productos_comida_chilena]
if len(lista_nombres_productos_final) < NUM_PRODUCTOS:
    needed = NUM_PRODUCTOS - len(lista_nombres_productos_final)
    random.shuffle(nombres_productos_genericos)
    lista_nombres_productos_final.extend(nombres_productos_genericos[:needed])

for i in range(1, min(NUM_PRODUCTOS, len(lista_nombres_productos_final)) + 1):
    nombre_prod = lista_nombres_productos_final[i-1]
    precio = round(random.uniform(PRECIO_MIN_PRODUCTO, PRECIO_MAX_PRODUCTO) / 50) * 50 # Precios redondeados a múltiplo de 50
    productos_data_temp.append([i, nombre_prod, precio])

with open(os.path.join(output_dir, 'productos.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['ProductoID', 'Nombre', 'Precio'])
    writer.writerows(productos_data_temp)
print(f"productos.csv generado en {output_dir}.")

# Generar Inventario
print(f"Generando inventario para {len(productos_data_temp)} productos...")
inventario_data = []
for prod_id, _, _ in productos_data_temp:
    cantidad_productos = random.randint(STOCK_MIN_PRODUCTO, STOCK_MAX_PRODUCTO)
    inventario_data.append([prod_id, cantidad_productos])

with open(os.path.join(output_dir, 'inventario.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['ProductoID', 'CantidadProductos']) # Coincide con sesion1.sql del profesor
    writer.writerows(inventario_data)
print(f"inventario.csv generado en {output_dir}.")


print(f"Generando pedidos y detalles...")
pedidos_data = []
detalles_data = []
pedido_id_counter = 1
detalle_id_counter = 1
cliente_ids = [c[0] for c in clientes_data]
producto_info = {p[0]: {"nombre": p[1], "precio": p[2]} for p in productos_data_temp}
producto_ids_disponibles = list(producto_info.keys())

for cliente_id_actual in cliente_ids:
    num_pedidos_cliente = random.randint(0, MAX_PEDIDOS_POR_CLIENTE) # Algunos clientes pueden no tener pedidos
    for _ in range(num_pedidos_cliente):
        fecha_pedido = fake.date_time_between(start_date='-4y', end_date='now')
        total_pedido_calculado = 0
        
        detalles_para_este_pedido_temp = []
        num_items_en_pedido = random.randint(1, MAX_DETALLES_POR_PEDIDO)
        
        if not producto_ids_disponibles: continue # No hay productos para pedir

        productos_seleccionados_para_pedido = random.sample(
            producto_ids_disponibles, 
            min(num_items_en_pedido, len(producto_ids_disponibles))
        )

        for producto_id_actual in productos_seleccionados_para_pedido:
            cantidad = random.randint(1, 6)
            precio_unitario_venta = producto_info[producto_id_actual]["precio"]
            
            detalles_para_este_pedido_temp.append([detalle_id_counter, pedido_id_counter, producto_id_actual, cantidad, precio_unitario_venta])
            detalle_id_counter += 1
            total_pedido_calculado += cantidad * precio_unitario_venta
        
        if detalles_para_este_pedido_temp: # Solo crear pedido si tiene detalles
            pedidos_data.append([pedido_id_counter, cliente_id_actual, fecha_pedido.strftime('%Y-%m-%d %H:%M:%S'), round(total_pedido_calculado, 2)])
            detalles_data.extend(detalles_para_este_pedido_temp)
            pedido_id_counter += 1

        if pedido_id_counter % 20000 == 0: # Log cada 20,000 pedidos
             print(f"  Generados {pedido_id_counter-1} pedidos y {detalle_id_counter-1} detalles...")


with open(os.path.join(output_dir, 'pedidos.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['PedidoID', 'ClienteID', 'FechaPedido', 'Total'])
    writer.writerows(pedidos_data)
print(f"{len(pedidos_data)} pedidos.csv generado en {output_dir}.")

with open(os.path.join(output_dir, 'detalles_pedidos.csv'), 'w', newline='', encoding='utf-8') as f:
    writer = csv.writer(f)
    writer.writerow(['DetalleID', 'PedidoID', 'ProductoID', 'Cantidad', 'PrecioUnitario'])
    writer.writerows(detalles_data)
print(f"{len(detalles_data)} detalles_pedidos.csv generado en {output_dir}.")

print("--- Generación de todos los archivos CSV completada ---")
total_filas = len(clientes_data) + len(productos_data_temp) + len(inventario_data) + len(pedidos_data) + len(detalles_data)
print(f"Total Clientes: {len(clientes_data)}")
print(f"Total Productos: {len(productos_data_temp)}")
print(f"Total Inventario: {len(inventario_data)}")
print(f"Total Pedidos: {len(pedidos_data)}")
print(f"Total Detalles Pedidos: {len(detalles_data)}")
print(f"SUMA TOTAL DE FILAS GENERADAS (aprox): {total_filas}")
if total_filas > 1900000 :
    print("¡Objetivo de ~2 millones de filas alcanzado o superado!")

