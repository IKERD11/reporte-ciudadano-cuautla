'use client';
import {useEffect,useRef} from 'react';
import L from 'leaflet';
import type {Report} from '../lib/api';
export default function ReportMap({reports,onSelect}:{reports:Report[];onSelect:(id:string)=>void}) {
 const host=useRef<HTMLDivElement>(null);
 useEffect(()=>{
  if(!host.current)return;
  const map=L.map(host.current,{scrollWheelZoom:false}).setView([18.812,-98.955],14);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',maxZoom:19}).addTo(map);
  const points:L.LatLngTuple[]=[];
  for(const r of reports){if(r.latitude==null||r.longitude==null)continue;const point:L.LatLngTuple=[r.latitude,r.longitude];points.push(point);
   const color=r.status_code==='EN_ATENCION'?'#f6a117':['RESUELTO','CERRADO'].includes(r.status_code)?'#13b86b':'#087dff';
   const marker=L.marker(point,{icon:L.divIcon({className:'map-marker',html:`<span style="background:${color}"></span>`,iconSize:[24,32],iconAnchor:[12,30]})}).addTo(map);
   const button=document.createElement('button');button.textContent=r.folio;button.onclick=()=>onSelect(r.id);marker.bindPopup(button);
  }
  if(points.length)map.fitBounds(L.latLngBounds(points),{padding:[35,35],maxZoom:15});
  const observer=new ResizeObserver(()=>map.invalidateSize());observer.observe(host.current);
  return()=>{observer.disconnect();map.remove();};
 },[reports,onSelect]);
 return <div ref={host} className="map" aria-label="Mapa de los reportes de la página actual"/>;
}
