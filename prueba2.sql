\pset pager off

SET client_encoding = 'UTF8';

BEGIN;
 /*
 \echo 'creando el esquema para la base de datos de discos'
\echo 'creando esquema temporal. para cargar temporalmente los datos del csv'
SET search_path='nombre del esquema/s usado'
\echo 'cargando datos'
\echo 'insertando datos en esquema final'



restricciones de tabla=claves primarias (usar CONSTRAINT nombreidentificarclave PRIMARY_KEY (atrib1,atrib2...)) y foraneas 




*/
--------------------------------Tablas finales----------------------------

\echo 'creando el esquema para la BBDD de películas'

CREATE TABLE IF NOT EXISTS grupo(----------corregido
    nombre_grupo TEXT,
    URL TEXT, -------------------------me da miedo que este rojo
    CONSTRAINT grupo_pk PRIMARY KEY (nombre_grupo)
);
CREATE TABLE IF NOT EXISTS disco( ------------------------corregido
    nombre_grupo TEXT,

    titulo_disco TEXT,
    anio_publicacion TEXT,
    url_portada TEXT,
    CONSTRAINT disco_pk PRIMARY KEY (titulo_disco,anio_publicacion),
    CONSTRAINT disco_fk FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre_grupo) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);



CREATE TABLE IF NOT EXISTS genero( -----------------------corregido
    titulo_disco TEXT,
    anio_publicacion TEXT,

    genero TEXT,
    CONSTRAINT genero_pk PRIMARY KEY (genero,titulo_disco,anio_publicacion),
    CONSTRAINT genero_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)  MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

CREATE TABLE IF NOT EXISTS edicion(-----------------------corregido
    titulo_disco TEXT,
    anio_publicacion TEXT,

    formato TEXT,
    pais text,
    anio_edicion TEXT,
    CONSTRAINT edicion_pk PRIMARY KEY (formato,anio_edicion,pais), --titulo_disco,anio_publicacion
    CONSTRAINT edicion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE  
);

CREATE TABLE IF NOT EXISTS cancion(-----------------------corregido
    titulo_disco TEXT,
    anio_publicacion TEXT,
    
    titulo_cancion TEXT,
    duracion TIME,
    CONSTRAINT cancion_pk PRIMARY KEY (titulo_cancion,titulo_disco,anio_publicacion), ----debil identificativa
    CONSTRAINT cancion_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE   
);

CREATE TABLE IF NOT EXISTS usuario( --------corregido
    nombre_usuario TEXT,
    nombre TEXT,
    email TEXT,
    passwd TEXT,
    CONSTRAINT usuario_pk PRIMARY KEY (nombre_usuario)
);


--------------RELACIONES-----------------

CREATE TABLE IF NOT EXISTS desea( --disco-usuario --corregido
    titulo_disco TEXT,
    anio_publicacion TEXT,
    nombre_usuario TEXT, 
    CONSTRAINT desea_pk PRIMARY KEY (titulo_disco,anio_publicacion,nombre_usuario),
    CONSTRAINT desea_disco_fk FOREIGN KEY (titulo_disco,anio_publicacion) REFERENCES disco(titulo_disco,anio_publicacion)MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE, 
    CONSTRAINT desea_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario)  MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

CREATE TABLE IF NOT EXISTS tiene( --usuario-ediciones ---Pero no sobra?
    formato TEXT,
    pais TEXT,
    anio_edicion TEXT,
    nombre_usuario TEXT,
    estado TEXT,  
    CONSTRAINT tiene_pk PRIMARY KEY (formato,pais,anio_edicion,nombre_usuario),
    CONSTRAINT tiene_edicion_fk FOREIGN KEY (formato,anio_edicion,pais) REFERENCES edicion(formato,anio_edicion,pais) MATCH FULL
    ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT tiene_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario) MATCH FULL --poner la coma antes de restrict???????
    ON DELETE RESTRICT ON UPDATE CASCADE 
);

-----------------------------------------tablas temporales----------------------------------
\echo 'creando un esquema temporal'
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
SELECT DISTINCT NombreGrupo, urlGrupo ----distinct?
FROM discoscsv;
---WHERE idGrupo IS NOT NULL;        no necesario creo
\echo 'grupo hecho'

INSERT INTO disco (titulo_disco, anio_publicacion, nombre_grupo, url_portada)
SELECT DISTINCT NombreDisco, 
        añoLanzamiento,  --cast en postgresql== fechaLanzamiento::SMALLINT
       NombreGrupo,
       urlPortada
FROM discoscsv;
\echo 'disco hecho'

