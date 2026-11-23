# Departamentos propuestos para el piloto

Ocho áreas funcionales creadas para Cuautla por solicitud del propietario el
23 de noviembre de 2026. Son una propuesta de organización para las pruebas;
no se presentan como directorio municipal certificado ni activan atención real.

- Seguridad Pública: Robo / Asalto y Vandalismo.
- Tránsito Municipal: Accidente.
- Atención a Víctimas y Violencia: Violencia.
- Alumbrado Público: Alumbrado público.
- Obras Públicas y Mantenimiento Vial: Baches / Vía pública.
- Protección y Bienestar Animal: Maltrato animal.
- Protección Civil: Deceso, como canalización inicial a las autoridades competentes.
- Atención Ciudadana: Otro y revisión inicial de categorías futuras.

La propuesta se ajusta por caso: un accidente puede requerir coordinación con
Protección Civil; los daños por vandalismo, con Obras Públicas; y la violencia,
con Seguridad Pública y servicios especializados. La categoría Deceso requiere
canalización institucional; no implica que Protección Civil investigue o certifique
la causa de una muerte.

## Funcionamiento

Los departamentos son registros reales, activos, del municipio. La migración
`20261123232447_pilot_report_departments.sql` es idempotente y no modifica áreas
existentes, cuentas, permisos ni asignaciones de reportes.

Configuración lista las áreas y sus categorías sugeridas. Al abrir un reporte
sin asignación, el dashboard propone un departamento activo según su categoría.
Solo se selecciona un ID real devuelto por el backend; no se fabrican destinos.
El administrador puede cambiar la propuesta y debe pulsar Guardar asignación
cuando el estado y sus permisos lo permitan. Se conservan las asignaciones
existentes. La propuesta no se guarda automáticamente.

La asignación efectiva sigue utilizando `admin_pilot`, con comprobaciones de
municipio, departamento activo, permisos, estado y versión del reporte. Las
pruebas cubren las nueve categorías, las ocho áreas, los departamentos inactivos
o ausentes y la sugerencia visible en el formulario del navegador.
