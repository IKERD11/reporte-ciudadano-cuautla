import type { Metadata } from 'next';
import type { CSSProperties } from 'react';
import './globals.css';
import 'leaflet/dist/leaflet.css';
import 'maplibre-gl/dist/maplibre-gl.css';
export const metadata: Metadata = {title: 'Panel administrativo · Reporte Ciudadano', description: 'Piloto de reportes ciudadanos de Cuautla, Morelos', robots:{index:false,follow:false}, referrer:'strict-origin-when-cross-origin'};
export default function Layout({children}:{children:React.ReactNode}) {
 const base=process.env.NEXT_PUBLIC_BASE_PATH || '';
 const style={'--cuautla-background':`url('${base}/branding/cuautla.png')`,'--login-background':`url('${base}/branding/login-reference.png')`} as CSSProperties;
 return <html lang="es"><body style={style}>{children}</body></html>;
}
