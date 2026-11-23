import type {Report} from './api';

export function reportCoordinate(report: Pick<Report,'latitude'|'longitude'>): [number,number] | null {
  const {latitude,longitude}=report;
  return typeof latitude==='number' && Number.isFinite(latitude) && Math.abs(latitude)<=90
    && typeof longitude==='number' && Number.isFinite(longitude) && Math.abs(longitude)<=180
    ? [longitude,latitude] : null;
}

export function reportMarkerColor(status:string) {
  return status==='EN_ATENCION' ? '#f6a117' : ['RESUELTO','CERRADO'].includes(status) ? '#13b86b'
    : ['RECHAZADO','DUPLICADO'].includes(status) ? '#ec637b' : '#087dff';
}
