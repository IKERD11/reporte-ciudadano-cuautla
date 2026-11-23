'use client';
import {useEffect,useRef} from 'react';
import L from 'leaflet';
import type {Report} from '../lib/api';
import {reportCoordinate} from '../lib/map-data';
import {createReportMarker} from '../lib/report-marker';
export default function ReportMap({reports,onSelect}:{reports:Report[];onSelect:(id:string)=>void}) {
 const host=useRef<HTMLDivElement>(null);
 useEffect(()=>{
  if(!host.current)return;
  const map=L.map(host.current,{scrollWheelZoom:false}).setView([18.812,-98.955],14);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png',{attribution:'© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',maxZoom:19}).addTo(map);
  const points:L.LatLngTuple[]=[];
  for(const r of reports){const coordinate=reportCoordinate(r);if(!coordinate)continue;const point:L.LatLngTuple=[coordinate[1],coordinate[0]];points.push(point);
   const button=createReportMarker(r,onSelect,process.env.NEXT_PUBLIC_BASE_PATH||'');
   L.marker(point,{keyboard:false,icon:L.divIcon({className:'admin-marker-container',html:button,iconSize:[54,54],iconAnchor:[27,61]})}).addTo(map);
  }
  if(points.length)map.fitBounds(L.latLngBounds(points),{padding:[35,35],maxZoom:15});
  const observer=new ResizeObserver(()=>map.invalidateSize());observer.observe(host.current);
  return()=>{observer.disconnect();map.remove();};
 },[reports,onSelect]);
 return <div ref={host} className="map" aria-label="Mapa de los reportes de la página actual"/>;
}
