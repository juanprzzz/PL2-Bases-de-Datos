\pset pager off

SET client_encoding = 'UTF8';

BEGIN;

--------------------------------Tablas finales----------------------------

\echo 'creando el esquema final para la BBDD'

CREATE TABLE IF NOT EXISTS grupo(
    nombre_grupo TEXT,
    URL TEXT, 
    CONSTRAINT grupo_pk PRIMARY KEY (nombre_grupo)
);
CREATE TABLE IF NOT EXISTS disco(
    nombre_grupo TEXT,

    titulo_disco TEXT,
    anio_publicacion TEXT,
    url_portada TEXT,
    CONSTRAINT disco_pk PRIMARY KEY (titulo_disco,anio_publicacion),
    CONSTRAINT disco_fk FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre_grupo) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);



CREATE TABLE IF NOT EXISTS genero( 
    titulo_disco TEXT,
    anio_publicacion TEXT,

    genero TEXT,
    CONSTRAINT genero_pk PRIMARY KEY (genero,titulo_disco,anio_publicacion),
    CONSTRAINT genero_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)  MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

CREATE TABLE IF NOT EXISTS edicion(
    titulo_disco TEXT,
    anio_publicacion TEXT,
    formato TEXT,
    pais text,
    anio_edicion TEXT,
    CONSTRAINT edicion_pk PRIMARY KEY (formato,anio_edicion,pais,titulo_disco,anio_publicacion), --titulo_disco,anio_publicacion
    CONSTRAINT edicion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE  
);

CREATE TABLE IF NOT EXISTS cancion(
    titulo_disco TEXT,
    anio_publicacion TEXT,
    
    titulo_cancion TEXT,
    duracion TIME,
    CONSTRAINT cancion_pk PRIMARY KEY (titulo_cancion,titulo_disco,anio_publicacion), ----debil identificativa
    CONSTRAINT cancion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE   
);

CREATE TABLE IF NOT EXISTS usuario( 
    nombre_usuario TEXT,
    nombre TEXT,
    email TEXT,
    passwd TEXT,
    CONSTRAINT usuario_pk PRIMARY KEY (nombre_usuario)
);


--------------RELACIONES-----------------

CREATE TABLE IF NOT EXISTS desea( --disco-usuario 
    titulo_disco TEXT,
    anio_publicacion TEXT,
    nombre_usuario TEXT, 
    CONSTRAINT desea_pk PRIMARY KEY (titulo_disco,anio_publicacion,nombre_usuario),
    CONSTRAINT desea_disco_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE, 
    CONSTRAINT desea_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario)  MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

CREATE TABLE IF NOT EXISTS tiene( --usuario-ediciones 
    formato TEXT,
    pais TEXT,
    anio_edicion TEXT,
    titulo_disco TEXT,
    anio_publicacion TEXT,
    nombre_usuario TEXT,
    estado TEXT,  
    CONSTRAINT tiene_pk PRIMARY KEY (formato,pais,anio_edicion,nombre_usuario,titulo_disco,anio_publicacion ),
    CONSTRAINT tiene_edicion_fk FOREIGN KEY (formato,anio_edicion,pais,titulo_disco,anio_publicacion) REFERENCES edicion(formato,anio_edicion,pais,titulo_disco,anio_publicacion) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT tiene_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario) MATCH FULL --poner la coma antes de restrict???????
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

-----------------------------------------tablas temporales----------------------------------
\echo 'Creando un esquema temporal...'
CREATE TABLE IF NOT EXISTS discoscsv(
    idDisco TEXT,
    NombreDisco TEXT,
    añoLanzamiento TEXT,
    idGrupo TEXT,
    NombreGrupo TEXT,
    urlGrupo TEXT,
    generos TEXT,
    urlPortada TEXT
);
CREATE TABLE IF NOT EXISTS usuarioscsv(
    nombreCompleto TEXT,
    nombreUsuario TEXT,
    email TEXT,
    passwd TEXT
);
CREATE TABLE IF NOT EXISTS cancionescsv(
    idDisco TEXT,
    tituloCancion TEXT,
    duracion TEXT
    
);
CREATE TABLE IF NOT EXISTS edicionescsv(
    idDisco TEXT,
    añoEdicion TEXT,
    paisEdicion TEXT,
    formato TEXT
);
CREATE TABLE IF NOT EXISTS usuarioDeseaDisco(
    nombreUsuario TEXT,
    tituloDisco TEXT,
    añoLanzamiento TEXT
);
CREATE TABLE IF NOT EXISTS usuarioTieneEdicion(
    nombreUsuario TEXT,
    tituloDisco TEXT,
    añoLanzamiento TEXT,
    añoEdicion TEXT,
    paisEdicion TEXT,
    formato TEXT,
    estado TEXT
);

