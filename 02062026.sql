USE master;
GO

IF DB_ID('EvaluacionDesempenoDB') IS NOT NULL
BEGIN
    ALTER DATABASE EvaluacionDesempenoDB
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

    DROP DATABASE EvaluacionDesempenoDB;
END
GO

CREATE DATABASE EvaluacionDesempenoDB;
GO

USE EvaluacionDesempenoDB;
GO

-- Schemas

CREATE SCHEMA Seguridad;
GO

CREATE SCHEMA Organizacion;
GO

CREATE SCHEMA Competencias;
GO

CREATE SCHEMA Desempeno;
GO

CREATE SCHEMA Analisis;
GO

CREATE SCHEMA Desarrollo;
GO

/* SCHEMA seguridad*/

--Tabla 1: Roles

CREATE TABLE Seguridad.Roles_Usuario
(
    rolID INT IDENTITY(1,1) PRIMARY KEY,

    nombreRol VARCHAR(50) NOT NULL UNIQUE,

    descripcionRol VARCHAR(MAX) NULL
);
GO

/*SCHEMA organizacion*/

-- Tabla 2: Sucursal

CREATE TABLE Organizacion.Sucursal
(
    sucursalID INT IDENTITY(1,1) PRIMARY KEY,

    nombreSucursal NVARCHAR(100) NOT NULL UNIQUE,

    direccion NVARCHAR(200) NULL
);
GO


-- Tabla 3: Departamento


CREATE TABLE Organizacion.Departamento
(
    departamentoID INT IDENTITY(1,1) PRIMARY KEY,

    codigoArea VARCHAR(10) NOT NULL UNIQUE,

    nombreDepartamento NVARCHAR(100) NOT NULL,

    centroCostos VARCHAR(20) NOT NULL,

    sucursalID INT NOT NULL,

    CONSTRAINT FK_Departamento_Sucursal
        FOREIGN KEY (sucursalID)
        REFERENCES Organizacion.Sucursal(sucursalID)
);
GO

-- tabla 4: Cargo

CREATE TABLE Organizacion.Cargo
(
    cargoID INT IDENTITY(1,1) PRIMARY KEY,

    nombreCargo NVARCHAR(100) NOT NULL,

    nivelJerarquico VARCHAR(5) NOT NULL,

    funciones VARCHAR(MAX) NOT NULL,

    departamentoID INT NOT NULL,

    CONSTRAINT FK_Cargo_Departamento
        FOREIGN KEY (departamentoID)
        REFERENCES Organizacion.Departamento(departamentoID),

    CONSTRAINT UQ_Cargo_NombreNivel
        UNIQUE(nombreCargo,nivelJerarquico)
);
GO


--    TABLA: Organizacion.Empleado


CREATE TABLE Organizacion.Empleado
(
    ID_Empleado INT IDENTITY(1,1) PRIMARY KEY,

    Nombres VARCHAR(100) NOT NULL,

    Apellidos VARCHAR(100) NOT NULL,

    Correo VARCHAR(120) NOT NULL UNIQUE,

    Telefono VARCHAR(15) NULL,

    FechaIngreso DATE NOT NULL
        DEFAULT GETDATE(),

    ID_Cargo INT NOT NULL,

    ID_Jefe_Inmediato INT NULL,

    CONSTRAINT FK_Empleado_Cargo
        FOREIGN KEY (ID_Cargo)
        REFERENCES Organizacion.Cargo(cargoID),

    CONSTRAINT FK_Empleado_Jefe
        FOREIGN KEY (ID_Jefe_Inmediato)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT CK_Empleado_NoEsSuJefe
        CHECK
        (
            ID_Jefe_Inmediato IS NULL
            OR
            ID_Jefe_Inmediato <> ID_Empleado
        )
);
GO

/*====================================================
    TABLA: Seguridad.Usuario
====================================================*/

