import type { Metadata } from 'next';
import './globals.css';
import 'leaflet/dist/leaflet.css';
export const metadata: Metadata = {title: 'Panel administrativo · Reporte Ciudadano', description: 'Piloto de reportes ciudadanos de Cuautla, Morelos'};
export default function Layout({children}:{children:React.ReactNode}) {return <html lang="es"><body>{children}</body></html>;}
