-- 02_logic_and_views.sql
-- ==============================================================================
-- ACTIVIDAD 1: Vistas Avanzadas para Reportes (Corregidas para el esquema actual)
-- ==============================================================================

-- Vista 1: Estadísticas de Técnicos 
-- Muestra el rendimiento y la carga de trabajo de cada técnico
CREATE OR REPLACE VIEW vw_estadisticas_tecnico AS
SELECT 
    pt.id_tecnico,
    u.nombres,
    u.apellidos,
    pt.especialidad,
    COUNT(s.uuid_solicitud) AS total_solicitudes_asignadas,
    SUM(CASE WHEN s.estado = 'FINALIZADA' THEN 1 ELSE 0 END) AS total_completadas
FROM perfiles_tecnicos pt
INNER JOIN usuarios u ON pt.id_usuario = u.id_usuario
LEFT JOIN solicitudes s ON pt.id_tecnico = s.id_tecnico
GROUP BY pt.id_tecnico, u.nombres, u.apellidos, pt.especialidad;

-- Vista 2: Resumen de Cotizaciones Aprobadas
-- Muestra el total de dinero y cantidad de cotizaciones aprobadas por empleado/creador
CREATE OR REPLACE VIEW vw_resumen_cotizaciones AS
SELECT 
    u.nombres,
    u.apellidos,
    COUNT(c.id_cotizacion) AS cantidad_cotizaciones_aprobadas,
    SUM(c.total) AS total_dinero_aprobado
FROM cotizaciones c
INNER JOIN usuarios u ON c.id_usuario_creador = u.id_usuario
WHERE c.estado = 'APROBADA'
GROUP BY u.id_usuario, u.nombres, u.apellidos;

-- ==============================================================================
-- ACTIVIDAD 2: Procedimientos Almacenados Transaccionales (Corregido)
-- ==============================================================================

DELIMITER //

-- Procedimiento: sp_aprobar_cotizacion
-- Objetivo: Aprobar una cotización y actualizar la solicitud vinculada de forma segura.
CREATE PROCEDURE sp_aprobar_cotizacion(
    IN p_id_cotizacion BIGINT UNSIGNED
)
BEGIN
    -- Declaración de variables locales
    DECLARE v_uuid_solicitud CHAR(36);
    DECLARE v_estado_cotizacion VARCHAR(50);
    DECLARE v_existe INT DEFAULT 0;

    -- Manejador de excepciones (Si ocurre un error, revierte toda la transacción)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- ROLLBACK deshace todos los cambios si algo falla
        ROLLBACK;
        RESIGNAL; -- Relanza el error para visualizarlo
    END;

    -- Verificar que la cotización exista antes de intentar procesarla
    SELECT COUNT(*) INTO v_existe FROM cotizaciones WHERE id_cotizacion = p_id_cotizacion;
    
    IF v_existe = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cotización indicada no existe en el sistema.';
    END IF;

    -- Inicia la transacción atómica
    START TRANSACTION;

    -- Obtener datos bloqueando la fila para evitar concurrencia
    SELECT uuid_solicitud, estado INTO v_uuid_solicitud, v_estado_cotizacion
    FROM cotizaciones 
    WHERE id_cotizacion = p_id_cotizacion FOR UPDATE; 
    
    IF v_estado_cotizacion = 'APROBADA' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: La cotización ya se encuentra aprobada.';
    END IF;

    -- 1. Actualizar estado de la cotización
    UPDATE cotizaciones 
    SET estado = 'APROBADA' 
    WHERE id_cotizacion = p_id_cotizacion;

    -- 2. Actualizar estado de la solicitud vinculada
    UPDATE solicitudes 
    SET estado = 'APROBADA' 
    WHERE uuid_solicitud = v_uuid_solicitud;

    -- Confirmar la transacción si todo salió bien
    COMMIT;
END //

DELIMITER ;