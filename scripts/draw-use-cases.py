"""Replace diagram 06 with a vector UML use-case view before build-pdf-atlas.py."""
from pathlib import Path
import json
from reportlab.pdfgen import canvas
from reportlab.lib.colors import HexColor
ROOT=Path(__file__).resolve().parents[1]
P=ROOT/'tmp/pdfs'
c=canvas.Canvas(str(P/'diagram-6.pdf'),pagesize=(1300,840))
white=HexColor('#f3efff');purple=HexColor('#aa32ff');cyan=HexColor('#23c8ed')
def label(x,y,lines,size=13):
 c.setFillColor(white);c.setFont('Helvetica',size)
 for i,line in enumerate(lines):c.drawCentredString(x,y+(len(lines)-1)*8-i*16,line)
def actor(x,y,lines):
 c.setStrokeColor(cyan);c.setLineWidth(2)
 c.circle(x,y+35,13,stroke=1,fill=0)
 c.line(x,y+22,x,y-18);c.line(x-23,y+5,x+23,y+5)
 c.line(x,y-18,x-21,y-44);c.line(x,y-18,x+21,y-44)
 label(x,y-67,lines)
def use(x,y,lines):
 c.setFillColor(HexColor('#21183e'));c.setStrokeColor(purple);c.setLineWidth(1.4)
 c.ellipse(x-145,y-29,x+145,y+29,stroke=1,fill=1);label(x,y-4,lines)
def link(x,y,tx,ty):
 c.setStrokeColor(HexColor('#8976b4'));c.setLineWidth(.9);c.line(x,y,tx,ty)
c.setStrokeColor(purple);c.setLineWidth(1.5);c.rect(225,35,850,765,stroke=1,fill=0)
label(650,771,['Reporte Ciudadano - piloto de Cuautla'],20)
cit=[(435,690,['Registrarse y confirmar correo']),(435,590,['Gestionar perfil y cuenta']),(435,490,['Crear reporte de prueba']),(435,390,['Consultar reportes y mapa propios']),(435,290,['Consultar avisos internos']),(435,190,['Enviar muestras sintéticas'])]
adm=[(865,690,['Consultar reportes municipales']),(865,590,['Asignar departamento / responsable']),(865,490,['Cambiar prioridad y estado']),(865,390,['Consultar métricas y equipos']),(865,290,['Crear departamento autorizado']),(865,190,['Revisar muestras sintéticas'])]
for x,y,_ in cit:link(140,450,x-145,y)
for x,y,_ in adm[:5]:link(1160,570,x+145,y)
link(1160,325,1010,490)
link(1160,325,1010,690)
link(1160,120,1010,190)
for x,y,t in cit+adm:use(x,y,t)
actor(115,450,['Ciudadano'])
actor(1185,570,['Administrador','municipal'])
actor(1185,325,['Operador / supervisor'])
actor(1185,120,['Revisor de identidad'])
label(650,103,['Asociaciones sujetas a permisos, municipio y alcance del reporte.'],12)
label(650,78,['El revisor necesita identity.read e identity.review; solo muestras sintéticas.'],12)
c.save()
items=json.loads((P/'items.json').read_text(encoding='utf-8'))
items[5]['title']='Casos de uso del sistema'
items[5]['kind']='UML · Casos de uso'
items[5]['note']='Actores externos, casos de uso y límite del sistema. La asociación indica participación, no concesión automática de permisos. Las consultas sin escritura corresponden al rol Viewer.'
items[5]['scope']='Piloto implementado · Actores y funciones sujetos a autorización'
(P/'items.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
