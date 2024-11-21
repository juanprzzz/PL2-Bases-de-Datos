\pset pager off

SET client_encoding = 'UTF8';

BEGIN;

--------------------------------Tablas finales----------------------------

\echo 'Creando el esquema final para la BBDD'

CREATE TABLE IF NOT EXISTS grupo(
    nombre_grupo TEXT,
    URL TEXT, 
    CONSTRAINT grupo_pk PRIMARY KEY (nombre_grupo)
);
CREATE TABLE IF NOT EXISTS disco(
    nombre_grupo TEXT,

    titulo_disco TEXT,
    anio_publicacion SMALLINT,
    url_portada TEXT,
    CONSTRAINT disco_pk PRIMARY KEY (titulo_disco,anio_publicacion),
    CONSTRAINT disco_fk FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre_grupo) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);



CREATE TABLE IF NOT EXISTS genero( 
    titulo_disco TEXT,
    anio_publicacion SMALLINT,

    genero TEXT,
    CONSTRAINT genero_pk PRIMARY KEY (genero,titulo_disco,anio_publicacion),
    CONSTRAINT genero_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)  MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

CREATE TABLE IF NOT EXISTS edicion(
    titulo_disco TEXT,
    anio_publicacion SMALLINT,
    formato TEXT,
    pais text,
    anio_edicion SMALLINT,
    CONSTRAINT edicion_pk PRIMARY KEY (formato,anio_edicion,pais,titulo_disco,anio_publicacion), --titulo_disco,anio_publicacion
    CONSTRAINT edicion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE  
);

CREATE TABLE IF NOT EXISTS cancion(
    titulo_disco TEXT,
    anio_publicacion SMALLINT,
    
    titulo_cancion TEXT,
    duracion TIME,
    CONSTRAINT cancion_pk PRIMARY KEY (titulo_cancion,titulo_disco,anio_publicacion),
    CONSTRAINT cancion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE   
);

CREATE TABLE IF NOT EXISTS usuario( 
    nombre_usuario TEXT,
    nombre TEXT NOT NULL,
    email TEXT NOT  NULL,
    passwd TEXT NOT NULL,
    CONSTRAINT usuario_pk PRIMARY KEY (nombre_usuario)
);


--------------RELACIONES-----------------

CREATE TABLE IF NOT EXISTS desea( --disco-usuario 
    titulo_disco TEXT,
    anio_publicacion SMALLINT,
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
    anio_edicion SMALLINT,
    titulo_disco TEXT,
    anio_publicacion SMALLINT,
    nombre_usuario TEXT,
    estado TEXT,  
    CONSTRAINT tiene_pk PRIMARY KEY (formato,pais,anio_edicion,nombre_usuario,titulo_disco,anio_publicacion ),
    CONSTRAINT tiene_edicion_fk FOREIGN KEY (formato,anio_edicion,pais,titulo_disco,anio_publicacion) REFERENCES edicion(formato,anio_edicion,pais,titulo_disco,anio_publicacion) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT tiene_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario) MATCH FULL
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

\COPY discoscsv FROM 'discos.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY usuarioscsv FROM 'usuarios.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY cancionescsv FROM 'canciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY edicionescsv FROM 'ediciones.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY usuarioDeseaDisco FROM 'usuario_desea_disco.csv' DELIMITER ';' CSV HEADER NULL 'NULL';
\COPY usuarioTieneEdicion FROM 'usuario_tiene_edicion.csv' DELIMITER ';' CSV HEADER NULL 'NULL';


------------------pasamos de temporales a finales---------------------

INSERT INTO grupo (nombre_grupo, URL)
SELECT DISTINCT ON (nombreGrupo)
NombreGrupo,
urlGrupo 
FROM discoscsv;

INSERT INTO disco (titulo_disco, anio_publicacion, nombre_grupo, url_portada)
SELECT DISTINCT ON (NombreDisco, añoLanzamiento)
    NombreDisco, 
        CAST(añoLanzamiento AS SMALLINT),  
       NombreGrupo,
       urlPortada
FROM discoscsv;

