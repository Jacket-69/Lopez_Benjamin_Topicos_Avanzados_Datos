
```
 ██████  ██████  ██████  ██████  ███████ ██       ██████   █████  
██      ██    ██ ██   ██ ██   ██ ██      ██      ██    ██ ██   ██ 
██      ██    ██ ██████  ██████  █████   ██      ██    ██ ███████ 
██      ██    ██ ██   ██ ██   ██ ██      ██      ██    ██ ██   ██ 
 ██████  ██████  ██████  ██   ██ ███████ ███████  ██████  ██   ██ 



                                         _.oo.
                 _.u[[/;:,.         .odMMMMMM'
              .o888UU[[[/;:-.  .o@P^    MMM^
             oN88888UU[[[/;::-.        dP^
            dNMMNN888UU[[[/;:--.   .o@P^
           ,MMMMMMN888UU[[/;::-. o@^
           NNMMMNN888UU[[[/~.o@P^
           888888888UU[[[/o@^-..
          oI8888UU[[[/o@P^:--..
       .@^  YUU[[[/o@^;::---..
     oMP     ^/o@P^;:::---..
  .dMMM    .o@^ ^;::---...
 dMMMMMMM@^`       `^^^^
YMMMUP^
 ^^

*Trucazos*

# 1. Limpiar Completamente el Entorno Docker Anterior
    docker-compose down -v
# 2. Construir las Imágenes Docker
    docker-compose build
# 3. Iniciar Todos los Servicios
    docker-compose up -d
# 4.  Verificar la Base de Datos
    docker-compose logs -f oracle-db
# 5. Ejecutar el Script de Python para Generar los Archivos CSV
    docker-compose exec data-inserter python generador_datos.py
# 6. Ejecutar el Script de Carga SQL*Loader
    docker-compose exec oracle-db bash /opt/oracle/scripts/cargar_datos.sh
# 7. Acceder al contenedor de Oracle
   docker-compose exec oracle-db bash
# 8. Iniciar sesión en SQL*Plus
   sqlplus curso_topicos/curso2025@//localhost:1521/XEPDB1

Comandos Útiles:

@/tmp/sesion*.sql

```

