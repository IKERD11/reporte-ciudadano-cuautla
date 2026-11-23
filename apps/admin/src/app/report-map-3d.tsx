'use client';
import {useEffect,useRef,useState} from 'react';
import dynamic from 'next/dynamic';
import {Map as LibreMap,Marker,LngLatBounds,NavigationControl,AttributionControl,setWorkerUrl} from 'maplibre-gl';
import type {Report} from '../lib/api';
import {reportCoordinate} from '../lib/map-data';
import {createReportMarker} from '../lib/report-marker';
const FlatMap=dynamic(()=>import('./report-map-fallback'),{ssr:false});
const buildings='admin-buildings-3d';
const center:[number,number]=[-98.9548,18.8126];

export default function ReportMap({reports,onSelect}:{reports:Report[];onSelect:(id:string)=>void}) {
 const host=useRef<HTMLDivElement>(null),mapRef=useRef<LibreMap|null>(null);
 const markers=useRef<Marker[]>([]),selectRef=useRef(onSelect),fitted=useRef(false),dimension=useRef(true);
 const [ready,setReady]=useState(false),[threeD,setThreeD]=useState(true);
 const [error,setError]=useState(false),[fallback,setFallback]=useState(false);
 useEffect(()=>{selectRef.current=onSelect;},[onSelect]);
 useEffect(()=>{
  if(!host.current||fallback)return;
  let disposed=false,map:LibreMap|undefined,observer:ResizeObserver|undefined;
  const timeout=setTimeout(()=>{if(!disposed&&!map?.isStyleLoaded())setError(true);},20_000);
  try {
   setWorkerUrl(`${process.env.NEXT_PUBLIC_BASE_PATH||''}/maps/maplibre-6.19.0/worker.mjs`);
   map=new LibreMap({container:host.current,style:'https://tiles.openfreemap.org/styles/liberty',center,zoom:15.5,
    pitch:48,bearing:-18,maxPitch:75,renderWorldCopies:false,attributionControl:false,scrollZoom:false,
    canvasContextAttributes:{antialias:true},locale:{'NavigationControl.ZoomIn':'Acercar',
     'NavigationControl.ZoomOut':'Alejar','NavigationControl.ResetBearing':'Restablecer orientación',
     'AttributionControl.ToggleAttribution':'Mostrar atribuciones'}});
   mapRef.current=map;
   map.addControl(new NavigationControl({visualizePitch:true}),'top-right');
   map.addControl(new AttributionControl({compact:true}),'bottom-right');
   map.touchZoomRotate.enableRotation();
   map.on('load',()=>{
    if(disposed||!map)return;clearTimeout(timeout);
    if(map.getSource('openmaptiles')&&!map.getLayer(buildings)) {
     const labels=map.getStyle().layers.find(layer=>layer.type==='symbol'&&layer.layout?.['text-field'])?.id;
     map.addLayer({id:buildings,type:'fill-extrusion',source:'openmaptiles','source-layer':'building',minzoom:14,
      layout:{visibility:dimension.current?'visible':'none'},paint:{'fill-extrusion-color':'#acbfd0',
       'fill-extrusion-height':['coalesce',['get','render_height'],['get','height'],6],
       'fill-extrusion-base':['coalesce',['get','render_min_height'],['get','min_height'],0],
       'fill-extrusion-opacity':0.8}},labels);
    }
    setReady(true);setError(false);
   });
   observer=new ResizeObserver(()=>map?.resize());observer.observe(host.current);
  } catch {clearTimeout(timeout);setError(true);}
  return()=>{
   disposed=true;clearTimeout(timeout);observer?.disconnect();
   markers.current.forEach(marker=>marker.remove());markers.current=[];
   map?.remove();mapRef.current=null;fitted.current=false;
  };
 },[fallback]);
 useEffect(()=>{
  const map=mapRef.current;if(!map||!ready||fallback)return;
  markers.current.forEach(marker=>marker.remove());markers.current=[];
  const bounds=new LngLatBounds();
  for(const report of reports) {
   const coordinate=reportCoordinate(report);if(!coordinate)continue;bounds.extend(coordinate);
   const button=createReportMarker(report,id=>selectRef.current(id),process.env.NEXT_PUBLIC_BASE_PATH||'');
   markers.current.push(new Marker({element:button,anchor:'bottom',offset:[0,-7]}).setLngLat(coordinate).addTo(map));
  }
  // Polling updates pins without resetting the user's camera.
  if(!bounds.isEmpty()&&!fitted.current) {
   map.fitBounds(bounds,{padding:55,maxZoom:16,pitch:dimension.current?48:0,bearing:dimension.current?-18:0,duration:0});
   fitted.current=true;
  }
 },[reports,ready,fallback]);
 function toggleDimension() {
  const next=!threeD;setThreeD(next);dimension.current=next;
  const map=mapRef.current;if(!map)return;
  if(map.getLayer(buildings))map.setLayoutProperty(buildings,'visibility',next?'visible':'none');
  map.easeTo({pitch:next?48:0,bearing:next?-18:0,duration:window.matchMedia('(prefers-reduced-motion: reduce)').matches?0:550});
 }
 function fitReports() {
  const map=mapRef.current;if(!map)return;const bounds=new LngLatBounds();
  reports.forEach(report=>{const point=reportCoordinate(report);if(point)bounds.extend(point);});
  if(bounds.isEmpty())map.easeTo({center,zoom:15.5});
  else map.fitBounds(bounds,{padding:55,maxZoom:16,pitch:threeD?48:0,bearing:threeD?-18:0,duration:0});
 }
 if(fallback)return <FlatMap reports={reports} onSelect={onSelect}/>;
 return <div className="admin-map-wrap">
  <div ref={host} className="map admin-vector-map" aria-label="Mapa 3D de los reportes de la página actual"/>
  <div className="admin-map-tools" role="group" aria-label="Controles del mapa">
   <button type="button" onClick={toggleDimension} aria-pressed={threeD} disabled={!ready} aria-label={threeD?'Cambiar a mapa 2D':'Cambiar a mapa 3D'}>{threeD?'3D':'2D'}</button>
   <button type="button" onClick={fitReports} disabled={!ready}>Ver reportes</button>
  </div>
  {!ready&&!error&&<div className="admin-map-status" role="status">Cargando mapa 3D…</div>}
  {error&&<div className="admin-map-status error" role="alert"><span>No se pudo cargar el mapa 3D.</span><button type="button" className="outline" onClick={()=>setFallback(true)}>Ver mapa 2D</button></div>}
 </div>;
}
