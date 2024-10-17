\pset pager off

SET client_encoding = 'UTF8';

BEGIN;
/*\echo 'creando el esquema para la BBDD de películas'


\echo 'creando un esquema temporal'


SET search_path='nombre del esquema o esquemas utilizados';

\echo 'Cargando datos'


\echo insertando datos en el esquema final

\echo Consulta 1: texto de la consulta

\echo Consulta n:

*/
CREATE TABLE IF NO EXISTS disco(
    titulo TEXT,
    anio_publicacion SMALLINT,
    URL TEXT,
    nombre_grupo TEXT
    CONSTRAINT disco_pk PRIMARY KEY(titulo, anio_publicacion)
    CONSTRAINT disco_fk FOREIGN KEY(nombre_grupo) REFERENCES grupo(nombre_grupo) --mirar match full-------
    -- Mirar delete y update -----------
);
CREATE TABLE IF NO EXISTS grupo(
    nombre_grupo TEXT,
    URL TEXT
    CONSTRAINT grupo_pk PRIMARY KEY(nombre_grupo)

);

CREATE TABLE IF NO EXISTS genero(
    titulo TEXT,
    anio_publicacion SMALLINT,
    genero TEXT
    CONSTRAINT genero_pk PRIMARY KEY(genero)
    CONSTRAINT genero_fk FOREIGN KEY(titulo, anio_publicacion) REFERENCES disco(titulo, anio_publicacion)
);

CREATE TABLE IF NO EXISTS edicion(
    formato TEXT,
    anio_edicion SMALLINT,
    anio_publicacion SMALLINT,
    titulo TEXT
    pais TEXT
    CONSTRAINT edicion_pk PRIMARY KEY(formato, anio_edicion, pais)
    CONSTRAINT edicion_fk FOREIGN KEY(titulo, anio_publicacion) REFERENCES disco(titulo, anio_publicacion)
);
CREATE TABLE IF NO EXISTS cancion(
    titulo_cancion TEXT,
    titulo TEXT,
    anio_publicacion SMALLINT,
    CONSTRAINT cancion_pk PRIMARY KEY(titulo_cancion)
    CONSTRAINT cancion_fk FOREIGN KEY(titulo, anio_publicacion) REFERENCES disco(titulo, anio_publicacion)
);
CREATE TABLE IF NO EXISTS usuario(
    nombre_usuario TEXT,
    nombre TEXT,
    email TEXT,
    passwd TEXT
    CONSTRAINT usuario_pk PRIMARY KEY(nombre_usuario)

);

--------------------Relaciones--------------------------
CREATE TABLE IF NO EXISTS desea(
    titulo TEXT,
    anio_publicacion SMALLINT,
    nombre_usuario TEXT
    
    CONSTRAINT desea_disco_fk FOREIGN KEY(titulo, anio_publicacion) REFERENCES disco(titulo, anio_publicacion)
    CONSTRAINT desea_usuario_fk FOREIGN KEY(nombre_usuario) REFERENCES usuario(nombre_usuario)
);
CREATE TABLE IF NO EXISTS tiene(
    titulo TEXT,
    anio_publicacion SMALLINT,
    nombre_usuario TEXT,
    formato TEXT,
    anio_edicion SMALLINT
    estado TEXT
    
    --CONSTRAINT tiene_disco_fk FOREIGN KEY(titulo, anio_publicacion) REFERENCES disco(titulo, anio_publicacion)
    CONSTRAINT tiene_usuario_fk FOREIGN KEY(nombre_usuario) REFERENCES usuario(nombre_usuario)
    CONSTRAINT formato_edicion_fk FOREIGN KEY(pais, formato, anio_edicion, titulo, anio_publicacion) REFERENCES edicion(pais, formato, anio_edicion, titulo, anio_publicacion)
    
);

CREATE
ROLLBACK;                       -- importante! permite correr el script multiples veces...p