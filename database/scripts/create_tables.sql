-- create_tables.sql
-- ==============================================================================
-- Script DDL de creación de esquema inicial
-- Proyecto: Sigesto
-- ==============================================================================

-- Creación de la base de datos principal del proyecto
CREATE DATABASE IF NOT EXISTS sigesto;
USE sigesto;

-- ==============================================================================
-- TABLAS INDEPENDIENTES (Catálogos y Maestras)
-- ==============================================================================

-- Tabla que almacena los perfiles de acceso y roles del sistema
CREATE TABLE roles (
    id_rol BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    PRIMARY KEY (id_rol)
);

-- Tabla para definir los tipos de trabajo o servicios que se ofrecen en los mantenimientos
CREATE TABLE tipos_trabajo (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT DEFAULT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- Tabla de catálogo que registra todos los materiales (ej. cables, breakers) y servicios disponibles
CREATE TABLE items_catalogo (
    id_item BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    sku_codigo VARCHAR(50) DEFAULT NULL UNIQUE,
    tipo_item ENUM('MATERIAL','SERVICIO') NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT DEFAULT NULL,
    unidad_medida VARCHAR(20) DEFAULT NULL,
    precio_ref DECIMAL(10,2) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_item)
);

-- ==============================================================================
-- TABLAS DEPENDIENTES (Con claves foráneas y restricciones)
-- ==============================================================================

-- Tabla central de usuarios del sistema (Depende de la tabla roles)
CREATE TABLE usuarios (
    id_usuario BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_rol BIGINT UNSIGNED NOT NULL,
    email VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id_usuario),
    -- Restricción UNIQUE para evitar el registro de correos duplicados
    CONSTRAINT uq_usuarios_email UNIQUE (email),
    -- Relación con la tabla roles: evita borrar un rol si tiene usuarios asignados (RESTRICT)
    FOREIGN KEY (id_rol) REFERENCES roles(id_rol) ON DELETE RESTRICT
);

-- Tabla para almacenar los datos específicos y de facturación de los clientes (Depende de usuarios)
CREATE TABLE perfiles_clientes (
    id_cliente BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    id_usuario BIGINT UNSIGNED NOT NULL,
    dni_ruc VARCHAR(20) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion VARCHAR(255) DEFAULT NULL,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id_cliente),
    -- Restricción UNIQUE para que no existan documentos de identidad o RUC repetidos
    CONSTRAINT uq_clientes_dni_ruc UNIQUE (dni_ruc),
    -- Restricción UNIQUE para asegurar una relación 1 a 1 estricta con la tabla usuarios
    CONSTRAINT uq_clientes_usuario UNIQUE (id_usuario),
    -- Relación con usuarios: si se elimina el usuario del sistema, se elimina su perfil (CASCADE)
    FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario) ON DELETE CASCADE
);

-- Tabla que gestiona las cotizaciones emitidas para las solicitudes (Depende de usuarios)
CREATE TABLE cotizaciones (
    id_cotizacion BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    estado ENUM('BORRADOR','ENVIADA','APROBADA','RECHAZADA','LIQUIDADA') NOT NULL DEFAULT 'BORRADOR',
    tasa_igv DECIMAL(5,2) NOT NULL DEFAULT 18.00,
    subtotal DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    igv DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    id_usuario_creador BIGINT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL DEFAULT NULL,
    PRIMARY KEY (id_cotizacion),
    -- Relación con el usuario que genera la cotización (RESTRICT)
    FOREIGN KEY (id_usuario_creador) REFERENCES usuarios(id_usuario) ON DELETE RESTRICT,
    -- Restricción CHECK de negocio: impide guardar cotizaciones con un total negativo
    CONSTRAINT chk_cotizacion_total CHECK (total >= 0)
);