from pathlib import Path
from io import BytesIO
import json, math
import xml.etree.ElementTree as ET
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from pypdf import PdfReader, PdfWriter, Transformation
from pypdf.generic import FloatObject

ROOT=Path(__file__).resolve().parents[1]
TMP=ROOT/'tmp/pdfs'
OUT=ROOT/'output/pdf/Reporte-Ciudadano-Atlas-Completo.pdf'
items=json.loads((TMP/'items.json').read_text(encoding='utf-8'))
pdfmetrics.registerFont(TTFont('Arial','C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('ArialBold','C:/Windows/Fonts/arialbd.ttf'))
BG='#0c1123'; CARD='#17172f'; FG='#f3efff'; MUTED='#bab1d1'; PURPLE='#aa32ff'; CYAN='#23c8ed'
W,H=1190.55,841.89
writer=PdfWriter()
def text(c,x,y,value,size=12,color=FG,bold=False):
    c.setFillColor(HexColor(color));c.setFont('ArialBold' if bold else 'Arial',size);c.drawString(x,y,value)
def wrap(c,value,x,y,width,size=12,color=MUTED,leading=18):
    words=value.split();line=''
    for word in words:
        new=(line+' '+word).strip()
        if pdfmetrics.stringWidth(new,'Arial',size)>width and line:
            text(c,x,y,line,size,color);y-=leading;line=word
        else: line=new
    if line:text(c,x,y,line,size,color)
    return y-leading
def page(w=W,h=H):
    buf=BytesIO();c=canvas.Canvas(buf,pagesize=(w,h));c.setFillColor(HexColor(BG));c.rect(0,0,w,h,fill=1,stroke=0);return buf,c
def footer(c,n,w=W):
    c.setStrokeColor(HexColor('#34314d'));c.line(42,42,w-42,42)
    text(c,42,23,'REPORTE CIUDADANO  /  CUAUTLA, MORELOS  /  ATLAS TÉCNICO',9,MUTED)
    text(c,w-90,23,f'{n:02}',10,CYAN,True)
def finish(buf,c):
    c.save();buf.seek(0);writer.add_page(PdfReader(buf).pages[0])

buf,c=page()
c.setFillColor(HexColor('#231247'));p=c.beginPath();p.moveTo(820,0);p.lineTo(W,0);p.lineTo(W,H);p.lineTo(1040,H);p.close();c.drawPath(p,fill=1,stroke=0)
c.setStrokeColor(HexColor(PURPLE));c.setLineWidth(3);c.line(820,0,1100,H)
c.drawImage(str(ROOT/'apps/admin/public/branding/logo-dashboard.png'),58,H-206,width=210,height=140,preserveAspectRatio=True,mask='auto')
text(c,62,560,'REPORTE CIUDADANO',18,CYAN,True)
text(c,58,473,'Atlas técnico',62,FG,True)
text(c,58,398,'del sistema',62,FG,True)
c.setFillColor(HexColor(PURPLE));c.roundRect(62,350,116,6,3,fill=1,stroke=0)
wrap(c,'Arquitectura, UML, flujos, modelo de datos y documentación para colaboradores.',62,303,760,23,FG,33)
text(c,62,187,'72 DIAGRAMAS',24,CYAN,True)
text(c,62,151,'25 tablas  ·  Fuentes editables  ·  Propuestas identificadas',15,MUTED)
text(c,62,90,'EDICIÓN 11 OCTUBRE 2026',13,FG,True)
text(c,62,63,'Piloto de Cuautla, Morelos | Costo cero | Identidad sintética',12,MUTED)
finish(buf,c)
buf,c=page();text(c,42,H-65,'Cómo leer este atlas',32,FG,True)
sections=[('ALCANCE','Los 55 diagramas originales se conservan y se complementan con 17 vistas. Las fichas individuales de tablas forman parte de ese total; no son 72 tipos diferentes de diagramas.'),('ESTADO DEL SISTEMA','El documento describe el piloto y su código local. No certifica el estado remoto de la base de datos ni el funcionamiento en dispositivos físicos. La operación municipal real y el uso de INE reales siguen deshabilitados.'),('NOTACIÓN UML','Clases, secuencias y estados emplean los tipos específicos de Mermaid. Casos de uso, paquetes, comunicación, objetos, estructura compuesta e interacción global utilizan representaciones equivalentes. La temporización usa una secuencia temporal. No se declara conformidad gráfica completa con UML 2.x.'),('PROPUESTAS Y EJEMPLOS','El despliegue público de las apps, el respaldo/restauración y el perfil documental son propuestas. Los objetos del ejemplo son ficticios. Las notas de cada página distinguen estos casos de la implementación.'),('LECTURA E IMPRESIÓN','Las páginas usan el azul nocturno, violeta y cian del software. Los planos extensos tienen un tamaño de página mayor para preservar texto vectorial legible. Usar zoom o impresión en mosaico para el modelo general.'),('FUENTES','Código de apps/mobile y apps/admin; migraciones y funciones de supabase; catálogo del atlas. Las referencias al pie son rutas relativas al repositorio. La documentación publicada está en https://ikerd11.github.io/reporte-ciudadano-diagramas/.')]
y=H-125
for label,value in sections:
    text(c,42,y,label,12,CYAN,True);y=wrap(c,value,42,y-25,W-100,14,FG,21)-27
footer(c,2);finish(buf,c)
for part in range(3):
    buf,c=page();text(c,42,H-65,f'Índice de diagramas  {part+1}/3',30,FG,True)
    y=H-112
    for idx in range(part*24,min((part+1)*24,len(items))):
        text(c,42,y,f'{idx+1:02}',12,CYAN,True)
        text(c,87,y,items[idx]['title'],13,FG)
        text(c,W-90,y,str(idx+6),12,MUTED)
        y-=27
    footer(c,part+3);finish(buf,c)

geometry=[]
for idx,item in enumerate(items):
    diagram=PdfReader(TMP/f'diagram-{idx+1}.pdf').pages[0]
    # Chromium paints its PDF canvas white regardless of the SVG background.
    # Replace only pure-white paint with the document's navy canvas.
    content=diagram.get_contents()
    for operands,operator in content.operations:
        if operator in (b'rg',b'RG') and list(operands)==[1,1,1]:
            operands[:]=[FloatObject(v/255) for v in (12,17,35)]
        elif operator==b'rg' and len(operands)==3 and all(abs(float(a)-b)<0.001 for a,b in zip(operands,(0.8997,0.8827,0.9546))):
            operands[:]=[FloatObject(v/255) for v in (21,38,64)]
    diagram.replace_contents(content)
    dw,dh=float(diagram.mediabox.width),float(diagram.mediabox.height)
    # Never shrink a diagram below its original PDF text size.
    natural=1.0
    if idx<55:
        svg=ET.parse(ROOT/f'docs/diagramas/svg/atlas-{idx+1}.svg').getroot()
        box=[float(v) for v in svg.attrib.get('viewBox','0 0 800 600').split()]
        natural=max(1.0,box[2]*0.75/dw,box[3]*0.75/dh)
    w=max(W,dw*natural+100);h=max(H,dh*natural+240)
    buf,c=page(w,h)
    text(c,42,h-36,f"{idx+1:02}  /  {item['kind'].upper()}",11,CYAN,True)
    text(c,42,h-74,item['title'],27,FG,True)
    wrap(c,item['note'],42,h-102,w-90,12,MUTED,17)
    text(c,42,84,item['scope'],10,PURPLE,True)
    wrap(c,'Fuente: '+item['source'],42,66,w-100,9,MUTED,12)
    footer(c,idx+6,w)
    c.save();buf.seek(0);sheet=PdfReader(buf).pages[0]
    available_h=h-235
    factor=min((w-100)/dw,available_h/dh,max(1.45,natural))
    x=(w-dw*factor)/2;y=108+(available_h-dh*factor)/2
    sheet.merge_transformed_page(diagram,Transformation().scale(factor).translate(x,y))
    writer.add_page(sheet)
    writer.add_outline_item(f"{idx+1:02} {item['title']}",idx+5)
    geometry.append({'diagram':idx+1,'page':idx+6,'width':w,'height':h,'scale':factor})
writer.add_metadata({'/Title':'Reporte Ciudadano - Atlas técnico completo','/Author':'Proyecto Reporte Ciudadano Cuautla','/Subject':'72 diagramas de arquitectura, UML, datos y flujos del piloto'})
with OUT.open('wb') as f:writer.write(f)
(TMP/'geometry.json').write_text(json.dumps(geometry,indent=2))
assert len(PdfReader(OUT).pages)==77
print(f'{OUT}: 77 páginas, {OUT.stat().st_size:,} bytes')
