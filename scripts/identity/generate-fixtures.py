from PIL import Image, ImageDraw, ImageFont
from pathlib import Path
import hashlib,json
out=Path('apps/mobile/assets/identity')
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',44)
small=ImageFont.truetype('C:/Windows/Fonts/arial.ttf',28)
result={}
for side,label in [('front','FRENTE'),('back','REVERSO')]:
    image=Image.new('RGB',(960,600),'#eef4f1'); d=ImageDraw.Draw(image)
    d.rounded_rectangle((24,24,936,576),radius=24,outline='#12685d',width=8)
    d.rectangle((60,72,900,170),fill='#12685d')
    d.text((85,96),'MUESTRA SINTETICA',font=font,fill='white')
    d.text((80,210),label+' / PRUEBA DE CAPTURA',font=small,fill='#203c35')
    d.text((80,295),'NO ES UNA INE',font=font,fill='#943b30')
    d.text((80,375),'SIN VALIDEZ / SIN DATOS PERSONALES',font=small,fill='#203c35')
    d.text((80,455),'Reporte Ciudadano - Piloto Cuautla',font=small,fill='#203c35')
    path=out/(side+'.png');image.save(path,optimize=True)
    data=path.read_bytes();result[side]={'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'width':960,'height':600}
Path('supabase/functions/identity-pilot/fixtures.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf8')
print(json.dumps(result))
