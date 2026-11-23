import type {Report} from './api';
import {reportCategoryArtwork} from './map-data';

// Share the app's original artwork and consultation marker geometry in both renderers.
export function createReportMarker(report:Report,onSelect:(id:string)=>void,basePath:string) {
  const artwork=reportCategoryArtwork(report.category);
  const button=document.createElement('button');
  button.type='button';button.className='admin-report-pin';button.dataset.icon=artwork.icon;
  button.style.setProperty('--pin-color',artwork.color);
  button.setAttribute('aria-label',`Abrir reporte ${report.folio}`);
  button.title=`${report.folio} · ${report.category} · ${report.status}`;
  const image=document.createElement('img');image.alt='';image.draggable=false;
  image.src=`${basePath}/branding/report-markers/${artwork.icon}.${artwork.icon==='mourning'?'png':'webp'}`;
  button.append(image);
  button.onclick=event=>{event.stopPropagation();onSelect(report.id);};
  return button;
}
