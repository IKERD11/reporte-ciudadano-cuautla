# Respaldo y restauración del piloto

Procedimiento preparado el 16 de octubre de 2026. **Todavía no ensayado:** el motor Docker local no está disponible. No confundir este documento con un respaldo realizado.

## Alcance y costo

Conservar el plan gratuito. Supabase recomienda exportaciones manuales con CLI para proyectos Free. Un respaldo de PostgreSQL no incluye los archivos de Storage, solamente sus metadatos. [Fuente oficial](https://supabase.com/docs/guides/platform/backups).

No activar recuperación a un punto en el tiempo ni crear proyectos adicionales de pago. Mantener copias cifradas en un medio controlado por el responsable; `backups/` está excluido de Git. No publicar bases, sesiones, claves ni fotografías privadas en GitHub o en el atlas.

## Preparar una copia

1. Identificar el proyecto correcto y anotar fecha, versión de las migraciones y commit del código. Acordar una pausa breve de escrituras para que las copias de base y archivos correspondan al mismo estado.
2. Con Docker disponible y la CLI autenticada, verificar el proyecto vinculado antes de exportar. No pasar contraseñas como argumentos ni pegarlas en el chat.
3. En un directorio nuevo dentro de `backups/`, exportar roles, esquema y datos por separado. Las opciones se comprobaron con la ayuda de CLI 2.117.0:

```powershell
npx supabase db dump --linked --role-only --file backups/roles.sql
npx supabase db dump --linked --file backups/schema.sql
npx supabase db dump --linked --data-only --use-copy --file backups/data.sql
```

Usar nombres de carpeta fechados para sucesivas copias, sin sobrescribir la anterior. Revisar qué esquemas incluye la exportación: Auth y Storage son administrados por Supabase y requieren seguir su [guía de respaldo/restauración](https://supabase.com/docs/guides/platform/migrating-within-supabase/backup-restore). Las migraciones del repositorio tampoco equivalen a una copia de usuarios y datos.

4. Respaldar por separado, mediante Storage API autorizada, los objetos privados que corresponden a la copia. Registrar ruta, tamaño y SHA-256; las URLs firmadas caducables no son un respaldo. No generar copias de evidencia vencida que deba eliminarse según la política aprobada.
5. Conservar también la configuración de Auth, orígenes permitidos y nombres de secretos necesarios. Guardar los valores secretos en un almacén privado separado, no en este documento.
6. Calcular hashes de los archivos, comprobar tamaños y proteger la copia antes de reanudar escrituras. Si falta algún componente, marcar la copia como incompleta.

## Ensayo de recuperación

- Usar exclusivamente una instancia local desechable. Comprobar que el destino es localhost; nunca ejecutar reset o restauración sobre el proyecto remoto del piloto.
- Primero validar reconstrucción del esquema con `npm run db:start`, `npm run db:reset`, `npm run db:test` y `npm run db:lint`. El script reset de este repositorio lleva `--local`.
- Para ensayar una copia de datos, seguir la guía oficial sobre una instancia limpia compatible; no superponer el dump de esquema sobre tablas ya creadas por migraciones. Restaurar usuarios antes de datos que los referencien y cargar objetos por Storage API.
- Mantener correo y tareas de purga externas desactivados en el entorno de restauración. No reutilizar sesiones reales ni credenciales de producción.
- Comparar conteos, relaciones y hashes de evidencias; comprobar acceso por roles, aislamiento municipal, URL privada y flujo de reporte/notificación con cuentas sintéticas.
- Registrar fecha, duración y resultados. Solo tras ese ensayo se podrá declarar la copia recuperable. La restauración remota requiere un plan de intervención independiente.