CREATE TABLE Seguridad.Usuario
(
    usuarioID INT IDENTITY(1,1) PRIMARY KEY,

    username VARCHAR(50) NOT NULL UNIQUE,

    contrasena VARCHAR(255) NOT NULL,

    estadoUsuario VARCHAR(20)
        CONSTRAINT DF_Usuario_Estado
        DEFAULT 'Activo',

    ID_Empleado INT NOT NULL UNIQUE,

    rolID INT NOT NULL,

    CONSTRAINT FK_Usuario_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Usuario_Rol
        FOREIGN KEY (rolID)
        REFERENCES Seguridad.Roles_Usuario(rolID),

    CONSTRAINT CK_Usuario_Estado
        CHECK
        (
            estadoUsuario IN
            ('Activo','Inactivo')
        )
);
GO

/*====================================================
    TABLA: Competencias.Competencia
====================================================*/

CREATE TABLE Competencias.Competencia
(
    ID_Competencia INT IDENTITY(1,1) PRIMARY KEY,

    NombreCompetencia VARCHAR(100) NOT NULL,

    TipoCompetencia VARCHAR(20) NOT NULL,

    Categoria VARCHAR(50) NOT NULL,

    Descripcion VARCHAR(MAX) NULL,

    CONSTRAINT CK_Competencia_Tipo
        CHECK
        (
            TipoCompetencia IN
            ('Blanda','Tecnica','Técnica')
        )
);
GO

/*====================================================
    TABLA: Competencias.EscalaEvaluacion
====================================================*/

CREATE TABLE Competencias.EscalaEvaluacion
(
    ID_Escala INT IDENTITY(1,1) PRIMARY KEY,

    ValorEscala INT NOT NULL,

    DescripcionConductual VARCHAR(200) NOT NULL,

    CONSTRAINT CK_Escala_Valor
        CHECK (ValorEscala BETWEEN 1 AND 5)
);
GO

/*====================================================
    TABLA: Competencias.CompetenciaCargo
====================================================*/

CREATE TABLE Competencias.CompetenciaCargo
(
    ID_CompetenciaCargo INT IDENTITY(1,1) PRIMARY KEY,

    ID_Cargo INT NOT NULL,

    ID_Competencia INT NOT NULL,

    NivelRequerido INT NOT NULL,

    CONSTRAINT FK_CC_Cargo
        FOREIGN KEY (ID_Cargo)
        REFERENCES Organizacion.Cargo(cargoID),

    CONSTRAINT FK_CC_Competencia
        FOREIGN KEY (ID_Competencia)
        REFERENCES Competencias.Competencia(ID_Competencia),

    CONSTRAINT CK_CC_Nivel
        CHECK (NivelRequerido BETWEEN 1 AND 5),

    CONSTRAINT UQ_CargoCompetencia
        UNIQUE(ID_Cargo, ID_Competencia)
);
GO

/*====================================================
    TABLA: Desempeno.KPI
====================================================*/

CREATE TABLE Desempeno.KPI
(
    ID_KPI INT IDENTITY(1,1) PRIMARY KEY,

    NombreKPI VARCHAR(100) NOT NULL,

    Formula VARCHAR(MAX) NOT NULL,

    UnidadMedida VARCHAR(20) NOT NULL
);
GO

/*====================================================
    TABLA: Desempeno.Meta
====================================================*/

CREATE TABLE Desempeno.Meta
(
    ID_Meta INT IDENTITY(1,1) PRIMARY KEY,

    ID_Empleado INT NOT NULL,

    ID_KPI INT NOT NULL,

    ValorMeta DECIMAL(10,2) NOT NULL,

    Peso DECIMAL(5,2) NOT NULL,

    EstadoMeta VARCHAR(20)
        CONSTRAINT DF_Meta_Estado
        DEFAULT 'Pendiente',

    CONSTRAINT FK_Meta_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Meta_KPI
        FOREIGN KEY (ID_KPI)
        REFERENCES Desempeno.KPI(ID_KPI),

    CONSTRAINT CK_Meta_Valor
        CHECK (ValorMeta > 0),

    CONSTRAINT CK_Meta_Peso
        CHECK (Peso > 0 AND Peso <= 100),

    CONSTRAINT CK_Meta_Estado
        CHECK
        (
            EstadoMeta IN
            ('Pendiente','Aprobada','Rechazada')
        )
);
GO

/*====================================================
    TABLA: Desempeno.PeriodoEvaluativo
====================================================*/

