# Categorías compartidas entre la app y el dashboard

El catálogo visible sigue los nombres y el orden del selector de reportes
de la app ciudadana:

1. Robo / Asalto — `robbery.webp`.
2. Accidente — `car.webp`.
3. Vandalismo — `spray.webp`.
4. Violencia — `users.webp`.
5. Alumbrado público — `bulb.webp`.
6. Baches / Vía pública — `cone.webp`.
7. Maltrato animal — `paw.webp`.
8. Deceso — `mourning.png`.
9. Otro — `more.webp`.

Configuración muestra los iconos originales de la app y los estados reales del
backend. Los filtros utilizan estos mismos nombres, orden e identificadores de
categoría; no crean categorías ficticias en el navegador.

La migración `20261123231847_align_app_dashboard_categories.sql` alinea el catálogo
de Cuautla: renombra Baches conservando su ID, incorpora Deceso si falta y ordena
las nueve categorías. Recolección de residuos se conserva como registro histórico
inactivo y no público, fuera de la oferta actual de la app. No se elimina ningún
reporte ni se cambian sus relaciones, permisos o esquemas de captura.

Las pruebas comparan los nombres directamente con `ReportWizard.choices`, verifican
que se conserven IDs y estados, y comparan las imágenes con sus archivos originales.
La prueba de navegador comprueba las nueve filas de Configuración, sus nombres,
iconos, carga de imágenes y estado activo utilizando el backend real del piloto.
