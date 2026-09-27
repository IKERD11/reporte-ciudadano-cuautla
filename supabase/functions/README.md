# Edge Functions

Fase 3 sintética desplegada: `identity-pilot` valida JWT, sesión vigente, consentimiento y huellas SHA-256 de muestras; `identity-purge` elimina archivos vencidos con Storage API y confirma la purga en PostgreSQL.

Guía y límites: [fase 3](../../docs/fase-3-identidad.md). Las claves privilegiadas solo se leen del entorno del servidor. Las INE reales y los proveedores de OCR/autenticidad están deshabilitados.

No se han implementado funciones de reportes ni notificaciones de fases posteriores.