INSERT INTO genero (titulo_disco, anio_publicacion, genero)
SELECT DISTINCT ON (nombreDisco, añoLanzamiento)
NombreDisco,
       CAST(añoLanzamiento AS SMALLINT),
       regexp_split_to_table(
           regexp_replace(trim(both '[]' from generos), '''', '', 'g'),  
           '\s*,\s*'
       )
FROM discoscsv;    

INSERT INTO edicion (titulo_disco, anio_publicacion, formato, pais, anio_edicion)
SELECT DISTINCT ON (NombreDisco, añoLanzamiento, formato, paisEdicion, añoEdicion)
disco.NombreDisco,
       CAST(disco.añoLanzamiento AS SMALLINT),
       edicion.formato,
       edicion.paisEdicion,
       CAST(edicion.añoEdicion  AS SMALLINT)
FROM discoscsv disco JOIN edicionescsv edicion ON disco.idDisco = edicion.idDisco;

INSERT INTO usuario (nombre_usuario, nombre, email, passwd)
SELECT  DISTINCT ON (nombreUsuario)
nombreUsuario,
       nombreCompleto,
       email,
       passwd
FROM usuarioscsv;

INSERT INTO tiene (formato,pais,anio_edicion,titulo_disco,anio_publicacion,nombre_usuario,estado)
SELECT DISTINCT ON (formato, paisEdicion, añoEdicion, tituloDisco, añoLanzamiento, nombreUsuario)
    usuarioTieneEdicion.formato,
    usuarioTieneEdicion.paisEdicion,
    CAST(usuarioTieneEdicion.añoEdicion AS SMALLINT),
    usuarioTieneEdicion.tituloDisco,
    CAST(usuarioTieneEdicion.añoLanzamiento AS SMALLINT),
    usuarioTieneEdicion.nombreUsuario,
    usuarioTieneEdicion.estado
FROM usuarioTieneEdicion JOIN usuario ON usuario.nombre_usuario = usuarioTieneEdicion.nombreUsuario 
    /*JOIN edicion ON (
    edicion.formato = usuarioTieneEdicion.formato AND 
    edicion.anio_edicion  = CAST(usuarioTieneEdicion.añoEdicion AS SMALLINT) AND 
    edicion.pais = usuarioTieneEdicion.paisEdicion AND 
    edicion.titulo_disco = usuarioTieneEdicion.tituloDisco AND 
    edicion.anio_publicacion = CAST(usuarioTieneEdicion.añoLanzamiento AS SMALLINT))*/
;
SELECT * from tiene LIMIT 10;

INSERT INTO desea (titulo_disco, anio_publicacion, nombre_usuario)
SELECT DISTINCT ON (tituloDisco, añoLanzamiento, nombreUsuario)
    tituloDisco,
       CAST(añoLanzamiento AS SMALLINT),
       nombreUsuario
FROM usuarioDeseaDisco JOIN usuario ON usuario.nombre_usuario = usuarioDeseaDisco.nombreUsuario JOIN disco ON (disco.titulo_disco= usuarioDeseaDisco.tituloDisco AND disco.anio_publicacion = CAST(usuarioDeseaDisco.añoLanzamiento AS SMALLINT));


INSERT INTO cancion(titulo_disco, anio_publicacion, titulo_cancion, duracion)
SELECT DISTINCT ON (tituloCancion, NombreDisco, añoLanzamiento)
disco.NombreDisco, 
    CAST(disco.añoLanzamiento AS SMALLINT), 
    cancion.tituloCancion, 
    MAKE_INTERVAL (
            mins => SPLIT_PART(cancion.duracion, ':', 1)::INTEGER, 
            secs => split_part(cancion.duracion, ':', 2)::INTEGER) ::TIME
            FROM discoscsv disco JOIN cancionescsv cancion ON disco.idDisco = cancion.idDisco;

---------------------\o prueba.txt

\echo '-----------------------MOSTRANDO CONSULTAS--------------------'

\echo 'Consulta 1'
--1. Mostrar los discos que tengan más de 5 canciones. Construir la expresión equivalente en álgebra relacional.
SELECT cancion.titulo_disco, cancion.anio_publicacion
FROM cancion
GROUP BY cancion.titulo_disco,  cancion.anio_publicacion
HAVING COUNT(*) > 5
ORDER BY cancion.anio_publicacion, cancion.titulo_disco;

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
WHERE usuario.nombre = 'Juan García Gómez'
ORDER BY edicion.anio_edicion, edicion.titulo_disco;
\echo 'Consulta 3' 
--3. Disco con mayor duración de la colección. Construir la expresión equivalente en álgebra relacional.
WITH  disco_duracion AS(
    SELECT c.titulo_disco, SUM(c.duracion) AS duracion_total
    FROM cancion c
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
WHERE u.nombre= 'Juan García Gómez'
ORDER BY d.anio_publicacion, d.titulo_disco;

\echo 'Consulta 5'
--5. Mostrar los discos publicados entre 1970 y 1972 junto con sus ediciones ordenados por el año de publicación.
SELECT e.*
FROM edicion e JOIN disco d ON d.titulo_disco = e.titulo_disco AND d.anio_publicacion=e.anio_publicacion
WHERE d.anio_publicacion BETWEEN '1970' AND '1972'
ORDER BY e.anio_publicacion, e.anio_edicion, d.titulo_disco;

\echo 'Consulta 6'
--6. Listar el nombre de todos los grupos que han publicado discos del género ‘Electronic’. Construir la expresión equivalente en álgebra relacional.
SELECT DISTINCT d.nombre_grupo
FROM disco d JOIN genero g ON g.titulo_disco=d.titulo_disco AND g.anio_publicacion=d.anio_publicacion
WHERE g.genero='Electronic';

\echo 'Consulta 7'
--7. Lista de discos con la duración total del mismo, editados antes del año 2000.
SELECT  d.titulo_disco, 
        d.anio_publicacion,
        e.anio_edicion,
        SUM(c.duracion) AS duracion_total
FROM disco d JOIN edicion e ON e.titulo_disco=d.titulo_disco AND e.anio_publicacion=d.anio_publicacion
    JOIN cancion c ON d.titulo_disco = c.titulo_disco AND d.anio_publicacion = c.anio_publicacion
WHERE e.anio_edicion <=2000 AND e.anio_edicion > 0
GROUP BY 
    d.titulo_disco, d.anio_publicacion, e.anio_edicion
ORDER BY e.anio_edicion desc, d.anio_publicacion;

\echo 'Consulta 8' ----NOMBRES CAMBIADOS YA QUE LORENA NO DESEABA NINGÚN DISCO DE JUAN GARCÍA GÓMEZ
--8. Lista de ediciones de discos deseados por el usuario Lorena Sáez Pérez que tiene el usuario Juan García Gómez
WITH juan_gomez_tiene as(
    SELECT t.titulo_disco, t.anio_publicacion
    FROM tiene t JOIN usuario u ON t.nombre_usuario = u.nombre_usuario
    WHERE u.nombre = 'Marta Díaz Moreno'
)
SELECT d.titulo_disco, d.anio_publicacion
FROM desea d JOIN juan_gomez_tiene jg ON d.titulo_disco=jg.titulo_disco
JOIN usuario u ON u.nombre_usuario = d.nombre_usuario
WHERE u.nombre = 'Marta Moreno Díaz';

\echo 'Consulta 9' 
--9. Lista todas las ediciones de los discos que tiene el usuario Gómez García en un estado NM o M. Construir la expresión equivalente en álgebra relacional.
SELECT  t.formato,
        t.pais,
        t.anio_edicion,
        t.titulo_disco,
        t.anio_publicacion
FROM tiene t JOIN usuario u ON u.nombre_usuario=t.nombre_usuario
WHERE u.nombre = 'Juan García Gómez' AND t.estado IN ('NM', 'M');

\echo 'Consulta 10'
--10. Listar todos los usuarios junto al número de ediciones que tiene de todos los discos junto al año de lanzamiento de su disco más antiguo, el año de lanzamiento de su disco más nuevo, y el año medio de todos sus discos de su colección
SELECT 
    u.nombre, 
    COUNT(t.titulo_disco) AS Nº_ediciones, 
    MIN(t.anio_publicacion) AS disco_más_antiguo, 
    MAX(t.anio_publicacion) AS disco_más_nuevo, 
    ROUND(AVG(t.anio_publicacion)) AS media_años
FROM usuario u JOIN tiene t ON u.nombre_usuario = t.nombre_usuario
WHERE t.anio_publicacion>0
GROUP BY u.nombre
ORDER BY u.nombre;

\echo 'Consulta 11'
--11. Listar el nombre de los grupos que tienen más de 5 ediciones de sus discos en la base de datos
SELECT  d.nombre_grupo
FROM disco d JOIN edicion e ON (e.titulo_disco = d.titulo_disco AND e.anio_publicacion = d.anio_publicacion)
GROUP BY 
    d.nombre_grupo
HAVING 
    COUNT(*) > 5
ORDER BY d.nombre_grupo;

\echo 'Consulta 12'
--12. Lista el usuario que más discos, contando todas sus ediciones tiene en la base de datos
WITH total_ediciones AS(
    SELECT t.nombre_usuario, COUNT(*) AS total_ediciones
    FROM tiene t
    GROUP BY t.nombre_usuario
)
SELECT u.nombre_usuario, te.total_ediciones
FROM usuario u JOIN total_ediciones te ON u.nombre_usuario = te.nombre_usuario
WHERE te.total_ediciones=(SELECT MAX(total_ediciones)
        FROM total_ediciones);

ROLLBACK;