\COPY discoscsv FROM 'discos.csv' DELIMITER ';' CSV HEADER NULL 'NULL'; ---tener en cuenta que puede haber nulos. cargar strings null como null real para que no lo cargue como text null
\COPY usuarioscsv FROM 'usuarios.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY cancionescsv FROM 'canciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY edicionescsv FROM 'ediciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY usuarioDeseaDisco FROM 'usuario_desea_disco.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY usuarioTieneEdicion FROM 'usuario_tiene_edicion.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\echo 'HTTP1.1 200 OK prueba2.sql'

------------------pasamos de temporales a finales---------------------

INSERT INTO grupo (nombre_grupo, URL)
SELECT DISTINCT ON (nombreGrupo)
NombreGrupo,
urlGrupo 
FROM discoscsv;
\echo 'grupo hecho'

INSERT INTO disco (titulo_disco, anio_publicacion, nombre_grupo, url_portada)
SELECT DISTINCT ON (NombreDisco, añoLanzamiento)
    NombreDisco, 
        añoLanzamiento,  
       NombreGrupo,
       urlPortada
FROM discoscsv;
\echo 'disco hecho'

--descomponer genero en varias filas
INSERT INTO genero (titulo_disco, anio_publicacion, genero)
SELECT DISTINCT ON (nombreDisco, añoLanzamiento)
NombreDisco,
       añoLanzamiento,
       regexp_split_to_table(
           regexp_replace(trim(both '[]' from generos), '''', '', 'g'),  -- Elimina las comillas simples
           '\s*,\s*'  -- Divide en filas usando la coma (con espacios opcionales alrededor)
       )
FROM discoscsv;
\echo 'genero hecho'    

INSERT INTO edicion (titulo_disco, anio_publicacion, formato, pais, anio_edicion)
SELECT DISTINCT ON (NombreDisco, añoLanzamiento, formato, paisEdicion, añoEdicion)
disco.NombreDisco,
       disco.añoLanzamiento,
       edicion.formato,
       edicion.paisEdicion,
       edicion.añoEdicion 
FROM discoscsv disco JOIN edicionescsv edicion ON disco.idDisco = edicion.idDisco;
\echo 'edicion hecho'


INSERT INTO usuario (nombre_usuario, nombre, email, passwd)
SELECT  DISTINCT ON (nombreUsuario)
nombreUsuario,
       nombreCompleto,
       email,
       passwd
FROM usuarioscsv;
\echo 'usuario hecho'


INSERT INTO tiene (formato,pais,anio_edicion,titulo_disco,anio_publicacion,nombre_usuario,estado)
SELECT DISTINCT ON (formato, paisEdicion, añoEdicion, tituloDisco, añoLanzamiento, nombreUsuario)
    usuarioTieneEdicion.formato,
    usuarioTieneEdicion.paisEdicion,
    usuarioTieneEdicion.añoEdicion,
    usuarioTieneEdicion.tituloDisco,
    usuarioTieneEdicion.añoLanzamiento,
    usuarioTieneEdicion.nombreUsuario,
    usuarioTieneEdicion.estado
FROM usuarioTieneEdicion JOIN usuario ON usuario.nombre_usuario = usuarioTieneEdicion.nombreUsuario 
    JOIN edicion ON (
    edicion.formato = usuarioTieneEdicion.formato AND 
    edicion.anio_edicion = usuarioTieneEdicion.añoEdicion AND 
    edicion.pais = usuarioTieneEdicion.paisEdicion AND 
    edicion.titulo_disco = usuarioTieneEdicion.tituloDisco AND 
    edicion.anio_publicacion = usuarioTieneEdicion.añoLanzamiento
);
\echo 'tiene hecho'

INSERT INTO desea (titulo_disco, anio_publicacion, nombre_usuario)
SELECT DISTINCT ON (tituloDisco, añoLanzamiento, nombreUsuario)
    tituloDisco,
       añoLanzamiento,
       nombreUsuario
FROM usuarioDeseaDisco JOIN usuario ON usuario.nombre_usuario = usuarioDeseaDisco.nombreUsuario JOIN disco ON (disco.titulo_disco= usuarioDeseaDisco.tituloDisco AND disco.anio_publicacion = usuarioDeseaDisco.añoLanzamiento);
\echo 'desea hecho'


INSERT INTO cancion(titulo_disco, anio_publicacion, titulo_cancion, duracion)
SELECT DISTINCT ON (tituloCancion, NombreDisco, añoLanzamiento)
disco.NombreDisco, 
    disco.añoLanzamiento, 
    cancion.tituloCancion, 
    MAKE_INTERVAL (
            mins => SPLIT_PART(cancion.duracion, ':', 1)::INTEGER, 
            secs => split_part(cancion.duracion, ':', 2)::INTEGER) ::TIME --PROBAR QUE FUNCIONE --Duración es de la forma 00:00 hay que pasarlo a time
FROM discoscsv disco JOIN cancionescsv cancion ON disco.idDisco = cancion.idDisco;--Tengo que juntar las dos tablas para conseguir los datos que quiero
\echo 'cancion hecho'

\echo '-----------------------MOSTRANDO TABLAS--------------------'

SELECT * FROM cancion LIMIT 10; 
\d cancion;
SELECT * FROM desea LIMIT 10; ---Algunos indica año 0,en el csv original tambien, pero quizas lo pone para indicar null
\d desea;
SELECT * FROM disco LIMIT 10; 
\d disco;
SELECT * FROM edicion LIMIT 10; 
\d edicion;
SELECT * FROM genero LIMIT 10; 
\d genero;
SELECT * FROM grupo LIMIT 10; 
\d grupo;
SELECT * FROM tiene LIMIT 10; 
\d tiene;
SELECT * FROM usuario LIMIT 10; 
\d usuario;
---------------------\o prueba.txt

\echo '-----------------------MOSTRANDO CONSULTAS--------------------'

\echo 'Consulta 1'
---REVISADO
--1. Mostrar los discos que tengan más de 5 canciones. Construir la expresión equivalente en álgebra relacional.
SELECT cancion.titulo_disco, cancion.anio_publicacion
FROM cancion
GROUP BY cancion.titulo_disco,  cancion.anio_publicacion
HAVING COUNT(*) > 5;

\echo 'Consulta 2' 
-- Mostrar los vinilos que tiene el usuario Juan García Gómez junto con el título del disco, y el país y año de edición del mismo
SELECT edicion.titulo_disco, edicion.pais, edicion.anio_edicion
FROM edicion 
JOIN tiene ON (
    edicion.formato = tiene.formato AND 
    edicion.pais = tiene.pais AND 
    edicion.anio_edicion = tiene.anio_edicion AND 
    edicion.titulo_disco = tiene.titulo_disco AND 
    edicion.anio_publicacion = tiene.anio_publicacion
)
JOIN usuario ON tiene.nombre_usuario = usuario.nombre_usuario
WHERE usuario.nombre = 'Juan García Gómez'; --usuario.nombre_usuario = 'juangomez'
\echo 'Consulta 3' 
--3. Disco con mayor duración de la colección. Construir la expresión equivalente en álgebra relacional.

WITH  disco_duracion AS(
    SELECT c.titulo_disco, SUM(c.duracion) AS duracion_total
    FROM cancion c --JOIN disco d ON (c.titulo_disco=d.titulo_disco && c.anio_publicacion=d.anio_publicacion)
    GROUP BY (c.titulo_disco)
)

SELECT dd.titulo_disco, dd.duracion_total
FROM disco_duracion dd
WHERE duracion_total=(SELECT MAX(duracion_total) FROM disco_duracion dd);


\echo 'Consulta 4'
--4. De los discos que tiene en su lista de deseos el usuario Juan García Gómez, indicar el nombre de los grupos musicales que los interpretan.
SELECT  d.titulo_disco, 
        d.anio_publicacion, 
        d.nombre_grupo
FROM usuario u JOIN desea ds ON u.nombre_usuario=ds.nombre_usuario
    JOIN disco d ON ds.titulo_disco=d.titulo_disco AND ds.anio_publicacion=d.anio_publicacion
WHERE u.nombre= 'Juan García Gómez';--u.nombre_usuario='juangomez'

\echo 'Consulta 5' --REVISADO (QUITAR LIMIT) ¿Cómo puede salir antes una edición que un disco?
SELECT e.*
FROM edicion e JOIN disco d ON d.titulo_disco = e.titulo_disco AND d.anio_publicacion=e.anio_publicacion
WHERE d.anio_publicacion BETWEEN '1970' AND '1972'
ORDER BY d.titulo_disco, e.anio_publicacion;
--5. Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones ordenados por el año de publicación.
/*SELECT  d.titulo_disco, 
        d.anio_publicacion, 
        d.nombre_grupo,
        e.formato,
        e.pais,
        e.anio_edicion
FROM disco d JOIN edicion e ON e.titulo_disco=d.titulo_disco AND e.anio_publicacion=d.anio_publicacion
WHERE CAST(d.anio_publicacion AS INTEGER)>=1970 AND CAST(d.anio_publicacion AS INTEGER)<=1972  ---se podria usar between tambien?
ORDER BY d.anio_publicacion
LIMIT 50;*/
SELECT e.titulo_disco, 
       e.anio_publicacion, 
       e.formato,
       e.pais,
       e.anio_edicion
FROM edicion e
WHERE CAST(e.anio_publicacion AS INTEGER) BETWEEN 1970 AND 1972
ORDER BY e.anio_publicacion;


\echo 'Consulta 6'
--6. Listar el nombre de todos los grupos que han publicado discos del género ‘Electronic’. Construir la expresión equivalente en álgebra relacional.
SELECT DISTINCT d.nombre_grupo  --distinct para que cada grupo salga solo 1 vez
FROM disco d JOIN genero g ON g.titulo_disco=d.titulo_disco AND g.anio_publicacion=d.anio_publicacion
WHERE g.genero='Electronic';

\echo 'Consulta 7'
---------------------------   salen duraciones null. es normal?
--7. Lista de discos con la duración total del mismo, editados antes del año 2000.

SELECT  d.titulo_disco, 
        d.anio_publicacion,
        e.anio_edicion, --sobra, debug
        SUM(c.duracion) AS duracion_total --duracion en minutos 
FROM disco d JOIN edicion e ON e.titulo_disco=d.titulo_disco AND e.anio_publicacion=d.anio_publicacion
    JOIN cancion c ON d.titulo_disco = c.titulo_disco AND d.anio_publicacion = c.anio_publicacion
WHERE CAST(e.anio_edicion AS INTEGER)<=2000
GROUP BY 
    d.titulo_disco, d.anio_publicacion, e.anio_edicion --si no pongo esto da error
ORDER BY e.anio_edicion desc --sobra, debug
LIMIT 50;

\echo 'Consulta 8' ----REVISADO (NOMBRES CAMBIADOS YA QUE LORENA NO DESEABA NINGÚN DISCO DE JUAN GARCÍA GÓMEZ)
/*
--8. Lista de ediciones de discos deseados por el usuario Lorena Sáez Pérez que tiene el usuario Juan García Gómez
USAMOS SUBCONSULTA TEMPORAL CON WITH PARA SIMPLIFICAR
PRIMERO CREAMOS UNA SUBCONSULTA CON WITH PARA SABER LOS DISCOS QUE TIENE JUAN GARCÍA GÓMEZ
*/
WITH juan_gomez_tiene as(
    SELECT t.titulo_disco, t.anio_publicacion
    FROM tiene t JOIN usuario u ON t.nombre_usuario = u.nombre_usuario
    WHERE u.nombre = 'Marta Díaz Moreno'
)
--AHORA HACEMOS UN JOIN ENTRE LOS QUE TIENE JUAN GARCÍA GÓMEZ Y LOS QUE DESEA LORENA (EN EL CSV NO HAY NINGUNO)
SELECT d.titulo_disco, d.anio_publicacion
FROM desea d JOIN juan_gomez_tiene jg ON d.titulo_disco=jg.titulo_disco
JOIN usuario u ON u.nombre_usuario = d.nombre_usuario
WHERE u.nombre = 'Marta Moreno Díaz';

\echo 'Consulta 9' 
--9. Lista todas las ediciones de los discos que tiene el usuario Gómez García en un estado NM o M. Construir la expresión equivalente en álgebra relacional.
SELECT  e.formato,
        e.pais,
        e.anio_edicion,
        e.titulo_disco,
        e.anio_publicacion
FROM edicion e JOIN tiene t ON (
    e.formato = t.formato AND 
    e.pais = t.pais AND 
    e.anio_edicion = t.anio_edicion AND 
    e.titulo_disco = t.titulo_disco AND 
    e.anio_publicacion = t.anio_publicacion
) JOIN usuario u ON u.nombre_usuario=t.nombre_usuario
WHERE u.nombre = 'Juan García Gómez' AND t.estado IN ('NM', 'M'); --AND (t.estado='NM' OR t.estado='M') --t.nombre_usuario='juangomez'


\echo 'Consulta 10'---REVISADO (HAY AÑOS 0)
--10. Listar todos los usuarios junto al número de ediciones que tiene de todos los discos junto al año de lanzamiento de su disco más antiguo, el año de lanzamiento de su disco más nuevo, y el año medio de todos sus discos de su colección
SELECT u.nombre, 
COUNT(t.titulo_disco) AS Nº_ediciones, 
MIN(t.anio_publicacion) AS disco_más_antiguo, 
MAX(t.anio_publicacion) AS disco_más_nuevo, 
CAST(AVG(CAST(t.anio_publicacion AS SMALLINT))AS SMALLINT) AS media_años
FROM usuario u JOIN tiene t ON u.nombre_usuario = t.nombre_usuario
GROUP BY u.nombre;
\echo 'Consulta 11'
------------------------------------revisar
--11. Listar el nombre de los grupos que tienen más de 5 ediciones de sus discos en la base de datos
SELECT  d.nombre_grupo
FROM disco d JOIN edicion e ON (e.titulo_disco = d.titulo_disco AND e.anio_publicacion = d.anio_publicacion)
GROUP BY 
    d.nombre_grupo
HAVING 
    COUNT(*) > 5;

\echo 'Consulta 12'

WITH total_ediciones AS(
    SELECT t.nombre_usuario, COUNT(*) AS total_ediciones
    FROM tiene t
    GROUP BY t.nombre_usuario
)--WITH ES UNA SUBCONSULTA (CREA UNA TABLA TEMPORAL DONDE SE MUESTRA CADA USUARIO Y TOTAL EDICIÓN DE CADA UNO)
--DESPUÉS DEL WITH HAY QUE HACER SIEMPRE UNA CONSULTA
SELECT u.nombre_usuario, te.total_ediciones
FROM usuario u JOIN total_ediciones te ON u.nombre_usuario = te.nombre_usuario
WHERE te.total_ediciones=(SELECT MAX(total_ediciones)
        FROM total_ediciones);













ROLLBACK;


--para la hora: Make interval, split por los :, tochar(intervalo) h:m:s para coger el intervalo y pasarlo a caracteres , cast a time (con duracion::time)
--para los generos: para quitar [''] con replace (solo reemplaza 1 char) o regexp_replace (meter expresion regular)
--para evitar error por clave duplicada
--insert into usuarios      select      distinct on(nombreUsuario),email,.....//resto de atrib