CREATE TABLE Desempeno.PeriodoEvaluativo
(
    ID_Periodo INT IDENTITY(1,1) PRIMARY KEY,

    NombrePeriodo VARCHAR(50) NOT NULL UNIQUE,

    FechaInicio DATE NOT NULL,

    FechaCierre DATE NOT NULL,

    TipoEvaluacion VARCHAR(30) NOT NULL,

    Estado VARCHAR(20)
        CONSTRAINT DF_Periodo_Estado
        DEFAULT 'Activo',

    CONSTRAINT CK_Periodo_Fechas
        CHECK (FechaCierre > FechaInicio),

    CONSTRAINT CK_Periodo_Tipo
        CHECK
        (
            TipoEvaluacion IN
            ('Anual','Semestral','Trimestral')
        ),

    CONSTRAINT CK_Periodo_Estado
        CHECK
        (
            Estado IN
            ('Activo','Planificado','Cerrado')
        )
);
GO

/*====================================================
    TABLA: Desempeno.Evaluador
====================================================*/

CREATE TABLE Desempeno.Evaluador
(
    ID_Evaluador_Rel INT IDENTITY(1,1) PRIMARY KEY,

    ID_Empleado INT NOT NULL,

    ID_Evaluador INT NOT NULL,

    ID_Periodo INT NOT NULL,

    CONSTRAINT FK_Evaluador_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Evaluador_Evaluador
        FOREIGN KEY (ID_Evaluador)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Evaluador_Periodo
        FOREIGN KEY (ID_Periodo)
        REFERENCES Desempeno.PeriodoEvaluativo(ID_Periodo),

    CONSTRAINT UQ_Evaluador_Unico
        UNIQUE(ID_Empleado, ID_Evaluador, ID_Periodo),

    CONSTRAINT CK_Evaluador_Distinto
        CHECK (ID_Empleado <> ID_Evaluador)
);
GO

/*====================================================
    TABLA: Desempeno.Evaluacion
====================================================*/

CREATE TABLE Desempeno.Evaluacion
(
    ID_Evaluacion INT IDENTITY(1,1) PRIMARY KEY,

    ID_Empleado INT NOT NULL,

    ID_Evaluador INT NOT NULL,

    ID_Periodo INT NOT NULL,

    EstadoEvaluacion VARCHAR(20)
        CONSTRAINT DF_Evaluacion_Estado
        DEFAULT 'Pendiente',

    CONSTRAINT FK_Evaluacion_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Evaluacion_Evaluador
        FOREIGN KEY (ID_Evaluador)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Evaluacion_Periodo
        FOREIGN KEY (ID_Periodo)
        REFERENCES Desempeno.PeriodoEvaluativo(ID_Periodo),

    CONSTRAINT CK_Evaluacion_Estado
        CHECK
        (
            EstadoEvaluacion IN
            (
                'Pendiente',
                'En Progreso',
                'Completada'
            )
        )
);
GO

/*====================================================
    TABLA: Desempeno.NotaCompetencia
====================================================*/

CREATE TABLE Desempeno.NotaCompetencia
(
    ID_Nota INT IDENTITY(1,1) PRIMARY KEY,

    ID_Evaluacion INT NOT NULL,

    ID_Competencia INT NOT NULL,

    Nota INT NOT NULL,

    CONSTRAINT FK_Nota_Evaluacion
        FOREIGN KEY (ID_Evaluacion)
        REFERENCES Desempeno.Evaluacion(ID_Evaluacion),

    CONSTRAINT FK_Nota_Competencia
        FOREIGN KEY (ID_Competencia)
        REFERENCES Competencias.Competencia(ID_Competencia),

    CONSTRAINT CK_Nota_Rango
        CHECK (Nota BETWEEN 1 AND 5),

    CONSTRAINT UQ_NotaCompetencia
        UNIQUE(ID_Evaluacion, ID_Competencia)
);
GO

/*====================================================
    TABLA: Desempeno.ResultadoMeta
====================================================*/