--descomponer genero en varias filas
INSERT INTO genero (titulo_disco, anio_publicacion, genero)
SELECT DISTINCT NombreDisco,
       añoLanzamiento,
       regexp_split_to_table(
           regexp_replace(trim(both '[]' from generos), '''', '', 'g'),  -- Elimina las comillas simples
           '\s*,\s*'  -- Divide en filas usando la coma (con espacios opcionales alrededor)
       )
       --(replace(generos, "'",''), ',')  ---quizas con '''' en vez de "'"?
       --unnest divide en varias filas
       --string to array (...,',') divide la cadena en un array de varios elementos tipo TEXT con la coma como delimitador 
FROM discoscsv;
\echo 'genero hecho'

INSERT INTO edicion (titulo_disco, anio_publicacion, formato, pais, anio_edicion)
SELECT DISTINCT disco.NombreDisco,
       disco.añoLanzamiento,
       edicion.formato,
       edicion.paisEdicion,
       edicion.añoEdicion -- LO de null ya está configurado en COPY
FROM discoscsv disco JOIN edicionescsv edicion ON disco.idDisco = edicion.idDisco
ON CONFLICT (formato, pais, anio_edicion) DO NOTHING;
\echo 'edicion hecho'

----falta cancion, join?


INSERT INTO usuario (nombre_usuario, nombre, email, passwd)
SELECT  DISTINCT nombreUsuario,
       nombreCompleto,
       email,
       passwd
FROM usuarioscsv;
\echo 'usuario hecho'


INSERT INTO tiene (formato,pais,anio_edicion,nombre_usuario,estado)
SELECT DISTINCT usuarioTieneEdicion.formato,
    usuarioTieneEdicion.paisEdicion,
    usuarioTieneEdicion.añoEdicion,
    usuarioTieneEdicion.nombreUsuario,
    usuarioTieneEdicion.estado
FROM usuarioTieneEdicion JOIN usuario ON usuario.nombre_usuario = usuarioTieneEdicion.nombreUsuario JOIN edicion ON (edicion.formato = usuarioTieneEdicion.formato AND edicion.anio_edicion = usuarioTieneEdicion.añoEdicion AND edicion.pais = usuarioTieneEdicion.paisEdicion)
ON CONFLICT (formato,pais,anio_edicion, nombre_usuario) DO NOTHING;
\echo 'tiene hecho'

INSERT INTO desea (titulo_disco, anio_publicacion, nombre_usuario)
SELECT DISTINCT tituloDisco,
       añoLanzamiento,
       nombreUsuario
FROM usuarioDeseaDisco JOIN usuario ON usuario.nombre_usuario = usuarioDeseaDisco.nombreUsuario JOIN disco ON (disco.titulo_disco= usuarioDeseaDisco.tituloDisco AND disco.anio_publicacion = usuarioDeseaDisco.añoLanzamiento);
\echo 'desea hecho'


INSERT INTO edicion(titulo_disco, anio_publicacion, formato, pais, anio_edicion)
SELECT DISTINCT disco.nombreDisco, 
    disco.añoLanzamiento, 
    edicion.formato, 
    edicion.paisEdicion, 
    edicion.añoEdicion
FROM discoscsv disco JOIN edicionescsv edicion ON disco.idDisco = edicion.idDisco
ON CONFLICT (formato, pais, anio_edicion) DO NOTHING;------------------------------------------------------

--Esta aqui no? pero hay un problema con duración. por cierto lo de NULL; ya está puesto en el COPY, está puesto en el COPY que si encuentra "NULL" es NULL
INSERT INTO cancion(titulo_disco, anio_publicacion, titulo_cancion, duracion)
SELECT DISTINCT disco.NombreDisco, 
    disco.añoLanzamiento, 
    cancion.tituloCancion, 
    MAKE_INTERVAL (
            mins => SPLIT_PART(cancion.duracion, ':', 1)::INTEGER, 
            secs => split_part(cancion.duracion, ':', 2)::INTEGER) ::TIME --PROBAR QUE FUNCIONE --Duración es de la forma 00:00 hay que pasarlo a time
FROM discoscsv disco JOIN cancionescsv cancion ON disco.idDisco = cancion.idDisco
ON CONFLICT (titulo_disco, anio_publicacion, titulo_cancion) DO NOTHING;--Tengo que juntar las dos tablas para conseguir los datos que quiero

INSERT INTO usuario(nombre_usuario, nombre, email, passwd)
SELECT DISTINCT nombreUsuario, nombreCompleto, email, passwd
FROM usuarioscsv
ON CONFLICT(nombre_usuario) DO NOTHING;


--INSERT INTO desea(titulo_disco, anio_publicacion, nombre_usuario)
--SELECT nombreDisco, CAST(fechaLanzamiento AS SMALLINT), nombreUsuario
--FRO

SELECT * FROM cancion LIMIT 10; ----Duraciones 00:00:00
\d cancion;
SELECT * FROM desea LIMIT 10; ---Algunos indica año 0,en el csv original tambien, pero quizas lo pone para indicar null
\d desea;
SELECT * FROM disco LIMIT 10; --url portada ????
\d disco;
SELECT * FROM edicion LIMIT 10; 
\d edicion;
SELECT * FROM genero LIMIT 10; ---MAL
\d genero;
SELECT * FROM grupo LIMIT 10; 
\d grupo;
\echo "dsfsfds";
SELECT * FROM tiene LIMIT 10; ---MAL
\d tiene;
SELECT * FROM usuario LIMIT 10; 
\d usuario;


ROLLBACK;

--para la hora: Make interval, split por los :, tochar(intervalo) h:m:s para coger el intervalo y pasarlo a caracteres , cast a time (con duracion::time)
--para los generos: para quitar [''] con replace (solo reemplaza 1 char) o regexp_replace (meter expresion regular)
--para evitar error por clave duplicada
--insert into usuarios      select      distinct on(nombreUsuario),email,.....//resto de atrib

