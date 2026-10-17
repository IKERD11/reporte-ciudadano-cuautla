"""Generate editable Mermaid diagrams and a local, offline HTML atlas.
Run node scripts/diagram-schema.mjs first. Rendering instructions in the atlas README.
"""
from pathlib import Path
import json, html, re

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'docs/diagramas'
schema = json.loads((OUT / 'schema.json').read_text(encoding='utf-8'))
tables = schema['tables']
diagrams = []
def add(slug, title, kind, note, source, code):
    diagrams.append(dict(slug=slug,title=title,kind=kind,note=note,source=source,code=code.strip()))

add('01-contexto','Contexto del sistema','Arquitectura','Vista del piloto implementado; no representa operación municipal real.','apps/mobile/lib; apps/admin/src; supabase/functions', '''flowchart LR
 C[Ciudadano] --> F[App Flutter]
 A[Personal autorizado] --> N[Panel Next.js]
 F --> S[Supabase: Auth, PostgreSQL y Storage]
 N --> S
 F --> L[Ubicación del dispositivo: permiso explícito]
 F --> M[OpenStreetMap: teselas]
 N --> M
 S --> C
 P[INE real, push y publicación: pendientes] -. fuera del piloto .-> S
''')
add('02-contenedores','Contenedores y canales reales','Arquitectura','Las notificaciones son RPC y triggers; no hay FCM ni suscripción Realtime implementada en este flujo.','report_repository.dart; api.ts; supabase/functions', '''flowchart TB
 subgraph Clientes
 F[Flutter]
 N[Next.js / navegador]
 end
 subgraph Supabase
 A[Auth]
 E[Edge report-pilot]
 I[Edge identity-pilot]
 R[Data API / RPC]
 D[(PostgreSQL + PostGIS)]
 S[(Storage privado)]
 P[Edge identity-purge]
 end
 F --> A
 N --> A
 F -->|JWT| E
 F -->|JWT| I
 F -->|citizen_notifications / perfil| R
 N -->|admin_pilot| R
 E -->|service RPC| D
 I -->|service RPC| D
 R --> D
 E --> S
 I --> S
 N -->|URL firmada autorizada| S
 F -->|URL firmada autorizada| S
 P --> D
 P --> S
''')
add('03-componentes-flutter','Componentes de la app ciudadana','Componentes','Nombres de clases y dependencias presentes en el código.','apps/mobile/lib', '''flowchart TB
 Main[main.dart] --> AuthController
 Main --> AuthScreen
 AuthScreen --> WelcomeScreen
 AuthScreen --> CitizenHome
 AuthController --> AuthRepository
 AuthRepository --> SupabaseAuthRepository
 CitizenHome --> ReportsScreen
 CitizenHome --> NotificationsScreen
 CitizenHome --> IdentityScreen[Identidad sintética desde perfil]
 ReportsScreen --> ReportWizard
 ReportWizard --> ReportMap
 ReportsScreen --> PrivateReportImage
 CitizenHome --> PrivateReportImage
 ReportsScreen --> ReportRepository
 NotificationsScreen --> ReportRepository
 ReportWizard --> ReportRepository
 ReportRepository --> SupabaseReportRepository
 IdentityScreen --> IdentityRepository
''')
add('04-componentes-admin','Componentes del panel','Componentes','Arquitectura de módulos; los componentes React no son clases de dominio.','apps/admin/src/app; apps/admin/src/lib/api.ts', '''flowchart LR
 Page[page.tsx] --> Login[Acceso / sesión]
 Page --> Summary[Resumen y métricas]
 Page --> Reports[Reportes y detalle]
 Page --> Teams[Equipos / configuración]
 Page --> Map[report-map.tsx]
 Page --> Controls[modern-controls.tsx]
 Summary --> Charts[metric-charts.tsx]
 Page --> API[api.ts: call]
 API --> RPC[admin_pilot]
 Page -. solo demostración .-> Demo[demo.ts: datos en memoria]
 RPC --> DB[(PostgreSQL)]
''')
add('05-despliegue','Despliegue actual y distribución','Despliegue','Despliegue local documentado; no se afirma que los servidores estén activos ni se dibuja hosting público inexistente.','scripts/serve-mobile.mjs; CONTRIBUTING.md; docs/fase-5-administracion.md', '''flowchart TB
 subgraph Equipo[Equipo de desarrollo]
 Git[Checkout Git]
 Flutter[Flutter SDK / compilación web]
 Web[Servidor local 127.0.0.1:3000]
 Next[Next.js 127.0.0.1:3001]
 Browser[Navegador]
 Git --> Flutter --> Web --> Browser
 Git --> Next --> Browser
 end
 GitHub[GitHub privado / main] -->|clone y pull| Git
 Browser -->|HTTPS| Cloud[Supabase del piloto]
 Browser -->|HTTPS teselas| OSM[OpenStreetMap]
 Git -. alternativa para pruebas .-> Docker[Supabase local con Docker]
 Pending[Hosting público y distribución móvil: pendientes]
''')
add('06-casos-uso','Casos de uso y actores','UML conceptual','Notación de casos de uso aproximada con nodos Mermaid. Las facultades concretas dependen del permiso, municipio y estado.','auth_repository.dart; admin_pilot migration; report_pilot migration', '''flowchart LR
 C[Ciudadano] --> UC1([Registrarse y confirmar correo])
 C --> UC2([Crear reporte de prueba])
 C --> UC3([Consultar reportes y mapa propios])
 C --> UC4([Leer notificaciones propias])
 C --> UC5([Enviar muestras de identidad sintética])
 A[Administrador municipal] --> UA1([Consultar reportes municipales])
 A --> UA2([Asignar departamento o responsable])
 A --> UA3([Actualizar prioridad y estado])
 A --> UA4([Consultar métricas y equipos])
 A --> UA5([Crear departamento con permiso])
 O[Operador / supervisor] --> UO([Atender reportes dentro de su alcance])
 V[Viewer] --> UV([Consulta sin escritura])
 R[Revisor con identity.read y identity.review] --> UR([Revisar muestra sintética])
 UC2 -. requiere .-> AU([Sesión válida y permiso])
 UA2 -. requiere .-> AU
 UO -. requiere .-> AU
''')
add('07-clases-autenticacion','Clases de autenticación Flutter','UML clases','Firmas resumidas; atributos y dependencias reales.','apps/mobile/lib/features/auth/domain/auth_repository.dart; application/auth_controller.dart', '''classDiagram
 class AuthRepository {
 <<interface>>
 +changes Stream~AuthSignal~
 +validateSession()
 +signUp(email,password)
 +signIn(email,password)
 +signOut()
 +loadProfile()
 +completeProfile(municipality,first,last)
 +updateProfile(first,last,phone)
 }
 class SupabaseAuthRepository
 class AuthController {
 +stage AuthStage
 +account Account
 +profile CitizenProfile
 +start()
 +register(email,password)
 +login(email,password)
 +logout()
 +complete(municipality,first,last)
 +edit(first,last,phone)
 }
 class Account {
 +String id
 +String email
 +bool confirmed
 }
 class CitizenProfile {
 +String id
 +String municipalityId
 +String firstName
 +String lastName
 +String identityStatus
 +String phone
 }
 class AuthSignal {
 +Account account
 +bool recovery
 }
 class Municipality {
 +String id
 +String name
 +String state
 }
 AuthRepository <|.. SupabaseAuthRepository
 AuthController --> AuthRepository
 AuthController --> Account
 AuthController --> CitizenProfile
 AuthController --> Municipality
 AuthRepository --> AuthSignal
 AuthSignal --> Account
''')
add('08-clases-reportes','Clases del módulo de reportes','UML clases','Los reportes se transportan como Map JSON; no se inventa una clase Report en Flutter.','apps/mobile/lib/features/reports', '''classDiagram
 class ReportRepository {
 <<abstract>>
 +call(action,values) Future~Map~
 }
 class SupabaseReportRepository {
 +client SupabaseClient
 +call(action,values) Future~Map~
 }
 class ReportsScreen
 class ReportWizard {
 +categories List~Map~
 +repository ReportRepository
 +onCreated callback
 +onCancel callback
 }
 class ReportMap {
 +point LatLng
 +onSelected callback
 +height double
 }
 class PrivateReportImage {
 +reportId String
 +imageId String
 +large bool
 }
 class NotificationsScreen
 ReportRepository <|.. SupabaseReportRepository
 ReportsScreen --> ReportRepository
 ReportsScreen --> ReportWizard
 ReportsScreen --> PrivateReportImage
 ReportWizard --> ReportRepository
 ReportWizard --> ReportMap
 PrivateReportImage --> ReportRepository
 NotificationsScreen --> ReportRepository
 NotificationsScreen --> ReportsScreen : abre detalle
''')
add('09-estados-sesion','Estados de sesión','UML estados','Representación del AuthController; loading también se usa al aceptar cambios de sesión.','apps/mobile/lib/features/auth/application/auth_controller.dart', '''stateDiagram-v2
 [*] --> loading
 loading --> signedOut: sin cuenta
 loading --> confirmation: correo no confirmado
 loading --> profileSetup: falta perfil
 loading --> ready: perfil válido
 loading --> recovery: señal de recuperación
 loading --> unavailable: error al cargar
 signedOut --> confirmation: registro pendiente
 signedOut --> loading: iniciar sesión
 confirmation --> loading: sesión confirmada
 profileSetup --> ready: completar perfil
 ready --> signedOut: cerrar sesión
 ready --> loading: cambio de sesión
 recovery --> signedOut: guardar contraseña y cerrar sesión
 unavailable --> loading: reintentar
''')
add('10-secuencia-registro','Registro y perfil','UML secuencia','No se conceden roles administrativos desde metadatos del registro.','auth_controller.dart; supabase_auth_repository.dart; phase2_auth_profiles.sql', '''sequenceDiagram
 actor C as Ciudadano
 participant UI as Flutter
 participant A as Supabase Auth
 participant DB as RPC de perfil
 C->>UI: Correo y contraseña
 UI->>A: signUp
 A-->>C: Confirmación de correo
 A-->>UI: Cuenta / sesión según confirmación
 C->>A: Confirmar correo
 UI->>A: Validar sesión
 UI->>DB: Cargar perfil
 alt Sin perfil
 DB-->>UI: Municipios habilitados
 C->>UI: Completar nombre y municipio
 UI->>DB: RPC de alta de perfil
 DB->>DB: Validar sesión y asignar CITIZEN
 end
 DB-->>UI: Perfil autorizado
 UI-->>C: Inicio ciudadano
''')
add('11-actividad-crear','Actividad: crear reporte','UML actividad','Dirección de diez caracteres o punto geográfico cuando la categoría exige ubicación; máximo tres fotos en el piloto.','report_wizard.dart; report_address_location.sql', '''flowchart TD
 A([Inicio]) --> B[Seleccionar categoría]
 B --> C[Escribir dirección / GPS / tocar mapa]
 C --> D{Ubicación requerida satisfecha}
 D -->|No| C
 D -->|Sí| E[Descripción, campos dinámicos y fotos]
 E --> F{Datos y evidencia válidos}
 F -->|No| E
 F -->|Sí| G[Revisar y aceptar reporte de prueba]
 G --> H[Enviar con clave idempotente]
 H --> I{Servidor acepta}
 I -->|No| J[Mostrar error / reintentar sin cambiar datos]
 J --> H
 I -->|Sí| K[Folio y detalle]
 K --> L([Fin])
''')
add('12-secuencia-envio','Envío de reporte y evidencia','UML secuencia','Reserva y commit son transacciones separadas; Storage no comparte transacción SQL. La reserva permite reintentos y purga de cargas incompletas.','supabase/functions/report-pilot/index.ts; phase4_report_list_alias.sql', '''sequenceDiagram
 actor C as Ciudadano
 participant F as Flutter
 participant E as Edge report-pilot
 participant A as Auth
 participant DB as report_pilot_service
 participant S as Storage privado
 C->>F: Confirmar envío
 F->>E: JWT, request_key, payload, fotos
 E->>A: getUser(token)
 A-->>E: Usuario validado
 E->>DB: context con actor y session_id
 DB->>DB: Sesión, municipio y habilitación
 E->>E: Normalizar fotos y calcular hash
 E->>DB: reserve(payload)
 DB->>DB: Validar permiso, datos, cuota e idempotencia
 DB-->>E: Ticket y rutas
 alt Ticket ya confirmado
 E-->>F: Mismo reporte y folio
 else Carga pendiente
 loop Cada foto
 E->>S: upload sin sobrescribir
 end
 E->>DB: commit con el mismo payload
 DB->>DB: Verificar objetos y crear reporte, imágenes e historial
 DB->>DB: Trigger de notificación
 DB-->>E: id y folio
 E-->>F: Confirmación
 end
 F-->>C: Reporte registrado
''')
add('13-estados-reporte','Máquina de estados del reporte','UML estados','Transiciones reales de admin_pilot; VALIDADO avanza mediante asignación, no mediante el selector de estado.','20260926004537_phase5_admin_pilot.sql; apps/admin/src/lib/api.ts', '''stateDiagram-v2
 [*] --> RECIBIDO
 RECIBIDO --> EN_REVISION
 RECIBIDO --> RECHAZADO
 RECIBIDO --> DUPLICADO
 EN_REVISION --> VALIDADO
 EN_REVISION --> RECHAZADO
 EN_REVISION --> DUPLICADO
 VALIDADO --> ASIGNADO: asignar departamento
 ASIGNADO --> EN_ATENCION
 EN_ATENCION --> RESUELTO
 RESUELTO --> EN_ATENCION: reabrir atención
 RESUELTO --> CERRADO
 CERRADO --> [*]
 RECHAZADO --> [*]
 DUPLICADO --> [*]
''')
add('14-secuencia-admin','Actualización administrativa y concurrencia','UML secuencia','El backend compara admin_version y bloquea cambios sobre estados terminales.','20260926004537_phase5_admin_pilot.sql', '''sequenceDiagram
 actor O as Personal autorizado
 participant P as Panel
 participant R as admin_pilot
 participant DB as PostgreSQL
 O->>P: Abrir detalle
 P->>R: detail con id
 R-->>P: Reporte y admin_version
 O->>P: Cambiar estado, prioridad o asignación
 P->>R: Acción, id y versión leída
 R->>DB: Validar sesión, permiso, municipio y alcance
 R->>DB: Bloquear reporte y comparar versión
 alt Versión distinta
 R-->>P: 40001 - recargar
 else Cambio autorizado
 R->>DB: Mutación y aumento de versión
 DB->>DB: Historial / auditoría según acción
 DB->>DB: Aviso si cambia estado o asignación
 R-->>P: saved true
 end
''')
add('15-secuencia-notificaciones','Notificaciones internas','UML secuencia','No existe envío push; la bandeja se actualiza mediante RPC. La prioridad por sí sola no genera aviso.','phase6_notifications.sql; notifications_screen.dart; citizen_home.dart', '''sequenceDiagram
 participant B as Operación de reporte
 participant T as Trigger PostgreSQL
 participant N as notifications
 participant F as Flutter
 participant R as citizen_notifications
 B->>T: Inserción / cambio de estado / asignación
 T->>T: Solo piloto, evitar doble aviso inicial de asignación
 T->>N: Insertar aviso al ciudadano propietario
 F->>R: count o list con JWT
 R->>R: Validar sesión, perfil y municipio
 R->>N: Consultar solo destinatario actual
 N-->>F: Contador y hasta 20 avisos
 F->>R: read(id)
 R->>N: read_at = coalesce(read_at,now)
 R-->>F: Confirmación idempotente
''')
add('16-secuencia-foto','Acceso privado a fotografías','UML secuencia','Flujo ciudadano. El panel también solicita acceso firmado, por su propia ruta autorizada.','report-pilot/index.ts; reports_screen.dart', '''sequenceDiagram
 participant UI as PrivateReportImage
 participant E as report-pilot
 participant R as report_pilot_service
 participant S as Storage
 UI->>E: image(report_id,image_id) + JWT
 E->>E: Validar token con Auth
 E->>R: Validar propietario y municipio
 R-->>E: storage_path autorizado
 E->>S: createSignedUrl(path,60)
 S-->>E: URL temporal
 E-->>UI: URL
 UI->>S: Descargar foto
 alt Error o enlace vencido
 UI->>UI: Mostrar opción de renovar
 end
''')
add('17-identidad-sintetica','Estados de identidad sintética','UML estados','Aprobar la simulación NO marca VERIFIED al perfil. VERIFIED y EXPIRED existen en el enum, pero no son resultados de este piloto.','20260924170343_phase3_synthetic_identity.sql', '''stateDiagram-v2
 [*] --> PENDING: consentimiento synthetic-v1
 PENDING --> DOCUMENT_CAPTURED: ambos lados cargados
 DOCUMENT_CAPTURED --> PROCESSING: submit
 PROCESSING --> UNDER_REVIEW: sin OCR real
 UNDER_REVIEW --> UNDER_REVIEW: approve_demo / simulation_approved
 UNDER_REVIEW --> REJECTED: revisión rechazada
 note right of UNDER_REVIEW
   No verifica la identidad del perfil.
   Solo muestras sintéticas permitidas.
 end note
''')
add('18-purga','Purga programada de archivos','Actividad / mantenimiento','La migración programa cada 15 minutos; no se consultó el estado actual del cron remoto. No borra automáticamente evidencia de reportes confirmados.','identity-purge/index.ts; phase3_purge_schedule.sql; phase4_pilot_reports.sql', '''flowchart TD
 C[pg_cron: cada 15 minutos] --> V[Leer token de Vault]
 V --> H[pg_net POST identity-purge]
 H --> A{Token autorizado}
 A -->|No| X[401 / sin modificación]
 A -->|Sí| I[Consultar muestras vencidas]
 I --> D[Borrar objetos de identity-documents]
 D --> F{Storage confirma}
 F -->|Sí| M[Marcar documentos purgados]
 F -->|No| R[Registrar fallo para reintento]
 M --> U[Consultar reservas de reportes vencidas sin commit]
 U --> E[Borrar cargas huérfanas de report-evidence]
 E --> P[Marcar reservas purgadas tras éxito]
 P --> O[Responder contadores de éxito y fallos]
 R --> O
''')
add('19-autorizacion','Decisión de autorización','Seguridad / flujo','Diagrama conceptual de controles combinados; cada RPC realiza los controles específicos de su operación.','phase1_security.sql; phase4_pilot_reports.sql; phase5_admin_pilot.sql; phase6_notifications.sql', '''flowchart TD
 A[Solicitud con JWT] --> B{Usuario y sesión válidos}
 B -->|No| X[Denegar]
 B -->|Sí| C{Perfil y municipio activos}
 C -->|No| X
 C -->|Sí| D{Permiso requerido}
 D -->|No| X
 D -->|Sí| E{Alcance autorizado}
 E -->|Propietario / asignado / municipio o global autorizado| F{Datos y estado válidos}
 E -->|Fuera de alcance| X
 F -->|No| Y[Rechazar datos o conflicto]
 F -->|Sí| G[Ejecutar operación]
 G --> H[Historial / auditoría / notificación según acción]
''')
add('20-navegacion','Navegación ciudadana','Mapa de pantallas','Vista funcional; no representa cada control ni cada ruta técnica.','auth_screen.dart; citizen_home.dart; reports_screen.dart', '''flowchart LR
 W[Bienvenida] --> L[Iniciar sesión]
 W --> R[Registro]
 R --> C[Confirmar correo]
 C --> P[Completar perfil]
 L --> H[Inicio]
 P --> H
 L --> Reset[Recuperar contraseña]
 H --> Reports[Mis reportes]
 H --> Create[Crear reporte]
 H --> Map[Mapa propio]
 H --> Profile[Perfil]
 H --> N[Notificaciones]
 Create --> Type[Tipo] --> Location[Ubicación] --> Details[Detalles] --> Confirm[Confirmación]
 Confirm --> Reports
 Reports --> Detail[Detalle de reporte]
 N --> Detail
 Map --> Preview[Tarjeta: foto, folio, estado y descripción]
 Profile --> Identity[Pruebas sintéticas de identidad]
 Drawer[Menú lateral opcional] --> H
 Bottom[Menú inferior] --> H
''')
add('21-ubicacion','Selección de ubicación','Actividad','GPS real pendiente de validar en el navegador del usuario. Una dirección escrita no se geocodifica automáticamente.','report_wizard.dart; report_map.dart; report_address_location.sql', '''flowchart TD
 A[Entrar a ubicación] --> B[Mapa visible centrado en Cuautla sin punto enviado]
 B --> C{Elección del ciudadano}
 C -->|Dirección| D[Guardar texto de dirección]
 C -->|Tocar mapa| E[Seleccionar punto]
 C -->|Usar ubicación| F[Solicitar ubicación con precisión media]
 F --> G{Respuesta antes de 20 segundos}
 G -->|Sí| E
 G -->|No o permiso denegado| H[Mostrar error sin bloquear formulario]
 H --> C
 E --> I[Mostrar marcador y precisión si proviene de GPS]
 I --> J[Verificar o ajustar punto]
 D --> K{Requisito de ubicación satisfecho}
 J --> K
 K -->|Punto o dirección de al menos 10 caracteres| L[Continuar]
 K -->|No| C
''')
add('22-flujo-datos','Flujo de datos de nivel 1','DFD conceptual','No es una topología de red; separa procesos y almacenes. Las flechas no conceden acceso directo a tablas.','supabase/functions; supabase/migrations', '''flowchart LR
 C[Ciudadano] --> P1[1 Autenticación y perfil]
 P1 <--> D1[(Auth y perfiles)]
 C --> P2[2 Captura de reporte]
 P2 --> D2[(Reportes, imágenes e historial)]
 P2 --> D3[(Objetos privados)]
 A[Personal autorizado] --> P3[3 Gestión y asignación]
 P3 <--> D2
 P3 --> D4[(Auditoría)]
 D2 --> P4[4 Generar avisos]
 P4 --> D5[(Notificaciones)]
 D5 --> P5[5 Consultar avisos propios]
 P5 --> C
 C --> P6[6 Identidad sintética]
 P6 --> D6[(Consentimientos y verificaciones)]
 P6 --> D3
''')
add('23-limites-confianza','Límites de confianza','Seguridad / arquitectura','No contiene secretos. RLS y validaciones de funciones cumplen papeles distintos; service_role exige comprobaciones explícitas de servidor.','supabase/functions; docs/seguridad.md', '''flowchart TB
 subgraph U[Cliente no confiable]
 UI[Flutter / panel]
 Data[Datos, IDs y versión enviados]
 UI --> Data
 end
 subgraph G[Entrada validada]
 Auth[Auth valida JWT]
 Edge[Edge valida método, origen, tamaño y contenido]
 RPC[RPC valida sesión y permisos]
 end
 subgraph DB[Persistencia protegida]
 RLS[RLS + concesiones SQL]
 FK[FK compuestas con municipio]
 Tables[(Tablas de aplicación)]
 Storage[(Buckets privados)]
 end
 Data --> Auth --> Edge --> RPC
 Data -->|RPC con JWT| RPC
 RPC --> RLS --> Tables
 RPC --> FK --> Tables
 Edge -->|solo tras autorización| Storage
''')
add('24-colaboracion','Colaboración y validación','Proceso de desarrollo','Flujo recomendado para colaboradores; CI es una plantilla manual, no una automatización activa.','CONTRIBUTING.md; docs/ci/database-workflow.yml', '''flowchart LR
 R[Repositorio privado main] --> B[Crear rama]
 B --> C[Configurar entorno local con plantillas]
 C --> D[Desarrollar cambio]
 D --> F[Flutter analyze y test]
 D --> N[Typecheck y build del panel]
 D --> S[SQL syntax y pgTAP local]
 F --> PR[Pull request]
 N --> PR
 S --> PR
 PR --> Review[Revisión por colaboradores]
 Review --> Merge[Integración autorizada]
 Merge --> R
 CI[Plantilla CI manual / no activa] -. opcional con permisos y cuota .-> Review
''')