CREATE TABLE Desempeno.ResultadoMeta
(
    ID_Resultado INT IDENTITY(1,1) PRIMARY KEY,

    ID_Meta INT NOT NULL UNIQUE,

    ValorReal DECIMAL(10,2) NOT NULL,

    Cumplimiento DECIMAL(5,2) NOT NULL
        DEFAULT 0,

    CONSTRAINT FK_Resultado_Meta
        FOREIGN KEY (ID_Meta)
        REFERENCES Desempeno.Meta(ID_Meta),

    CONSTRAINT CK_Resultado_Valor
        CHECK (ValorReal >= 0)
);
GO

/*====================================================
    TABLA: Desempeno.Feedback
====================================================*/

CREATE TABLE Desempeno.Feedback
(
    ID_Feedback INT IDENTITY(1,1) PRIMARY KEY,

    ID_Evaluacion INT NOT NULL UNIQUE,

    Comentarios VARCHAR(MAX) NOT NULL,

    Fortalezas VARCHAR(MAX) NULL,

    OportunidadesMejora VARCHAR(MAX) NULL,

    EvidenciaPDF VARCHAR(255) NULL,

    CONSTRAINT FK_Feedback_Evaluacion
        FOREIGN KEY (ID_Evaluacion)
        REFERENCES Desempeno.Evaluacion(ID_Evaluacion)
);
GO

/*====================================================
    TABLA: Analisis.ScoreFinal
====================================================*/

CREATE TABLE Analisis.ScoreFinal
(
    scoreID INT IDENTITY(1,1) PRIMARY KEY,

    ID_Empleado INT NOT NULL,

    ID_Periodo INT NOT NULL,

    scoreCompetencias DECIMAL(5,2) NOT NULL
        DEFAULT 0,

    scoreMetas DECIMAL(5,2) NOT NULL
        DEFAULT 0,

    scoreTotal DECIMAL(5,2) NOT NULL
        DEFAULT 0,

    cuadrante9Box VARCHAR(50)
        DEFAULT 'No Asignado',

    CONSTRAINT FK_Score_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT FK_Score_Periodo
        FOREIGN KEY (ID_Periodo)
        REFERENCES Desempeno.PeriodoEvaluativo(ID_Periodo),

    CONSTRAINT UQ_Score
        UNIQUE(ID_Empleado, ID_Periodo)
);
GO

/*====================================================
    TABLA: Analisis.BrechaCompetencia
====================================================*/

CREATE TABLE Analisis.BrechaCompetencia
(
    brechaID INT IDENTITY(1,1) PRIMARY KEY,

    ID_Evaluacion INT NOT NULL,

    ID_Competencia INT NOT NULL,

    nivelRequerido INT NOT NULL,

    nivelObtenido INT NOT NULL,

    brecha INT NOT NULL DEFAULT 0,

    CONSTRAINT FK_Brecha_Evaluacion
        FOREIGN KEY (ID_Evaluacion)
        REFERENCES Desempeno.Evaluacion(ID_Evaluacion),

    CONSTRAINT FK_Brecha_Competencia
        FOREIGN KEY (ID_Competencia)
        REFERENCES Competencias.Competencia(ID_Competencia),

    CONSTRAINT CK_Brecha_Requerido
        CHECK (nivelRequerido BETWEEN 1 AND 5),

    CONSTRAINT CK_Brecha_Obtenido
        CHECK (nivelObtenido BETWEEN 1 AND 5)
);
GO

/*====================================================
    TABLA: Desarrollo.CursoCapacitacion
====================================================*/

CREATE TABLE Desarrollo.CursoCapacitacion
(
    ID_Curso INT IDENTITY(1,1) PRIMARY KEY,

    NombreCurso VARCHAR(100) NOT NULL,

    Descripcion VARCHAR(MAX) NULL,

    CompetenciaAsociada INT NOT NULL,

    CONSTRAINT FK_Curso_Competencia
        FOREIGN KEY (CompetenciaAsociada)
        REFERENCES Competencias.Competencia(ID_Competencia)
);
GO

/*====================================================
    TABLA: Desarrollo.PlanMejora
====================================================*/

