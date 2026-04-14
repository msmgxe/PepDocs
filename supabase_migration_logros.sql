-- Agregar columnas de edad y sexo a la tabla perfiles para cálculo de logros

ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS age INT,
ADD COLUMN IF NOT EXISTS sex VARCHAR(255);

-- Opcional: Agregar restricción de verificación para sex (M, F, O)
-- ALTER TABLE profiles ADD CONSTRAINT chk_sex CHECK (sex IN ('M', 'F', 'O', 'masculino', 'femenino'));