def ident(s): return s.replace('.','_')
def er(selected, all_columns=True):
    lines=['erDiagram']
    for name in selected:
        t=tables.get(name)
        if not t:
            lines += [f'  {ident(name)} {{', '    uuid id PK', '  }']; continue
        lines.append(f'  {ident(name)} {{')
        for c in t['columns']:
            keys=[]
            if c['name'] in t['primary']: keys.append('PK')
            if any(c['name'] in f['columns'] for f in t['foreign']): keys.append('FK')
            if [c['name']] in t['unique']: keys.append('UK')
            if not all_columns and not keys: continue
            typ=c['type'].replace('.','_')
            lines.append(f'    {typ} {c["name"]}'+(' '+', '.join(keys) if keys else '')+f' "{"nullable" if c["nullable"] else "required"}"')
        lines.append('  }')
    for name in selected:
        t=tables.get(name)
        if not t: continue
        for fk in t['foreign']:
            if fk['target'] not in selected: continue
            optional=any(c['nullable'] for c in t['columns'] if c['name'] in fk['columns'])
            # Child uniqueness only from complete PK/UNIQUE constraints, not partial indexes.
            one=any(set(u).issubset(fk['columns']) for u in [t['primary']]+t['unique'] if u)
            parent='|o' if optional else '||'
            child='o|' if one else 'o{'
            lines.append(f'  {ident(fk["target"])} {parent}--{child} {ident(name)} : "{", ".join(fk["columns"])}"')
    return '\n'.join(lines)