CREATE TABLE Desarrollo.PlanMejora
(
    ID_PMI INT IDENTITY(1,1) PRIMARY KEY,

    ID_Empleado INT NOT NULL,

    Actividades VARCHAR(MAX) NOT NULL,

    FechaInicio DATE NOT NULL,

    FechaFin DATE NOT NULL,

    Estado VARCHAR(20)
        DEFAULT 'Pendiente',

    CONSTRAINT FK_PMI_Empleado
        FOREIGN KEY (ID_Empleado)
        REFERENCES Organizacion.Empleado(ID_Empleado),

    CONSTRAINT CK_PMI_Fechas
        CHECK (FechaFin > FechaInicio),

    CONSTRAINT CK_PMI_Estado
        CHECK
        (
            Estado IN
            (
                'Pendiente',
                'En Progreso',
                'Completado'
            )
        )
);
GO

/*====================================================
    TABLA: Desarrollo.Seguimiento
====================================================*/

CREATE TABLE Desarrollo.Seguimiento
(
    ID_Seguimiento INT IDENTITY(1,1) PRIMARY KEY,

    ID_PMI INT NOT NULL,

    EstadoCompromiso VARCHAR(20)
        DEFAULT 'Pendiente',

    Evidencias VARCHAR(MAX) NULL,

    FechaSeguimiento DATE NOT NULL
        DEFAULT GETDATE(),

    CONSTRAINT FK_Seguimiento_PMI
        FOREIGN KEY (ID_PMI)
        REFERENCES Desarrollo.PlanMejora(ID_PMI),

    CONSTRAINT CK_Seguimiento_Estado
        CHECK
        (
            EstadoCompromiso IN
            (
                'Pendiente',
                'En Progreso',
                'Cumplido'
            )
        )
);
GO

CREATE TRIGGER TR_PeriodoActivoUnico
ON Desempeno.PeriodoEvaluativo
AFTER INSERT, UPDATE
AS
BEGIN

    IF EXISTS
    (
        SELECT TipoEvaluacion
        FROM Desempeno.PeriodoEvaluativo
        WHERE Estado='Activo'
        GROUP BY TipoEvaluacion
        HAVING COUNT(*) > 1
    )
    BEGIN
        RAISERROR(
        'Solo puede existir un periodo activo por tipo.',
        16,
        1);

        ROLLBACK TRANSACTION;
    END

END;
GO

CREATE TRIGGER TR_MetaBloqueada
ON Desempeno.Meta
INSTEAD OF UPDATE
AS
BEGIN

    IF EXISTS
    (
        SELECT 1
        FROM Desempeno.Meta M
        INNER JOIN inserted I
            ON M.ID_Meta = I.ID_Meta
        WHERE M.EstadoMeta='Aprobada'
    )
    BEGIN

        RAISERROR(
        'Las metas aprobadas no pueden modificarse.',
        16,
        1);

        RETURN;
    END

    UPDATE M
    SET
        M.ID_Empleado = I.ID_Empleado,
        M.ID_KPI = I.ID_KPI,
        M.ValorMeta = I.ValorMeta,
        M.Peso = I.Peso,
        M.EstadoMeta = I.EstadoMeta
    FROM Desempeno.Meta M
    INNER JOIN inserted I
        ON M.ID_Meta = I.ID_Meta;

END;
GO

CREATE TRIGGER TR_CalcularCumplimiento
ON Desempeno.ResultadoMeta
AFTER INSERT, UPDATE
AS
BEGIN

    UPDATE RM
    SET Cumplimiento =
        (RM.ValorReal / M.ValorMeta) * 100

    FROM Desempeno.ResultadoMeta RM
    INNER JOIN Desempeno.Meta M
        ON RM.ID_Meta = M.ID_Meta
    INNER JOIN inserted I
        ON RM.ID_Resultado = I.ID_Resultado;

END;
GO

CREATE TRIGGER TR_CalcularBrecha
ON Analisis.BrechaCompetencia
AFTER INSERT, UPDATE
AS
BEGIN

    UPDATE B
    SET brecha =
        B.nivelObtenido - B.nivelRequerido
    FROM Analisis.BrechaCompetencia B
    INNER JOIN inserted I
        ON B.brechaID = I.brechaID;

END;
GO
