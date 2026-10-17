from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
base=root/'docs/diagramas'
items=json.loads((base/'catalogo.json').read_text(encoding='utf-8'))
for item in items:
    item['code']=(base/'fuentes'/f"{item['slug']}.mmd").read_text(encoding='utf-8')
    item['scope']='Código del piloto / vista documentada'
def add(title,kind,note,source,code,scope='Vista conceptual del código'):
    n=len(items)+1
    item=dict(slug=f'{n:02}-ampliacion',title=title,kind=kind,note=note,source=source,code=code.strip(),scope=scope)
    items.append(item)
    (base/'ampliacion'/f'{n:02}.mmd').write_text(code.strip(),encoding='utf-8')
add('Clases de identidad sintética','UML · Clases','La carga usa muestras sintéticas. No existe validación de INE real habilitada.','apps/mobile/lib/features/identity', '''classDiagram
class IdentityRepository {
<<interface>>
+context()
+begin(requestKey)
+upload(caseId,side)
+submit(caseId)
}
class SupabaseIdentityRepository {
+call(body)
}
class IdentityScreen {
+IdentityRepository repository
}
class IdentityScreenState {
+run(action)
}
IdentityRepository <|.. SupabaseIdentityRepository
IdentityScreen --> IdentityRepository
IdentityScreen *-- IdentityScreenState
IdentityScreenState ..> IdentityRepository
''')
add('Clases de notificaciones','UML · Clases','Las notificaciones usan ReportRepository y mapas JSON; no se inventa una clase de dominio Notification.','notifications_screen.dart; citizen_home.dart; report_repository.dart','''classDiagram
class CitizenHome
class CitizenHomeState {
+refreshUnread()
+notifications()
}
class NotificationsScreen {
+ReportRepository repository
}
class NotificationsScreenState {
+load(page)
+open(item)
}
class ReportRepository {
<<interface>>
+call(action,values)
}
CitizenHome *-- CitizenHomeState
CitizenHomeState ..> NotificationsScreen : abre
NotificationsScreen *-- NotificationsScreenState
NotificationsScreen --> ReportRepository
NotificationsScreenState ..> ReportRepository : notifications_list / read
CitizenHomeState ..> ReportRepository : notifications_count
''')
add('Clases de perfil ciudadano','UML · Clases','Perfil y autenticación comparten repositorio; la identidad no se aprueba desde la edición del perfil.','auth_repository.dart; auth_controller.dart','''classDiagram
class CitizenProfile {
+String id
+String municipalityId
+String firstName
+String lastName
+String identityStatus
+String phone
+fromJson(json)
}
class AuthController {
+CitizenProfile profile
+edit(first,last,phone)
}
class AuthRepository {
<<interface>>
+loadProfile()
+updateProfile(first,last,phone)
}
class SupabaseAuthRepository
AuthController --> CitizenProfile
AuthController --> AuthRepository
AuthRepository <|.. SupabaseAuthRepository
AuthRepository ..> CitizenProfile : devuelve
''')
add('Cliente y servidor: contratos','Arquitectura','Complementa contenedores con los canales usados por cada cliente. JWT acompaña operaciones autenticadas.','apps/mobile; apps/admin/src/lib/api.ts; supabase/functions','''flowchart LR
F[Cliente Flutter] -->|Auth / sesión| A[Supabase Auth]
N[Cliente administrativo] -->|Auth / sesión| A
F -->|HTTPS + JWT| E[Edge report-pilot / identity-pilot]
F -->|RPC perfil y avisos| R[Data API]
N -->|RPC admin_pilot| R
E --> D[(PostgreSQL)]
R --> D
E --> S[(Storage privado)]
N -->|URL firmada autorizada| S
F -->|URL temporal| S
''')
add('Navegación administrativa','Navegación','La interfaz oculta o deshabilita acciones según permisos; la autorización definitiva corresponde al servidor.','apps/admin/src/app/page.tsx','''flowchart TB
L[Login] --> V{Sesión y acceso válido}
V -->|No| L
V -->|Sí| H[Resumen]
H --> R[Reportes y filtros]
H --> M[Mapa: página actual]
H --> G[Métricas]
H --> T[Equipos: consulta]
H --> C[Configuración]
R --> D[Detalle]
M --> D
D --> P[Prioridad / estado / asignación]
P --> A{Permiso y versión vigentes}
A -->|Sí| S[Guardar y recargar]
A -->|No| E[Error / recargar sesión o reporte]
C --> DEP[Crear departamento autorizado]
H --> OUT[Cerrar sesión]
OUT --> L
''')
add('Atención de un reporte por responsable','Actividad · Carriles','Flujo del piloto con carriles conceptuales. No representa atención municipal real ni BPMN formal.','report_wizard.dart; admin_pilot; notifications','''flowchart LR
subgraph Ciudadano
C1[Capturar reporte de prueba] --> C2[Confirmar envío]
C3[Consultar estado y aviso]
end
subgraph Sistema
S1[Validar y guardar] --> S2[Generar folio]
S3[Historial y notificación interna]
end
subgraph Administrador
A1[Revisar] --> A2[Validar y asignar]
end
subgraph Personal_autorizado
O1[En atención] --> O2[Resolver] --> O3[Cerrar]
end
C2 --> S1
S2 --> A1
A2 --> O1
O1 --> S3
O2 --> S3
O3 --> S3
S3 --> C3
''')
add('Paquetes y dependencias','UML · Paquetes','Representación equivalente con agrupaciones Mermaid. Los paquetes reflejan carpetas, no servicios adicionales.','apps; packages/shared; supabase','''flowchart TB
subgraph Flutter
P[presentation] --> AC[auth/application]
AC --> AD[auth/domain]
AI[auth/data] --> AD
RP[features/reports] --> SDK[supabase_flutter]
ID[features/identity] --> SDK
NT[features/notifications] --> RP
P --> CORE[core: tema y configuración]
end
subgraph Nextjs
APP[src/app] --> LIB[src/lib]
LIB --> JS[supabase-js]
end
subgraph Backend
EF[functions] --> SQL[migrations / PostgreSQL]
TEST[tests/database] -. verifica .-> SQL
end
SDK --> EF
JS --> SQL
SQL -. generación .-> TYPES[packages/shared: tipos]
''')
add('Errores y recuperación del envío','Actividad','Reintentar conserva la clave de solicitud y los bytes. La selección manual sigue disponible si el GPS falla.','report_wizard.dart; report-pilot','''flowchart TB
I[Crear reporte] --> G{GPS disponible}
G -->|No| M[Marcar mapa o escribir dirección]
G -->|Sí| P[Revisar marcador]
M --> F[Completar formulario]
P --> F
F --> V{Datos válidos}
V -->|No| F
V -->|Sí| E[Enviar con clave estable]
E --> X{Resultado}
X -->|Sin conexión / tiempo agotado| RET[Mostrar error y ofrecer reintento]
RET --> E
X -->|Sesión inválida| LOGIN[Restablecer acceso antes de continuar]
X -->|Correcto| OK[Folio confirmado]
''')
add('Conflicto entre administradores','UML · Secuencia','El control de versión evita sobrescribir una actualización anterior.','admin_pilot: admin_version','''sequenceDiagram
actor A as Administrador A
actor B as Administrador B
participant D as Base de datos
A->>D: Leer reporte versión n
B->>D: Leer reporte versión n
A->>D: Guardar con versión n
D-->>A: Guardado / versión n+1
B->>D: Guardar con versión n
D-->>B: Conflicto 40001
B->>D: Recargar detalle
D-->>B: Estado vigente
Note over B,D: Revisar antes de volver a guardar
''')
add('Despliegue público propuesto','Despliegue · Propuesta','Solo el atlas está publicado. El alojamiento de las apps, URLs y cuotas deben configurarse y verificarse antes de operar.','Propuesta basada en arquitectura actual','''flowchart TB
U[Navegador ciudadano] -->|HTTPS| F[Hosting estático: Flutter web]
A[Personal autorizado] -->|HTTPS| N[Hosting panel Next.js]
F --> S[Supabase Auth / Data API / Edge]
N --> S
S --> D[(PostgreSQL)]
S --> B[(Storage privado)]
G[Repositorio privado] -. build y pruebas .-> F
G -. build y pruebas .-> N
R[Repositorio público de diagramas] --> P[GitHub Pages: atlas]
CFG[Configurar redirecciones, CORS y cuotas gratis] -. requisito .-> S
''','PROPUESTA · No desplegado')
add('Respaldo y restauración propuestos','Actividad · Propuesta','Procedimiento por implementar y ensayar en un entorno aislado. SQL por sí solo no respalda los archivos de Storage.','Pendientes de entrega / README','''flowchart LR
I[Responsable autorizado] --> S[Inventariar esquema, datos y archivos]
S --> DB[Exportar datos y esquema]
S --> ST[Copiar evidencias autorizadas]
DB --> ENC[Cifrar y restringir acceso]
ST --> ENC
ENC --> V[Verificar integridad y fecha]
V --> R[Restaurar en entorno aislado]
R --> C[Comprobar cuentas, RLS y archivos]
C --> T[Prueba funcional]
T --> OK[Registrar resultado y retención]
''','PROPUESTA · No ejecutado')
add('Objetos: ejemplo de un reporte','UML · Objetos','Instancias totalmente ficticias para explicar vínculos; no son registros exportados ni nuevas clases del programa.','Modelo de datos: profiles / reports / categories','''flowchart LR
P["ciudadanoEjemplo : profiles<br/>id = C-01"] --> R["reporteEjemplo : reports<br/>folio = EJEMPLO-001<br/>is_pilot = true"]
R --> C["serviciosEjemplo : categories<br/>name = Servicios"]
R --> S["recibido : report_statuses<br/>code = RECIBIDO"]
R --> M["cuautlaEjemplo : municipalities<br/>name = Cuautla"]
R --> E["fotoEjemplo : report_images<br/>archivo privado"]
''','EJEMPLO · Datos ficticios')
add('Comunicación al registrar un reporte','UML · Comunicación','Mensajes numerados equivalentes a una vista de comunicación UML; simplificación del flujo reserva/carga/confirmación.','report-pilot; report_repository.dart','''flowchart LR
C[Ciudadano] -->|1. Confirmar| F[ReportWizard]
F -->|2. submit| R[ReportRepository]
R -->|3. HTTPS autenticado| E[report-pilot]
E -->|4. Reservar| D[(PostgreSQL)]
E -->|5. Cargar evidencia| S[(Storage)]
E -->|6. Confirmar transacción| D
D -->|7. Folio| E
E -->|8. Resultado| F
F -->|9. Mostrar confirmación| C
''')
add('Temporización: evidencia privada','UML · Temporización','Vista temporal conceptual: la URL dura 60 segundos desde su emisión. No es una medición de latencia ni significa borrar la fotografía al expirar.','URLs firmadas: report-pilot y panel','''sequenceDiagram
participant C as Cliente
participant A as API autorizada
participant S as Storage privado
C->>A: Solicitar evidencia
A-->>C: URL firmada de 60 segundos
Note over C,S: t0: empieza la vigencia
C->>S: Abrir URL durante vigencia
S-->>C: Imagen
Note over C,S: t0 + 60 s: URL expirada
C->>S: Reutilizar URL expirada
S-->>C: Acceso rechazado
C->>A: Solicitar nueva URL con sesión válida
''')
add('Visión general de interacciones','UML · Interacción global','Relaciona las secuencias detalladas del atlas. Notación equivalente mediante actividad, no diagrama UML normativo.','Diagramas 10, 12, 14, 15 y 16','''flowchart LR
I([Inicio]) --> A[ref: registro y sesión]
A --> R[ref: envío de reporte]
R --> D[ref: revisión administrativa]
D --> N[ref: notificación interna]
N --> C[ref: consulta del detalle]
C --> P{Hay evidencia}
P -->|Sí| F[ref: URL privada de fotografía]
P -->|No| FIN([Fin de consulta])
F --> FIN
''')
add('Estructura compuesta del módulo de reportes','UML · Estructura compuesta','Vista de responsabilidades internas. Puertos conceptuales, no componentes nuevos del código.','features/reports; report-pilot','''flowchart LR
subgraph M[Modulo de reportes]
UI[Interfaz: ReportsScreen / ReportWizard] --> REP[Puerto de datos: ReportRepository]
UI --> MAP[Puerto visual: ReportMap]
UI --> PHOTO[Preparación de fotografía]
REP --> IMP[SupabaseReportRepository]
end
IMP --> API[Edge report-pilot]
MAP --> T[Teselas externas]
PHOTO --> IMP
''')
add('Perfiles UML: convenciones del atlas','UML · Perfil conceptual','Convenciones documentales propuestas; no es un perfil UML ejecutable ni agrega permisos al sistema.','Convenciones de este documento','''classDiagram
class ElementoDocumentado
class Implementado {
<<stereotype>>
+referenciaCodigo
}
class Propuesto {
<<stereotype>>
+requisitoPendiente
}
class Sintetico {
<<stereotype>>
+sinDatosPersonales
}
ElementoDocumentado <|-- Implementado
ElementoDocumentado <|-- Propuesto
ElementoDocumentado <|-- Sintetico
''','CONVENCIÓN · Documental')
tmp=root/'tmp/pdfs'
(tmp/'items.json').write_text(json.dumps(items,ensure_ascii=False,indent=2),encoding='utf-8')
(tmp/'atlas.md').write_text('\n\n'.join('```mermaid\n'+i['code'].strip()+'\n```' for i in items),encoding='utf-8')
config={'theme':'base','themeVariables':{'primaryColor':'#21183e','primaryTextColor':'#f3efff','primaryBorderColor':'#a83dff','lineColor':'#8771b7','secondaryColor':'#152640','tertiaryColor':'#19192e','mainBkg':'#21183e','textColor':'#f3efff','nodeBorder':'#a83dff','clusterBkg':'#11172b','clusterBorder':'#615080','edgeLabelBackground':'#15132b','actorBkg':'#21183e','actorTextColor':'#f3efff','actorBorder':'#a83dff','signalColor':'#b8a6df','signalTextColor':'#f3efff','labelTextColor':'#f3efff','noteBkgColor':'#242345','noteTextColor':'#f3efff','noteBorderColor':'#23c8ed','attributeBackgroundColorOdd':'#21183e','attributeBackgroundColorEven':'#152640','fontFamily':'Arial','fontSize':'18px'},'flowchart':{'htmlLabels':False},'securityLevel':'strict'}
(tmp/'theme.json').write_text(json.dumps(config),encoding='utf-8')
print(f'{len(items)} diagramas preparados')