all_names=['auth.users']+list(tables)
add('25-er-general','Modelo entidad-relación general','Base de datos','Vista de claves. Relaciones físicas FK; no dibuja como FK las rutas de Storage ni IDs polimórficos. Las FK compuestas se muestran como una sola relación.','Todas las migraciones; schema.json',er(all_names,False))
groups=[('26-er-acceso','Identidad de usuario y permisos',['auth.users','public.municipalities','public.profiles','public.roles','public.permissions','public.role_permissions','public.user_roles']),('27-er-catalogos','Catálogos y configuración',['public.municipalities','public.priorities','public.categories','public.subcategories','public.departments','public.zones','public.settings','public.sla_rules']),('28-er-reportes','Reportes y seguimiento',['public.municipalities','public.profiles','public.categories','public.subcategories','public.priorities','public.report_statuses','public.zones','public.reports','public.report_images','public.report_status_history','public.report_assignments','public.departments','public.report_comments']),('29-er-identidad','Verificación sintética y consentimiento',['public.municipalities','public.profiles','public.consents','public.identity_verifications','private.identity_documents']),('30-er-avisos','Avisos, auditoría y reservas',['public.municipalities','public.profiles','public.reports','public.notifications','public.audit_logs','private.report_uploads'])]
for slug,title,n in groups:
    add(slug,title,'Base de datos','Columnas completas de las tablas seleccionadas. PK/FK son participaciones de columnas en claves; ver schema.json para claves compuestas y diccionario para restricciones.','Todas las migraciones; schema.json',er(n))
