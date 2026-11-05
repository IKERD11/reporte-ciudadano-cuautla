/* MapLibre GL JS bridge for the Flutter web pilot. No account data or geocoder lives here. */
(function (global) {
  'use strict';
  const STYLE = 'https://tiles.openfreemap.org/styles/liberty';
  const CENTER = [-98.9548, 18.8126];
  const BUILDINGS = 'citizen-buildings-3d';
  const scriptBase = new URL('../', document.currentScript.src);
  let loading;
  function loadLibrary() {
    if (global.maplibregl) return Promise.resolve(global.maplibregl);
    if (loading) return loading;
    loading = new Promise((resolve, reject) => {
      const script = document.createElement('script');
      const timer = setTimeout(() => finish(new Error('Tiempo de carga agotado')), 20000);
      function finish(error) {
        clearTimeout(timer); script.onload = script.onerror = null;
        if (error) { script.remove(); reject(error); }
        else resolve(global.maplibregl);
      }
      script.src = new URL('vendor/maplibre-gl-4.7.1/maplibre-gl.js', scriptBase).href;
      script.onload = () => global.maplibregl ? finish() : finish(new Error('MapLibre no disponible'));
      script.onerror = () => finish(new Error('No se pudo descargar MapLibre'));
      document.head.appendChild(script);
    }).catch(error => { loading = null; throw error; });
    return loading;
  }
  function coordinate(point) {
    return point && Number.isFinite(point.latitude) && Number.isFinite(point.longitude) &&
      Math.abs(point.latitude) <= 90 && Math.abs(point.longitude) <= 180
      ? [point.longitude, point.latitude] : null;
  }
  function node(tag, className, text) {
    const element = document.createElement(tag);
    if (className) element.className = className;
    if (text) element.textContent = text;
    return element;
  }
  function create(host, initial, handlers = {}) {
    let options = initial, map, selectedMarker, markers = [], listeners = [];
    let dead = false, generation = 0, timer, threeD = !!(initial.initial3D && initial.allow3D && !initial.editable);
    let lastZone = null;
    let lastPoint = null, markerListeners = [], demoLabel, currentControls, failed = false;
    host.className = 'citizen-map';
    host.dataset.mode = initial.allow3D && !initial.editable ? 'consultation' : 'picker';
    const stage = node('div', 'citizen-map-stage');
    const attribution = node('div', 'citizen-map-attribution');
    for (const [text, href] of [
      ['OpenFreeMap', 'https://openfreemap.org/'],
      ['© OpenMapTiles', 'https://openmaptiles.org/'],
      ['© OpenStreetMap', 'https://www.openstreetmap.org/copyright'],
    ]) {
      const link = node('a', '', text);
      link.href = href; link.target = '_blank'; link.rel = 'noopener noreferrer';
      attribution.appendChild(link);
    }
    const status = node('div', 'citizen-map-status');
    status.setAttribute('role', 'status'); status.setAttribute('aria-live', 'polite');
    const message = node('span');
    const retry = node('button', '', 'Reintentar'); retry.type = 'button';
    status.append(message, retry);
    for (const [index, icon] of ['robbery','paw','cone','car'].entries()) {
      const decoration=node('img', `citizen-map-fallback-marker fallback-${index}`);
      decoration.alt=''; decoration.setAttribute('aria-hidden','true');
      decoration.src=new URL(`assets/assets/renewal/icons/3d/${icon}.webp`, document.baseURI).href;
      status.appendChild(decoration);
    }
    host.replaceChildren(stage, attribution);
    if (initial.allow3D && !initial.editable) {
          const toggle = node('button', 'citizen-map-mode', threeD ? '3D' : '2D'); toggle.type = 'button';
          toggle.title = 'Alternar vista 2D y 3D'; toggle.setAttribute('aria-label', toggle.title); toggle.setAttribute('aria-pressed', String(threeD));
          toggle.onclick = event => {
            event.stopPropagation(); threeD = !threeD; setDimension();
            map?.easeTo({pitch: threeD ? 48 : 0, bearing: threeD ? -18 : 0, duration: global.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 0 : 650});
            toggle.textContent = threeD ? '3D' : '2D'; toggle.setAttribute('aria-pressed', String(threeD));
          }; host.appendChild(toggle);
        }

    function state(value) {
      if (dead) return;
      status.hidden = value === 'ready';
      status.dataset.state = value;
      if (currentControls) currentControls.hidden = value !== 'ready' || !!options.preview || !!options.hideControls;
      message.textContent = value === 'loading' ? 'Cargando mapa...' : 'No se pudo cargar el mapa de OpenFreeMap';
      retry.hidden = value !== 'error';
      handlers.onState?.(value);
    }
    function listen(target, type, callback) {
      target.on(type, callback);
      listeners.push(() => target.off(type, callback));
    }
    function clearMarkers() {
      for (const remove of markerListeners.splice(0)) remove();
      for (const marker of markers) { marker.getElement().onclick = null; marker.remove(); }
      markers = [];
      selectedMarker?.remove(); selectedMarker = null;
    }
    function release() {
      clearTimeout(timer);
      for (const remove of listeners.splice(0)) remove();
      clearMarkers();
      currentControls?.remove(); currentControls = null;
      map?.remove(); map = null; lastZone = null;
    }
    function emitPoint(position) {
      if (dead || !options.editable) return;
      options = {...options, point: {latitude: position.lat, longitude: position.lng}};
      lastPoint = [position.lng, position.lat];
      handlers.onSelected?.(position.lat, position.lng);
    }
    function renderMarkers() {
      if (!map) return;
      clearMarkers();
      const selected = coordinate(options.point);
      if (selected && options.showPointMarker !== false) {
        const markerOptions = {color:'#1769ea',draggable:!!options.editable};
        if(options.showZoneRadius === true) {
          const image=node('img','citizen-map-zone-pin'); image.alt='';
          image.src=new URL('assets/assets/renewal/icons/3d/pin.webp',document.baseURI).href;
          markerOptions.element=image;markerOptions.anchor='bottom';
        }
        selectedMarker = new global.maplibregl.Marker(markerOptions)
          .setLngLat(selected).addTo(map);
        selectedMarker.getElement().setAttribute('aria-label', options.editable ? 'Ubicación seleccionada. Arrastra el marcador para moverla.' : 'Ubicación del incidente');
        const marker = selectedMarker;
        const dragged = () => emitPoint(marker.getLngLat());
        marker.on('dragend', dragged);
        markerListeners.push(() => marker.off('dragend', dragged));
      }
      for (const report of options.reports || []) {
        const position = coordinate(report);
        if (!position || !report.id) continue;
        const element = node('button', 'citizen-map-marker');
        element.type = 'button';
        const demo = report.source === 'demo';
        const title = `${report.title || 'Reporte'}${demo ? ' · Reporte de demostración' : ''}`;
        element.setAttribute('aria-label', title); element.title = title;
        element.dataset.demo = String(demo);
        element.dataset.icon = report.icon || 'more';
        const image = node('img'); image.alt = '';
        // Artwork is supplied by Flutter's existing category mapping, never by remote report data.
        image.src = new URL(`assets/assets/renewal/icons/3d/${/^[a-z-]+$/.test(report.icon) ? report.icon : 'more'}.${report.icon === 'mourning' ? 'png' : 'webp'}`, document.baseURI).href;
        element.appendChild(image);
        element.onclick = event => { event.stopPropagation(); if (!dead) handlers.onReportSelected?.(report.id); };
        const marker = new global.maplibregl.Marker({element, anchor: 'bottom', offset: [0, -7]}).setLngLat(position).addTo(map);
        element.setAttribute('aria-label', title);
        markers.push(marker);
      }
    }
    function setDimension() {
      if (!map || !map.isStyleLoaded()) return;
      if (options.allow3D && !options.editable && !map.getLayer(BUILDINGS) && map.getSource('openmaptiles')) {
        const before = map.getStyle().layers.find(layer => layer.type === 'symbol' && layer.layout?.['text-field'])?.id;
        map.addLayer({id: BUILDINGS, type: 'fill-extrusion', source: 'openmaptiles', 'source-layer': 'building', minzoom: 14,
          layout: {visibility: threeD ? 'visible' : 'none'},
          paint: {'fill-extrusion-color': ['interpolate', ['linear'], ['zoom'], 14, '#d7e3e8', 17, '#b9ccd5'], 'fill-extrusion-height': ['coalesce', ['get', 'render_height'], ['get', 'height'], 6],
            'fill-extrusion-base': ['coalesce', ['get', 'render_min_height'], ['get', 'min_height'], 0], 'fill-extrusion-opacity': 0.72}}, before);
      }
      if (map.getLayer(BUILDINGS)) map.setLayoutProperty(BUILDINGS, 'visibility', threeD ? 'visible' : 'none');
    }
    function updateZone() {
      if (!map?.isStyleLoaded()) return;
      const center = coordinate(options.point), radius = options.radiusKm;
      const enabled = options.showZoneRadius === true && center && Number.isFinite(radius) && radius >= 1 && radius <= 10;
      const signature = JSON.stringify([center, radius, options.showZoneRadius === true]);
      if (signature === lastZone && map.getSource('citizen-zone')) return;
      const coordinates = [];
      if (enabled) {
        const lat = center[1] * Math.PI / 180, lng = center[0] * Math.PI / 180, distance = radius / 6371;
        for (let i = 0; i <= 80; i++) {
          const angle = i / 80 * Math.PI * 2;
          const y = Math.asin(Math.sin(lat)*Math.cos(distance)+Math.cos(lat)*Math.sin(distance)*Math.cos(angle));
          const x = lng + Math.atan2(Math.sin(angle)*Math.sin(distance)*Math.cos(lat),Math.cos(distance)-Math.sin(lat)*Math.sin(y));
          coordinates.push([x*180/Math.PI,y*180/Math.PI]);
        }
      }
      const data = {type:'FeatureCollection',features: enabled ? [{type:'Feature',properties:{},geometry:{type:'Polygon',coordinates:[coordinates]}}] : []};
      if (enabled && options.editable && signature !== lastZone) {
        const deltaLat = radius / 111.2, deltaLng = deltaLat / Math.cos(center[1] * Math.PI / 180);
        map.fitBounds([[center[0]-deltaLng,center[1]-deltaLat],[center[0]+deltaLng,center[1]+deltaLat]], {padding:35,duration:lastZone ? 250 : 0});
      }
      lastZone = signature;
      if(map.getSource('citizen-zone')) map.getSource('citizen-zone').setData(data);
      else {
        map.addSource('citizen-zone',{type:'geojson',data});
        map.addLayer({id:'citizen-zone-fill',type:'fill',source:'citizen-zone',paint:{'fill-color':'#3b9df5','fill-opacity':0.16}});
        map.addLayer({id:'citizen-zone-line',type:'line',source:'citizen-zone',paint:{'line-color':'#2387e9','line-width':2,'line-opacity':0.55}});
      }
    }
    function apply() {
      host.classList.toggle('hide-map-controls', !!options.hideControls);
      host.classList.toggle('citizen-map-preview', !!options.preview);
      host.style.setProperty('--map-bottom', `${Math.max(0, options.bottomInset || 0)}px`);
      host.style.setProperty('--control-top', `${Math.max(0, options.controlTop || 8)}px`);
      status.style.top = options.editable ? '76px' : '50%';
      if (!map) return;
      if (currentControls) currentControls.hidden = !!options.preview || !!options.hideControls || status.dataset.state !== 'ready';
      renderMarkers();
      if (demoLabel) demoLabel.hidden = !(options.reports || []).some(report => report.source === 'demo');
      const point = coordinate(options.point);
      if (point && JSON.stringify(point) !== JSON.stringify(lastPoint)) map.easeTo({center: point, zoom: options.zoom || map.getZoom(), duration: global.matchMedia?.('(prefers-reduced-motion: reduce)').matches ? 0 : (options.cameraDuration ?? 300)});
      lastPoint = point;
      updateZone();
      map.resize();
    }
    async function start() {
      const run = ++generation;
      release(); failed = false; stage.replaceChildren(); state('loading');
      // The status belongs inside the viewport, above the persistent attribution and away from cards.
      stage.appendChild(status);
      try {
        const library = await loadLibrary();
        if (dead || generation !== run) return;
        const canvas = node('div'); canvas.style.cssText = 'position:absolute;inset:0';
        stage.prepend(canvas);
        map = new library.Map({container: canvas, interactive: !options.preview, style: STYLE, center: coordinate(options.point) || CENTER, zoom: options.zoom || 16,
          pitch: options.allow3D && !options.editable && threeD ? 48 : 0, bearing: threeD ? -18 : 0, maxPitch: options.allow3D && !options.editable ? 85 : 0, attributionControl: false, renderWorldCopies: false,
          dragRotate: !!(options.allow3D && !options.editable), touchPitch: !!(options.allow3D && !options.editable), pitchWithRotate: !!(options.allow3D && !options.editable)});
        listen(map, 'styleimagemissing', ({id}) => {
          if (!map.hasImage(id)) map.addImage(id,{width:1,height:1,data:new Uint8Array([0,0,0,0])});
        });
        if (!options.allow3D || options.editable) map.touchZoomRotate.disableRotation();

        const controls = node('div', 'citizen-map-controls');
        currentControls = controls; controls.hidden = true;
        for (const [label, text, action] of [
          ['Acercar mapa', '+', () => map?.zoomIn()], ['Alejar mapa', '−', () => map?.zoomOut()],
        ]) {
          const button = node('button', 'citizen-map-button', text); button.type = 'button'; button.title = label; button.setAttribute('aria-label', label);
          button.onclick = event => { event.stopPropagation(); action(); }; controls.appendChild(button);
        }
        demoLabel = node('div', 'citizen-map-demo', 'Datos de demostración');
        host.appendChild(controls);
        stage.appendChild(demoLabel);
        listen(map, 'click', event => {
          if (!options.editable) return;
          if (!selectedMarker) {
            options = {...options, point: {latitude: event.lngLat.lat, longitude: event.lngLat.lng}};
            renderMarkers();
          } else selectedMarker.setLngLat(event.lngLat);
          emitPoint(event.lngLat);
        });
        listen(map, 'load', () => { if (dead || generation !== run) return; clearTimeout(timer); setDimension(); updateZone(); if (!failed) state('ready'); });
        listen(map, 'error', () => { if (!dead && generation === run) { failed = true; state('error'); } });
        listen(map, 'idle', () => { updateZone(); if (!dead && !failed && map?.isStyleLoaded() && map.areTilesLoaded()) { clearTimeout(timer); state('ready'); } });
        const lost = event => { event.preventDefault(); failed = true; state('error'); };
        map.getCanvas().addEventListener('webglcontextlost', lost);
        listeners.push(() => map?.getCanvas().removeEventListener('webglcontextlost', lost));
        timer = setTimeout(() => { failed = true; state('error'); }, 25000);
        apply();
      } catch (_) { if (!dead && generation === run) { failed = true; state('error'); } }
    }
    const observer = new ResizeObserver(() => { if (!dead) map?.resize(); }); observer.observe(host);
    retry.onclick = () => start();
    apply(); start();
    return {
      update(value) { if (dead) return; options = value; apply(); },
      dispose() { if (dead) return; dead = true; ++generation; observer.disconnect(); release(); retry.onclick = null; host.replaceChildren(); },
    };
  }
  global.CitizenMapLibre = {create};
})(globalThis);
