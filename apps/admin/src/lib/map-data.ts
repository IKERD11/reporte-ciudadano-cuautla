import type {Report} from './api';

export function reportCoordinate(report: Pick<Report,'latitude'|'longitude'>): [number,number] | null {
  const {latitude,longitude}=report;
  return typeof latitude==='number' && Number.isFinite(latitude) && Math.abs(latitude)<=90
    && typeof longitude==='number' && Number.isFinite(longitude) && Math.abs(longitude)<=180
    ? [longitude,latitude] : null;
}

// Matches Flutter categoryArtwork and the citizen consultation map colors.
export function reportCategoryArtwork(category:string) {
  const name=category.toLowerCase();
  let icon='more';
  if(/robo|asalto|seguridad/.test(name))icon='robbery';
  else if(/accidente|tránsito/.test(name))icon='car';
  else if(/vandal/.test(name))icon='spray';
  else if(/violencia/.test(name))icon='users';
  else if(/alumbr|lumin|servicio/.test(name))icon='bulb';
  else if(/bache|vial/.test(name))icon='cone';
  else if(/deceso/.test(name))icon='mourning';
  else if(/animal/.test(name))icon='paw';
  const color=icon==='robbery'||icon==='users'?'#ff3d55'
    :icon==='paw'||icon==='spray'?'#813de4'
    :icon==='cone'?'#ff8c1a':icon==='bulb'?'#08b989':'#176bea';
  return {icon,color};
}