for i,(name,t) in enumerate(tables.items(),31):
    add(f'{i:02}-tabla-{name.replace(".","-")}',name,'Tabla individual','Ficha de columnas completa. Para relaciones, consultar los diagramas ER por área y el diccionario.','supabase/migrations/'+t['source'],er([name]))

OUT.mkdir(exist_ok=True)
(OUT/'fuentes').mkdir(exist_ok=True)
for d in diagrams: (OUT/'fuentes'/f'{d["slug"]}.mmd').write_text(d['code']+'\n',encoding='utf-8')
(OUT/'catalogo.json').write_text(json.dumps([{k:v for k,v in d.items() if k!='code'} for d in diagrams],ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
intro='''# Atlas de diagramas — Reporte Ciudadano

Fecha de documentación: 6 de octubre de 2026. Fuente: código y migraciones del checkout local. No es una inspección del estado remoto de Supabase.

Piloto de Cuautla, Morelos, sin atención municipal real y con identidad exclusivamente sintética. Los diagramas conceptuales simplifican la implementación; los diagramas ER y el diccionario se extraen del SQL. Las tablas auth/storage/cron/vault son administradas por Supabase y no se detallan como si pertenecieran al esquema propio.

No se presentan como implementados OCR real, FCM, Realtime, geocodificación de direcciones, SLA operativo ni hosting público. Existen tablas para algunas capacidades futuras, lo que no implica que sus pantallas y procesos estén completos.

## Entregables

- `index.html`: visor local sin CDN, con búsqueda, filtros, zoom y descarga SVG. Abrir después de generar los SVG.
- `atlas.md`: todos los diagramas editables en bloques Mermaid, visibles también en GitHub.
- `fuentes/`: un archivo Mermaid por diagrama.
- `svg/`: figuras vectoriales para documentos, presentaciones e impresión.
- `diccionario.md` y `schema.json`: 25 tablas de aplicación, columnas, claves y nulabilidad. No contienen registros de usuarios.

## Regeneración

Desde la raíz: `node scripts/diagram-schema.mjs` y `python scripts/generate-diagrams.py`. El extractor procesa CREATE TABLE y ALTER TABLE ADD COLUMN/ADD CONSTRAINT de las migraciones actuales; no ejecuta SQL ni reconstruye cambios dinámicos futuros. Los índices parciales, CHECK, valores por defecto y lógica de triggers permanecen en las migraciones originales. Revisar el extractor al introducir otros tipos de ALTER.

Renderizar con Mermaid CLI 12.0.0 usando `atlas.md` como entrada y `svg/atlas.svg` como salida; produce `atlas-1.svg`, `atlas-2.svg`, etc. Mantener el orden del catálogo. La CLI puede utilizar un navegador local mediante configuración Puppeteer. No requiere API ni servicio de pago. Las tablas muy grandes se consultan mejor en SVG con zoom o en las fichas individuales.

Los diagramas de actividad, casos de uso, componentes y despliegue emplean notación Mermaid equivalente y no afirman conformidad gráfica estricta con todas las notaciones UML 2.x. Clases, secuencias y estados usan sus tipos Mermaid específicos.

## Índice
'''
index='\n'.join(f'- [{d["slug"]} · {d["title"]}](fuentes/{d["slug"]}.mmd) · [SVG](svg/atlas-{i}.svg)' for i,d in enumerate(diagrams,1))
(OUT/'README.md').write_text(intro+index+'\n',encoding='utf-8')
(OUT/'atlas.md').write_text('# Diagramas del piloto de Cuautla\n\n'+ '\n\n'.join(f'## {i}. {d["title"]}\n\n{d["note"]}\n\nFuente: `{d["source"]}`.\n\n```mermaid\n{d["code"]}\n```' for i,d in enumerate(diagrams,1))+'\n',encoding='utf-8')
dictionary=['# Diccionario estructural de tablas\n\nExtraído del SQL, no de datos remotos. PK y UK compuestas se listan completas. Las columnas espaciales usan SRID 4326; reports.location es Point y zones.boundary es MultiPolygon. CHECK, DEFAULT e índices: consultar migraciones originales.']
for name,t in tables.items():
    dictionary += [f'\n## {name}\n',f'Creada en `{t["source"]}`; incluye columnas añadidas por migraciones posteriores.','\n| Columna | Tipo SQL | Admite NULL |\n|---|---|---|']
    dictionary += [f'| `{c["name"]}` | `{c["type"]}` | {"Sí" if c["nullable"] else "No"} |' for c in t['columns']]
    dictionary += ['\nPK: `'+', '.join(t['primary'])+'`.']
    dictionary += ['\nUNIQUE: `'+', '.join(u)+'`.' for u in t['unique']]
    dictionary += [f'\nFK: `({", ".join(f["columns"])})` → `{f["target"]}({", ".join(f["references"])})`.' for f in t['foreign']]
(OUT/'diccionario.md').write_text('\n'.join(dictionary)+'\n',encoding='utf-8')
data=json.dumps([{**{k:v for k,v in d.items() if k!='code'},'svg':f'svg/atlas-{i}.svg'} for i,d in enumerate(diagrams,1)],ensure_ascii=False).replace('</','<\\/')
page='''<!doctype html><html lang="es"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Atlas técnico · Reporte Ciudadano</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f5f6fa;color:#192138;font:15px system-ui}header{background:#101830;color:white;padding:26px 32px}header small{color:#bfc9de}h1{font-size:25px;margin:7px 0}main{display:grid;grid-template-columns:300px 1fr;height:calc(100vh - 145px)}aside{background:white;padding:18px;overflow:auto;border-right:1px solid #dce0e8}input,select{width:100%;padding:10px;margin-bottom:10px;border:1px solid #cbd0dd;border-radius:8px}nav button{display:block;border:0;background:none;text-align:left;width:100%;padding:10px;color:#39415a;cursor:pointer;border-radius:8px}nav button.active{background:#eee8fa;color:#5a259a;font-weight:700}article{padding:24px;overflow:auto}h2{font-size:21px;margin:0 0 10px}p{line-height:1.5;color:#536078}.toolbar{display:flex;gap:10px;flex-wrap:wrap;margin:15px 0}a,button{color:#593293}.toolbar a,.toolbar button{background:white;border:1px solid #cbd0dd;border-radius:7px;padding:9px;text-decoration:none;font:inherit;cursor:pointer}.figure{background:white;overflow:auto;border:1px solid #dce0e8;border-radius:12px;min-height:380px;padding:20px}.figure img{width:100%;max-width:none;display:block;min-height:200px}footer{font-size:12px;margin-top:14px;color:#647087}@media(max-width:750px){main{display:block;height:auto}aside{max-height:270px}article{padding:16px}}@media print{aside,.toolbar,header{display:none}main{display:block;height:auto}article{overflow:visible}.figure{overflow:visible;border:0}}
</style><header><small>CUAUTLA, MORELOS · DOCUMENTACIÓN DEL PILOTO · 06 OCT 2026</small><h1>Atlas técnico · Reporte Ciudadano</h1><small>55 diagramas · UML, arquitectura, flujos y 25 tablas · Fuentes editables</small></header>
<main><aside><input id="search" placeholder="Buscar diagrama…" aria-label="Buscar"><select id="kind" aria-label="Tipo"><option value="">Todos los tipos</option></select><nav id="nav"></nav></aside><article><h2 id="title"></h2><p id="note"></p><div class="toolbar"><button id="minus" aria-label="Reducir">−</button><button id="plus" aria-label="Ampliar">+</button><button id="fit">Ajustar</button><a id="svg" download>Descargar SVG</a><a id="source">Fuente Mermaid</a><a href="diccionario.md">Diccionario</a><button onclick="print()">Imprimir</button></div><div class="figure"><img id="diagram" alt=""></div><footer id="origin"></footer></article></main>
<script>const data=__DATA__;let active=0,zoom=100;const $=id=>document.getElementById(id);for(const k of [...new Set(data.map(d=>d.kind))]){let o=document.createElement('option');o.value=o.textContent=k;$('kind').append(o)}
function menu(){ $('nav').replaceChildren();data.forEach((d,i)=>{if((d.title+' '+d.kind+' '+d.slug).toLowerCase().includes($('search').value.toLowerCase())&&(!$('kind').value||d.kind===$('kind').value)){let b=document.createElement('button');b.textContent=d.slug.split('-')[0]+' · '+d.title;b.className=i===active?'active':'';b.onclick=()=>show(i);$('nav').append(b)}})}
function show(i){active=i;zoom=100;let d=data[i];$('title').textContent=d.title;$('note').textContent=d.note;$('origin').textContent='Fuente: '+d.source;$('diagram').src=d.svg;$('diagram').alt=d.title;$('diagram').style.width='100%';$('svg').href=d.svg;$('source').href='fuentes/'+d.slug+'.mmd';location.hash=d.slug;menu()}
$('search').oninput=menu;$('kind').onchange=menu;$('plus').onclick=()=>{$('diagram').style.width=(zoom=Math.min(500,zoom+25))+'%'};$('minus').onclick=()=>{$('diagram').style.width=(zoom=Math.max(25,zoom-25))+'%'};$('fit').onclick=()=>{$('diagram').style.width='100%';zoom=100};show(Math.max(0,data.findIndex(d=>d.slug===location.hash.slice(1))));</script></html>'''
(OUT/'index.html').write_text(page.replace('__DATA__',data),encoding='utf-8')
print(f'{len(diagrams)} diagramas generados; {len(tables)} fichas de tabla.')
