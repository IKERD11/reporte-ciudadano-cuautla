# Mapa 3D del dashboard

El dashboard utiliza MapLibre GL JS 6.19.0 con el mismo estilo Liberty de
OpenFreeMap que utiliza la app ciudadana. La vista inicial está inclinada y
orientada sobre Cuautla. Los edificios se representan con la capa `building`
de OpenMapTiles a partir del nivel de zoom 14. La altura procede de los datos
disponibles; no es una reconstrucción fotográfica de la ciudad.

## Uso

- Disponible en Resumen, Mapa y detalle del reporte.
- Botón 3D/2D para alternar inclinación y edificios en volumen.
- Controles para acercar, alejar y restablecer orientación; también admite
  rotación mediante arrastre con botón derecho y gestos táctiles.
- Ver reportes encuadra las ubicaciones de la página actual, hasta 20 resultados.
- Cada marcador abre su reporte real y conserva el color correspondiente al estado.
- No se inventan coordenadas para reportes sin ubicación válida.
- La actualización periódica cambia los marcadores sin reiniciar la cámara.
- Si WebGL no está disponible o el estilo no carga, se puede elegir Ver mapa 2D
  para utilizar el respaldo Leaflet con los mismos reportes.

Los edificios se aprecian al acercarse a las calles. Un encuadre regional de
reportes muy separados puede quedar por debajo del nivel de zoom de edificios.
Los créditos de OpenFreeMap, OpenMapTiles y OpenStreetMap permanecen visibles.
No se añadieron servicios de pago ni claves de mapas.

## Compilar

`npm install`/`npm ci` instalan la versión fijada en el lockfile. Los comandos
`npm run dev` y `npm run build` preparan automáticamente el worker del mapa
en `public/maps/maplibre-6.19.0/`, con su licencia. Ese directorio generado se
excluye de Git. La exportación estática incluye el worker y respeta
`NEXT_PUBLIC_BASE_PATH`, incluida la subruta de GitHub Pages.

## Validación

- Pruebas de coordenadas inválidas, orden longitud/latitud y colores por estado.
- TypeScript y compilación estática de producción.
- Prueba de navegador con cuenta sintética y Supabase real: carga de mapas
  vectoriales, worker local, alternancia 2D/3D, vista Mapa, actualización de datos,
  apertura del detalle desde un marcador y liberación del mapa al cerrar sesión.
- Prueba sin WebGL: aviso de fallo y respaldo 2D con marcadores reales.

La prueba de navegador usa Playwright y Edge. Requiere una compilación estática,
la configuración local del piloto y las cuentas sintéticas locales existentes:

```powershell
$env:PLAYWRIGHT_MODULE='ruta/al/modulo/playwright'
node scripts/test-admin-map.cjs
```

Consulta y navega sin crear ni modificar reportes; cierra la sesión de prueba.
