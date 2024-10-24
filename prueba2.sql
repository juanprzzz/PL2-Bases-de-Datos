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
CREATE TABLE IF NOT EXISTS disco(
    titulo TEXT,
    anio_publicacion SMALLINT,
    nombre_grupo TEXT,
    CONSTRAINT disco_pk PRIMARY KEY (titulo,anio_publicacion,nombre_grupo),
    CONSTRAINT disco_fk FOREIGN KEY (nombre_grupo) REFERENCES grupo(nombre_grupo) MATCH FULL 
);

CREATE TABLE IF NOT EXISTS grupo(
    nombre_grupo TEXT,
    URL TEXT,
    CONSTRAINT grupo_pk PRIMARY KEY (nombre_grupo)
);


CREATE TABLE IF NOT EXISTS genero(
    titulo TEXT,
    anio_publicacion SMALLINT,
    genero TEXT,
    CONSTRAINT genero_pk PRIMARY KEY (genero,titulo,anio_publicacion),
    CONSTRAINT genero_fk FOREIGN KEY (titulo,anio_publicacion) REFERENCES disco(titulo,anio_publicacion)  MATCH FULL
);

CREATE TABLE IF NOT EXISTS edicion(
    titulo TEXT,
    anio_publicacion SMALLINT,
    formato TEXT,
    pais text,
    anio_edicion SMALLINT,
    CONSTRAINT edicion_pk PRIMARY KEY (formato,anio_edicion,pais,titulo,anio_publicacion),
    CONSTRAINT edicion_fk FOREIGN KEY (titulo,anio_publicacion) REFERENCES disco(titulo,anio_publicacion) MATCH FULL 
);

CREATE TABLE IF NOT EXISTS cancion(
    titulo TEXT,
    anio_publicacion SMALLINT, --falta duracion y sobra año??
    titulo_cancion TEXT,
    CONSTRAINT cancion_pk PRIMARY KEY (titulo_cancion,titulo,anio_publicacion),
    CONSTRAINT cancion_fk FOREIGN KEY (titulo,anio_publicacion) REFERENCES disco(titulo,anio_publicacion)MATCH FULL  
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
    titulo TEXT,
    anio_publicacion SMALLINT,
    nombre_usuario TEXT,
    CONSTRAINT desea_disco_fk FOREIGN KEY (titulo,anio_publicacion) REFERENCES disco(titulo,anio_publicacion)MATCH FULL,
    CONSTRAINT desea_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario)  MATCH FULL
);

CREATE TABLE IF NOT EXISTS tiene( --usuario-ediciones
    titulo TEXT,
    anio_publicacion SMALLINT,
    formato TEXT,
    pais TEXT,
    anio_edicion SMALLINT,
    estado TEXT,
    CONSTRAINT tiene_edicion_fk FOREIGN KEY (formato,anio_edicion,pais, titulo,anio_publicacion) REFERENCES edicion(formato,anio_edicion,pais,titulo,anio_publicacion) MATCH FULL, 
    CONSTRAINT tiene_usuario_fk FOREIGN KEY (nombre_usuario) REFERENCES usuario(nombre_usuario) MATCH FULL
);

-----------------------------------------tablas temporales----------------------------------
\echo 'creando un esquema temporal'
CREATE TABLE IF NOT EXISTS discoscsv(
    idDisco INT,
    NombreDisco TEXT,
    fechaLanzamiento SMALLINT,
    --idGrupo INT,
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
    idDisco INT,
    tituloCancion TEXT,
    duracion TEXT
    
);
CREATE TABLE IF NOT EXISTS edicionescsv(
    idDisco INT,
    añoEdicion SMALLINT,
    paisEdicion TEXT,
    formato TEXT
);
CREATE TABLE IF NOT EXISTS usuarioDeseaDisco(
    nombreUsuario TEXT,
    tituloDisco TEXT,
    añoLanzamiento SMALLINT
);
CREATE TABLE IF NOT EXISTS usuarioTieneEdicion(
    nombreUsuario TEXT,
    tituloDisco TEXT,
    añoLanzamiento SMALLINT,
    añoEdicion SMALLINT,
    paisEdicion TEXT,
    formato TEXT,
    estado TEXT
);

COPY discocsv FROM 'discos.csv ' DELIMITER ';' CSV HEADER ENCODING UTF8 NULL 'NULL'; ---tener en cuenta que puede haber nulos. cargar strings null como null real para que no lo cargue como text null
COPY usuarioscsv FROM 'usuarios.csv ' DELIMITER ';' CSV HEADE ENCODING UTF8 NULL "NULL";
COPY cancionescsv FROM 'canciones.csv ' DELIMITER ';' CSV HEADER ENCODING UTF8 NULL "NULL";
COPY edicionescsv FROM 'ediciones.csv ' DELIMITER ';' CSV HEADER ENCODING UTF8 NULL "NULL";
COPY usuarioDeseaDisco FROM 'usuario_desea_disco.csv ' DELIMITER ';' CSV HEADER ENCODING UTF8 NULL "NULL";
COPY usuarioTieneEdicion FROM 'usuario_tiene_edicion.csv ' DELIMITER ';' CSV HEADER ENCODING UTF8 NULL "NULL";

ROLLBACK;

--para la hora: Make interval, split por los :, tochar(intervalo) h:m:s para coger el intervalo y pasarlo a caracteres , cast a time (con duracion::time)
--para los generos: para quitar [''] con replace (solo reemplaza 1 char) o regexp_replace (meter expresion regular)
--para evitar error por clave duplicada
--insert into usuarios      select      distinct on(nombreUsuario),email,.....//resto de atrib

