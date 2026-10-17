# Edge Functions

Fase 3 sintética desplegada: `identity-pilot` valida JWT, sesión vigente, consentimiento y huellas SHA-256 de muestras; `identity-purge` elimina archivos vencidos con Storage API y confirma la purga en PostgreSQL.

Guía y límites: [fase 3](../../docs/fase-3-identidad.md). Las claves privilegiadas solo se leen del entorno del servidor. Las INE reales y los proveedores de OCR/autenticidad están deshabilitados.

`report-pilot` implementa reportes, fotografías privadas y búsqueda de direcciones públicas con caché y límites globales. Los avisos internos se consultan por RPC `citizen_notifications`. Ver [estado actual](../../docs/cierre-piloto-2026-10-15.md).
