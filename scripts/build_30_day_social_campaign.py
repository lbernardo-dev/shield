#!/usr/bin/env python3
"""Build MaskID's bilingual 30-day social campaign from real simulator captures."""

from __future__ import annotations

import csv
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "Marketing" / "30-Day-Social-Campaign"
CAPTURES = ROOT / ".asc" / "screenshots" / "aso" / "final"
W, H = 1080, 1350
NAVY, SURFACE, CYAN, WHITE, MUTED = "#071426", "#0E2038", "#20C7D9", "#F7F7FA", "#B8C2D1"
FONTS = ["/System/Library/Fonts/SFNS.ttf", "/System/Library/Fonts/Supplemental/Arial.ttf"]
PLATFORMS = ["instagram", "linkedin", "x", "facebook", "tiktok"]


def fnt(size: int):
    for path in FONTS:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def wrap(draw, text, font, width):
    lines, line = [], ""
    for word in text.split():
        candidate = f"{line} {word}".strip()
        if draw.textbbox((0, 0), candidate, font=font)[2] <= width:
            line = candidate
        else:
            lines.append(line)
            line = word
    if line:
        lines.append(line)
    return lines


# day, scene, format, pillar, ES hook, EN hook, ES facts, EN facts, ES CTA, EN CTA
TOPICS = [
 (1,"home","image","awareness","Comparte el documento. No toda tu identidad.","Share the document. Not your whole identity.",["Revisa antes de compartir","Oculta solo lo necesario","Exporta una copia separada"],["Review before sharing","Hide only what is needed","Export a separate copy"],"Guárdalo para tu próximo trámite.","Save this for your next document request."),
 (2,"capture","carousel","education","Tres formas de empezar sin cambiar tu flujo","Three ways to start without changing your workflow",["Escanea con la cámara","Importa desde Fotos","Elige PDF o archivo"],["Scan with the camera","Import from Photos","Choose a PDF or file"],"¿Cómo recibes normalmente tus documentos?", "How do you usually receive documents?"),
 (3,"editor","infographic","education","No todo dato sensible necesita el mismo recorte","Not every sensitive detail needs the same crop",["Marca direcciones","Cubre firmas","Protege números y retratos"],["Mark addresses","Cover signatures","Protect numbers and portraits"],"Revisa cada zona antes de exportar.","Review every region before export."),
 (4,"ocr","carousel","trust","El OCR ayuda. Tú decides.","OCR assists. You decide.",["El análisis ocurre en el dispositivo","Las sugerencias son conservadoras","Cada selección requiere revisión"],["Analysis runs on device","Suggestions are conservative","Every selection needs review"],"La automatización no sustituye tu revisión.","Automation does not replace your review."),
 (5,"export","image","trust","Una caja negra no basta","A black box is not enough",["La copia se rasteriza","Se comprueba texto recuperable","Solo se llama verificada si supera la comprobación"],["The copy is rasterized","Recoverable text is checked","It is called verified only after passing"],"Comparte la copia exportada, no el original.","Share the exported copy, not the original."),
 (6,"settings","infographic","privacy","Privacidad sin perfil publicitario","Privacy without an advertising profile",["Sin backend de anuncios","Sin seguimiento del usuario","Procesamiento local del documento"],["No advertising backend","No user tracking","Local document processing"],"La privacidad también es lo que una app no recopila.","Privacy is also what an app does not collect."),
 (7,"vault","image","trust","Lo privado merece una segunda puerta","Private files deserve a second door",["Bóveda cifrada localmente","Clave separada del dispositivo","Acceso con autenticación o PIN"],["Locally encrypted Vault","Separate device-only key","Authentication or PIN access"],"Protege el acceso, además del contenido.","Protect access as well as content."),
 (8,"gallery","carousel","product","Un documento, distintas necesidades de máscara","One document, different masking needs",["Negro o blanco","Etiqueta o pixelado","Estilos avanzados en Pro"],["Black or white","Label or pixelation","Advanced styles in Pro"],"Elige claridad sin perder el control.","Choose clarity without losing control."),
 (9,"home","infographic","education","Antes de enviar un documento: lista de 30 segundos","Before sending a document: a 30-second checklist",["¿Quién lo pide?","¿Qué campos necesita?","¿Qué información sobra?"],["Who is requesting it?","Which fields do they need?","What information is unnecessary?"],"Menos datos compartidos, menos exposición innecesaria.","Less data shared means less unnecessary exposure."),
 (10,"capture","image","product","Tu archivo entra por el selector que ya conoces","Your file enters through the picker you already know",["Fotos y Archivos","PDF y escáner","Proveedores mediante Archivos de Apple"],["Photos and Files","PDF and scanner","Providers through Apple Files"],"MaskID solo recibe el archivo que eliges.","MaskID receives only the file you choose."),
 (11,"editor","carousel","education","Qué ocultar en una copia de DNI","What to hide in an ID copy",["Dirección si no es necesaria","Firma y número de soporte","Retrato cuando el trámite lo permita"],["Address when unnecessary","Signature and support number","Portrait when the request allows it"],"Confirma siempre los requisitos del receptor.","Always confirm the recipient's requirements."),
 (12,"ocr","image","trust","En el dispositivo significa aquí, no en una nube de análisis","On device means here, not in an analysis cloud",["OCR local","Enmascarado local","Exportación local"],["Local OCR","Local masking","Local export"],"Tus documentos no necesitan viajar para ser revisados.","Your documents do not need to travel to be reviewed."),
 (13,"export","carousel","education","Negro visible no siempre significa seguro","Visible black does not always mean secure",["Una capa puede ocultar sin eliminar","MaskID rasteriza la copia","El verificador busca texto recuperable"],["An overlay can hide without removing","MaskID rasterizes the copy","The verifier checks recoverable text"],"Verifica antes de compartir.","Verify before sharing."),
 (14,"batch","image","product","Cuando los documentos se repiten, también puede hacerlo el flujo","When documents repeat, the workflow can too",["Procesamiento por lotes en Pro","Flujos semánticos reutilizables","Revisión final obligatoria"],["Batch processing in Pro","Reusable semantic workflows","Final review still required"],"Ahorra pasos, no la revisión.","Save steps, not the review."),
 (15,"settings","infographic","privacy","Qué se sincroniza y qué se queda local","What syncs and what stays local",["El contenido del documento queda local","Los títulos introducidos quedan locales","El índice iCloud minimizado es opcional"],["Document content stays local","User-entered titles stay local","Minimized iCloud index is optional"],"Tú decides si activar la sincronización.","You decide whether to enable sync."),
 (16,"vault","carousel","education","Bóveda no significa copia de seguridad en la nube","Vault does not mean cloud backup",["Protección local cifrada","Acceso protegido","Gestiona tus copias por separado"],["Encrypted local protection","Protected access","Manage backups separately"],"Conoce dónde vive cada archivo.","Know where every file lives."),
 (17,"gallery","image","product","Una etiqueta puede explicar por qué falta un dato","A label can explain why a detail is missing",["Máscaras visuales configurables","Estilos para distintos contextos","Controles avanzados en Pro"],["Configurable visual masks","Styles for different contexts","Advanced controls in Pro"],"Haz legible la intención de la copia.","Make the purpose of the copy easy to understand."),
 (18,"home","carousel","use-case","Alquiler: comparte lo necesario, revisa lo demás","Renting: share what is needed, review the rest",["Confirma los documentos solicitados","Oculta campos no requeridos","Conserva el original fuera del envío"],["Confirm requested documents","Hide fields that are not required","Keep the original out of the send flow"],"Pregunta qué datos son imprescindibles.","Ask which details are truly required."),
 (19,"editor","infographic","use-case","CV y contratos también contienen identidad","CVs and contracts also contain identity",["Direcciones personales","Firmas","Teléfonos y números internos"],["Home addresses","Signatures","Phone numbers and internal IDs"],"Revisa el documento completo, no solo la primera página.","Review the full document, not only page one."),
 (20,"capture","carousel","use-case","Antes de subir un extracto bancario","Before uploading a bank statement",["Comprueba el periodo solicitado","Revisa IBAN y movimientos","Oculta información ajena al trámite"],["Check the requested period","Review IBAN and transactions","Hide information unrelated to the request"],"No ocultes datos que el trámite sí exige.","Do not hide details the process requires."),
 (21,"export","image","trust","El original no se convierte en tu copia para compartir","Your original does not become the copy you share",["Edita una representación de trabajo","Exporta una copia rasterizada","Mantén separado el original"],["Edit a working representation","Export a rasterized copy","Keep the original separate"],"Trabaja con copias y verifica el resultado.","Work with copies and verify the result."),
 (22,"settings","carousel","privacy","Archivos cloud sin entregar tus credenciales a MaskID","Cloud files without handing credentials to MaskID",["Acceso mediante el selector Archivos","Solo eliges el archivo necesario","MaskID no guarda tokens OAuth del proveedor"],["Access through the Files picker","You choose only the needed file","MaskID stores no provider OAuth tokens"],"Tu proveedor sigue gestionado por el sistema.","Your provider remains managed by the system."),
 (23,"ocr","infographic","education","Tres límites honestos del OCR","Three honest limits of OCR",["Puede omitir un dato","Puede sugerir de más","El contexto requiere criterio humano"],["It may miss a detail","It may suggest too much","Context requires human judgment"],"Amplía, revisa y corrige antes de exportar.","Zoom, review and correct before export."),
 (24,"vault","image","privacy","Cifrado local con claves del dispositivo","Local encryption with device-only keys",["Originales importados cifrados en reposo","Cachés de render cifradas","Bóveda con clave independiente"],["Imported originals encrypted at rest","Render caches encrypted","Vault uses a separate key"],"La seguridad no está bloqueada tras Pro.","Security is not locked behind Pro."),
 (25,"paywall","carousel","product","Qué incluye MaskID gratis","What MaskID includes for free",["Importación, cámara y escáner","OCR conservador y máscara manual","Exportación rasterizada verificada sin marca forzada"],["Import, camera and scanner","Conservative OCR and manual masking","Verified rasterized export with no forced watermark"],"Hasta 10 documentos activos.","Up to 10 active documents."),
 (26,"paywall","infographic","product","Cuándo tiene sentido MaskID Pro","When MaskID Pro makes sense",["Proyectos activos ilimitados","Lotes y plantillas reutilizables","Estilos y automatización avanzados"],["Unlimited active projects","Batches and reusable templates","Advanced styles and automation"],"La protección esencial sigue disponible gratis.","Essential protection remains available for free."),
 (27,"editor","carousel","education","El flujo seguro en cinco pasos","The safer workflow in five steps",["Importa","Selecciona y revisa","Aplica máscaras","Exporta","Comprueba y comparte"],["Import","Select and review","Apply masks","Export","Check and share"],"No saltes la revisión final.","Do not skip the final review."),
 (28,"settings","image","trust","Sin anuncios. Sin seguimiento. Sin vender tu atención.","No ads. No tracking. No selling your attention.",["No hay backend publicitario","No se perfila tu uso","La privacidad es parte del producto"],["No advertising backend","No usage profiling","Privacy is part of the product"],"Compara herramientas por lo que recopilan.","Compare tools by what they collect."),
 (29,"batch","carousel","product","Velocidad con una regla: cada resultado se revisa","Speed with one rule: every result gets reviewed",["Reutiliza flujos en Pro","Procesa grupos de documentos","Comprueba cada salida"],["Reuse workflows in Pro","Process groups of documents","Check every output"],"La productividad no elimina la responsabilidad.","Productivity does not remove responsibility."),
 (30,"home","infographic","awareness","Tu nueva rutina antes de pulsar Enviar","Your new routine before tapping Send",["Minimiza","Enmascara","Verifica","Comparte la copia"],["Minimize","Mask","Verify","Share the copy"],"Instala MaskID y conserva esta rutina.","Install MaskID and keep this routine."),
]


def source_path(lang, scene):
    locale = "es-ES" if lang == "es" else "en-US"
    index = {"home":1,"capture":2,"editor":3,"ocr":4,"export":5,"gallery":6,"vault":7,"batch":8,"paywall":9,"settings":10}[scene]
    return CAPTURES / locale / "iphone-69" / f"{index:02d}-{scene}.png"


def render_asset(topic, lang, slide, total):
    day, scene, fmt, pillar, es_hook, en_hook, es_facts, en_facts, es_cta, en_cta = topic
    hook, facts, cta = (es_hook, es_facts, es_cta) if lang == "es" else (en_hook, en_facts, en_cta)
    src = Image.open(source_path(lang, scene)).convert("RGB")
    canvas = Image.new("RGB", (W,H), NAVY)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((52,48,270,102), 27, fill=CYAN)
    draw.text((82,61), "MASKID", font=fnt(27), fill=NAVY)
    draw.text((805,60), f"{day:02d}/30", font=fnt(28), fill=MUTED)
    if slide == 1:
        title = hook
        subtitle = "PRIVACIDAD EN EL DISPOSITIVO" if lang == "es" else "PRIVACY ON DEVICE"
    elif slide <= len(facts)+1:
        title = facts[slide-2]
        subtitle = f"{slide-1}/{len(facts)}"
    else:
        title, subtitle = cta, ("REVISA ANTES DE COMPARTIR" if lang == "es" else "REVIEW BEFORE SHARING")
    y=145
    for line in wrap(draw,title,fnt(58),930):
        draw.text((68,y),line,font=fnt(58),fill=WHITE); y+=68
    draw.text((70,y+12),subtitle,font=fnt(25),fill=CYAN)
    if fmt == "infographic":
        card_y = y + 62
        for number, fact in enumerate(facts, 1):
            draw.rounded_rectangle((62, card_y, 1018, card_y + 72), 24, fill=SURFACE)
            draw.ellipse((82, card_y + 16, 122, card_y + 56), fill=CYAN)
            draw.text((95, card_y + 21), str(number), font=fnt(20), fill=NAVY)
            draw.text((145, card_y + 19), fact, font=fnt(27), fill=WHITE)
            card_y += 84
        top = max(700, card_y + 26)
    else:
        top=max(430,y+80)
    target_h=H-top+190
    scale=target_h/src.height
    shot=src.resize((int(src.width*scale),target_h),Image.Resampling.LANCZOS)
    x=(W-shot.width)//2
    canvas.paste(shot,(x,top))
    shade=Image.new("RGBA",(W,H),(0,0,0,0)); sd=ImageDraw.Draw(shade)
    sd.rectangle((0,H-155,W,H),fill=(7,20,38,225))
    canvas=Image.alpha_composite(canvas.convert("RGBA"),shade).convert("RGB")
    d=ImageDraw.Draw(canvas)
    footer = ("CAPTURA REAL DEL SIMULADOR" if lang=="es" else "REAL SIMULATOR CAPTURE") + f"  •  {slide}/{total}"
    d.text((68,H-105),footer,font=fnt(23),fill=MUTED)
    path=OUT/"assets"/lang/f"day-{day:02d}"
    path.mkdir(parents=True,exist_ok=True)
    out=path/f"slide-{slide:02d}.png"
    canvas.save(out,"PNG",optimize=True)
    return out


def captions(topic, lang):
    day, scene, fmt, pillar, es_hook, en_hook, es_facts, en_facts, es_cta, en_cta = topic
    hook, facts, cta = (es_hook,es_facts,es_cta) if lang=="es" else (en_hook,en_facts,en_cta)
    bullet="\n".join(f"• {x}" for x in facts)
    tags = "#PrivacidadDigital #ProteccionDeDatos #MaskID #Documentos" if lang=="es" else "#DigitalPrivacy #DataProtection #MaskID #Documents"
    safety = "Revisa siempre cada zona antes de compartir." if lang=="es" else "Always review every region before sharing."
    return {
      "instagram": f"{hook}\n\n{bullet}\n\n{cta}\n\n{safety}\n\n{tags}",
      "linkedin": f"{hook}\n\nCompartir menos datos no significa ocultar información necesaria; significa revisar el propósito de cada copia.\n\n{bullet}\n\n{cta} {safety}\n\n{tags}" if lang=="es" else f"{hook}\n\nSharing less data does not mean hiding required information; it means reviewing the purpose of every copy.\n\n{bullet}\n\n{cta} {safety}\n\n{tags}",
      "x": f"{hook}\n\n{facts[0]}. {facts[1]}.\n\n{cta}\n\n#MaskID #Privacidad" if lang=="es" else f"{hook}\n\n{facts[0]}. {facts[1]}.\n\n{cta}\n\n#MaskID #Privacy",
      "facebook": f"{hook}\n\n{bullet}\n\n{cta} {safety}\n\n{tags}",
      "tiktok": f"{hook}\n\n{bullet}\n\n{cta}\n\n{tags}",
    }


# Dedicated six-slide explainers integrated into selected campaign days.
# Each statement below is constrained to capabilities verified in product positioning.
FEATURES = [
 ("capture-import", "capture", 2,
  [("¿Te piden un documento ya?", "Cambiar de app o de formato añade fricción cuando el trámite ya está en marcha."), ("Empieza desde donde lo tienes", "Escanea con la cámara o importa desde Fotos, Archivos y PDF."), ("Cómo se usa", "1. Elige la fuente  2. Revisa la captura  3. Abre el editor"), ("Por qué resulta útil", "Un único punto de entrada para copias, imágenes y documentos de varias páginas."), ("Límite importante", "Los proveedores cloud se abren mediante Archivos de Apple; MaskID solo recibe lo que eliges."), ("Solución cotidiana", "Pasa del documento recibido a una copia de trabajo sin enviar el original a un servicio de análisis.")],
  [("Need to share a document now?", "Switching apps or formats adds friction when the process is already underway."), ("Start where the file lives", "Scan with the camera or import from Photos, Files and PDF."), ("How it works", "1. Choose the source  2. Review the capture  3. Open the editor"), ("Why it is useful", "One entry point for scans, images and multi-page documents."), ("Important limit", "Cloud providers open through Apple Files; MaskID only receives what you select."), ("Everyday solution", "Move from a received document to a working copy without sending the original to an analysis service.")]),
 ("precision-editor", "editor", 3,
  [("Un dato privado ocupa una zona concreta", "Recortar una página entera puede volver inútil el documento."), ("Editor de máscara manual", "Marca direcciones, firmas, números, retratos o cualquier región sensible."), ("Cómo se usa", "1. Amplía  2. Dibuja la región  3. Ajusta  4. Revisa"), ("Cualidad diferencial", "Tú decides el contexto: la herramienta no impone qué información exige el receptor."), ("Límite importante", "Una región no seleccionada no puede protegerse; revisa todas las páginas."), ("Solución cotidiana", "Entrega una copia legible conservando los campos necesarios para el trámite.")],
  [("Private data occupies a specific region", "Cropping an entire page can make the document unusable."), ("Manual precision editor", "Mark addresses, signatures, numbers, portraits or any sensitive region."), ("How it works", "1. Zoom  2. Draw the region  3. Adjust  4. Review"), ("Distinctive quality", "You decide the context: the tool does not dictate what the recipient requires."), ("Important limit", "An unselected region cannot be protected; review every page."), ("Everyday solution", "Deliver a readable copy while keeping the fields required for the process.")]),
 ("on-device-ocr", "ocr", 4,
  [("Encontrar cada dato a mano lleva tiempo", "Los documentos densos esconden números, nombres y direcciones entre mucho texto."), ("Sugerencias OCR en el dispositivo", "MaskID identifica campos sensibles posibles sin enviar el documento a una nube de análisis."), ("Cómo se usa", "1. Analiza  2. Lee la sugerencia  3. Acepta, ajusta o descarta"), ("Cualidad diferencial", "La sugerencia acelera la búsqueda sin quitarte la decisión final."), ("Límite importante", "El OCR puede omitir datos o sugerir de más. No garantiza detección completa."), ("Solución cotidiana", "Reduce el trabajo repetitivo y concentra tu atención en la revisión.")],
  [("Finding every detail manually takes time", "Dense documents hide numbers, names and addresses inside lots of text."), ("On-device OCR suggestions", "MaskID identifies possible sensitive fields without sending the document to an analysis cloud."), ("How it works", "1. Analyze  2. Read the suggestion  3. Accept, adjust or discard"), ("Distinctive quality", "Suggestions speed up discovery without taking away your final decision."), ("Important limit", "OCR may miss details or suggest too much. It cannot guarantee complete detection."), ("Everyday solution", "Reduce repetitive work and focus your attention on review.")]),
 ("verified-export", "export", 5,
  [("Una caja negra visible puede ser solo una capa", "En algunos archivos el texto original continúa debajo y puede recuperarse."), ("Exportación rasterizada y verificada", "MaskID integra las máscaras en una copia plana y comprueba texto recuperable."), ("Cómo se usa", "1. Revisa máscaras  2. Exporta  3. Espera la comprobación  4. Comparte la copia"), ("Cualidad superior verificable", "No confía únicamente en que la máscara se vea negra: valida la salida generada."), ("Límite importante", "Solo se llama salida verificada cuando el comprobador termina correctamente."), ("Solución cotidiana", "Evita compartir por error un PDF con texto oculto todavía seleccionable.")],
  [("A visible black box may be only an overlay", "In some files the original text remains underneath and can be recovered."), ("Rasterized, verified export", "MaskID integrates masks into a flat copy and checks for recoverable text."), ("How it works", "1. Review masks  2. Export  3. Wait for verification  4. Share the copy"), ("Verifiable superior quality", "It does not rely only on a black-looking mask: it validates the generated output."), ("Important limit", "The output is called verified only after the verifier finishes successfully."), ("Everyday solution", "Avoid accidentally sharing a PDF whose hidden text can still be selected.")]),
 ("mask-styles", "gallery", 8,
  [("No todas las copias necesitan el mismo aspecto", "Una máscara puede ocultar, identificar el motivo o preservar contexto visual."), ("Estilos de máscara", "Usa negro, blanco, etiqueta, pixelado y controles visuales disponibles."), ("Cómo se usa", "1. Selecciona la región  2. Elige estilo  3. Previsualiza  4. Exporta"), ("Por qué resulta útil", "Adapta la claridad visual a documentación administrativa, interna o personal."), ("Límite importante", "Los estilos avanzados y controles de imagen forman parte de Pro."), ("Solución cotidiana", "Crea una copia comprensible sin exponer el contenido cubierto.")],
  [("Not every copy needs the same appearance", "A mask can hide, explain its purpose or preserve visual context."), ("Mask styles", "Use black, white, labeled, pixelated and available visual controls."), ("How it works", "1. Select the region  2. Choose a style  3. Preview  4. Export"), ("Why it is useful", "Adapt visual clarity for administrative, internal or personal documents."), ("Important limit", "Advanced styles and image controls are part of Pro."), ("Everyday solution", "Create an understandable copy without exposing the covered content.")]),
 ("encrypted-vault", "vault", 7,
  [("Una copia protegida sigue siendo un archivo privado", "Dejarla accesible junto a documentos normales aumenta la exposición accidental."), ("Bóveda cifrada local", "MaskID usa una clave separada y exige autenticación del dispositivo o PIN."), ("Cómo se usa", "1. Mueve a la Bóveda  2. Autentícate al entrar  3. Gestiona la copia local"), ("Cualidad diferencial", "Añade una frontera de acceso además del cifrado local en reposo."), ("Límite importante", "La Bóveda no equivale a una copia de seguridad cloud."), ("Solución cotidiana", "Mantén documentos de identidad y copias de trámites fuera del acceso casual.")],
  [("A protected copy is still a private file", "Leaving it beside ordinary documents increases accidental exposure."), ("Locally encrypted Vault", "MaskID uses a separate key and requires device authentication or a PIN."), ("How it works", "1. Move to Vault  2. Authenticate on entry  3. Manage the local copy"), ("Distinctive quality", "It adds an access boundary on top of local encryption at rest."), ("Important limit", "Vault is not the same as a cloud backup."), ("Everyday solution", "Keep identity documents and process copies away from casual access.")]),
 ("batch-workflows", "batch", 14,
  [("Repetir el mismo trabajo en muchos archivos consume tiempo", "Equipos y profesionales reciben documentos con estructuras parecidas."), ("Lotes y flujos reutilizables en Pro", "Aplica una preparación común a varios documentos y revisa cada resultado."), ("Cómo se usa", "1. Define el flujo  2. Añade documentos  3. Procesa  4. Revisa cada salida"), ("Por qué resulta útil", "Reduce pasos repetitivos sin convertir la revisión en una caja negra."), ("Límite importante", "El lote no garantiza que todos los documentos tengan la misma estructura."), ("Solución cotidiana", "Agiliza expedientes repetitivos conservando una revisión humana final.")],
  [("Repeating the same work across many files takes time", "Teams and professionals receive documents with similar structures."), ("Batches and reusable workflows in Pro", "Apply common preparation to multiple documents and review every result."), ("How it works", "1. Define the flow  2. Add documents  3. Process  4. Review every output"), ("Why it is useful", "Reduce repetitive steps without turning review into a black box."), ("Important limit", "A batch cannot guarantee that every document has the same structure."), ("Everyday solution", "Speed up recurring case files while preserving final human review.")]),
 ("local-encryption", "settings", 24,
  [("Los archivos privados también descansan en el dispositivo", "La protección no termina cuando cierras el editor."), ("Cifrado local en reposo", "Originales importados, cachés de render y telemetría local usan claves del dispositivo."), ("Qué protege", "Contenido almacenado localmente y materiales temporales utilizados durante el trabajo."), ("Cualidad esencial", "Seguridad, cifrado y verificación no se bloquean detrás de la suscripción."), ("Límite importante", "El cifrado del dispositivo no sustituye un código seguro ni el control físico del teléfono."), ("Solución cotidiana", "Reduce la exposición si alguien intenta acceder a los archivos almacenados fuera del flujo autorizado.")],
  [("Private files also rest on the device", "Protection does not end when you close the editor."), ("Local encryption at rest", "Imported originals, render caches and local telemetry use device-only keys."), ("What it protects", "Locally stored content and temporary materials used during processing."), ("Essential quality", "Security, encryption and verification are not locked behind a subscription."), ("Important limit", "Device encryption does not replace a strong passcode or physical control of the phone."), ("Everyday solution", "Reduce exposure when someone attempts to access stored files outside the authorized flow.")]),
 ("private-cloud-access", "settings", 22,
  [("Tu documento está en Drive o Dropbox", "No deberías entregar nuevas credenciales solo para elegir un archivo."), ("Acceso mediante Archivos de Apple", "El sistema presenta tus proveedores y MaskID recibe únicamente el archivo seleccionado."), ("Cómo se usa", "1. Abre Archivos  2. Elige proveedor  3. Selecciona el documento"), ("Cualidad diferencial", "MaskID no almacena tokens OAuth del proveedor."), ("Límite importante", "La disponibilidad del proveedor depende de su integración con Archivos y de tu configuración."), ("Solución cotidiana", "Importa un archivo cloud manteniendo la autenticación bajo control del sistema.")],
  [("Your document is in Drive or Dropbox", "You should not need to hand over new credentials just to choose a file."), ("Access through Apple Files", "The system presents your providers and MaskID receives only the selected file."), ("How it works", "1. Open Files  2. Choose provider  3. Select the document"), ("Distinctive quality", "MaskID stores no provider OAuth tokens."), ("Important limit", "Provider availability depends on its Files integration and your configuration."), ("Everyday solution", "Import a cloud file while keeping authentication under system control.")]),
 ("free-vs-pro", "paywall", 25,
  [("¿Necesitas pagar para proteger un documento?", "La protección esencial no debería depender de una suscripción."), ("MaskID Free", "Importa, escanea, enmascara, usa OCR conservador y exporta copias verificadas sin marca forzada."), ("MaskID Pro", "Añade proyectos ilimitados, lotes, plantillas, estilos y automatización avanzada."), ("Qué permanece gratis", "Cifrado, privacidad, verificación, accesibilidad y hasta 10 documentos activos."), ("Cuándo elegir Pro", "Cuando el volumen, la repetición o la personalización justifican flujos avanzados."), ("Solución cotidiana", "Empieza protegiendo copias reales y amplía solo cuando tu uso lo necesite.")],
  [("Must you pay to protect a document?", "Essential protection should not depend on a subscription."), ("MaskID Free", "Import, scan, mask, use conservative OCR and export verified copies with no forced watermark."), ("MaskID Pro", "Adds unlimited projects, batches, templates, styles and advanced automation."), ("What remains free", "Encryption, privacy, verification, accessibility and up to 10 active documents."), ("When to choose Pro", "When volume, repetition or customization justify advanced workflows."), ("Everyday solution", "Start protecting real copies and upgrade only when your usage requires it.")]),
]


def render_feature_slide(slug, scene, day, lang, sections, slide):
    title, body = sections[slide - 1]
    src = Image.open(source_path(lang, scene)).convert("RGB")
    canvas = Image.new("RGB", (W, H), NAVY)
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((52, 46, 270, 100), 27, fill=CYAN)
    draw.text((82, 59), "MASKID", font=fnt(27), fill=NAVY)
    draw.text((830, 59), f"{slide}/6", font=fnt(27), fill=MUTED)
    label = "GUÍA DE FUNCIÓN" if lang == "es" else "FEATURE GUIDE"
    draw.text((68, 140), label, font=fnt(24), fill=CYAN)
    y = 190
    for line in wrap(draw, title, fnt(52), 930):
        draw.text((68, y), line, font=fnt(52), fill=WHITE); y += 62
    y += 18
    for line in wrap(draw, body, fnt(31), 920):
        draw.text((70, y), line, font=fnt(31), fill=MUTED); y += 43
    top = max(600, y + 40)
    target_h = H - top + 180
    scale = target_h / src.height
    shot = src.resize((int(src.width * scale), target_h), Image.Resampling.LANCZOS)
    canvas.paste(shot, ((W - shot.width) // 2, top))
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(overlay).rectangle((0, H - 142, W, H), fill=(7, 20, 38, 232))
    canvas = Image.alpha_composite(canvas.convert("RGBA"), overlay).convert("RGB")
    footer = "CAPTURA REAL DEL SIMULADOR" if lang == "es" else "REAL SIMULATOR CAPTURE"
    ImageDraw.Draw(canvas).text((68, H - 94), f"{footer}  •  DÍA {day:02d}", font=fnt(23), fill=MUTED)
    folder = OUT / "feature-infographics" / slug / lang
    folder.mkdir(parents=True, exist_ok=True)
    out = folder / f"slide-{slide:02d}.png"
    canvas.save(out, "PNG", optimize=True)
    return out


def feature_caption(slug, lang, sections):
    titles = [title for title, _ in sections]
    if lang == "es":
        return f"{titles[0]}\n\nEsta guía explica {titles[1].lower()}, cómo se usa, qué ventaja aporta y qué límite debes revisar. Desliza las 6 pantallas y guarda la lista para tu próximo documento.\n\nRevisa siempre cada región antes de compartir.\n\n#MaskID #PrivacidadDigital #ProteccionDeDatos #Documentos"
    return f"{titles[0]}\n\nThis guide explains {titles[1].lower()}, how it works, the advantage it provides and the limit you must review. Swipe through all 6 screens and save the checklist for your next document.\n\nAlways review every region before sharing.\n\n#MaskID #DigitalPrivacy #DataProtection #Documents"


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    for platform in PLATFORMS:
        (OUT/"platforms"/platform).mkdir(parents=True,exist_ok=True)
    (OUT/"source-captures").mkdir(parents=True,exist_ok=True)
    rows=[]
    for topic in TOPICS:
        day,scene,fmt,pillar,*_ = topic
        slides = 5 if fmt=="carousel" else 1
        for lang in ("es","en"):
            for n in range(1,slides+1): render_asset(topic,lang,n,slides)
            copy=captions(topic,lang)
            for platform in PLATFORMS:
                label={"es":"ESPAÑOL","en":"ENGLISH"}[lang]
                asset=f"../../assets/{lang}/day-{day:02d}/slide-01.png"
                extra = "Publicación de fotos: sube las 5 diapositivas en orden." if lang=="es" else "Photo post: upload all 5 slides in order."
                if fmt != "carousel": extra = "Publica la imagen única." if lang=="es" else "Publish the single image."
                md=f"# Day {day:02d} — {label}\n\n- Format: {fmt}\n- Pillar: {pillar}\n- Asset: [{asset}]({asset})\n- Publishing note: {extra}\n\n## Copy\n\n{copy[platform]}\n\n## Alt text\n\n" + ((f"Pantalla real de MaskID en el simulador mostrando {scene}, con el titular: {topic[4]}." if lang=="es" else f"Real MaskID simulator screen showing {scene}, with the headline: {topic[5]}.")+"\n")
                (OUT/"platforms"/platform/f"day-{day:02d}-{lang}.md").write_text(md)
            rows.append([day,lang,fmt,pillar,scene,"09:00" if platform=="linkedin" else "19:30",f"assets/{lang}/day-{day:02d}/slide-01.png"])
    feature_rows = []
    for slug, scene, day, es_sections, en_sections in FEATURES:
        for lang, sections in (("es", es_sections), ("en", en_sections)):
            for slide in range(1, 7):
                render_feature_slide(slug, scene, day, lang, sections, slide)
            caption = feature_caption(slug, lang, sections)
            alt = (f"Carrusel de seis capturas reales del simulador que explica {sections[1][0].lower()}, su utilidad, pasos y límites."
                   if lang == "es" else
                   f"Six-slide carousel made from real simulator captures explaining {sections[1][0].lower()}, its value, steps and limits.")
            copy_file = OUT / "feature-infographics" / slug / f"platform-copy-{lang}.md"
            copy_file.write_text(
                f"# {sections[1][0]}\n\n- Campaign day: {day:02d}\n- Format: 6-slide carousel\n- Networks: Instagram, LinkedIn, Facebook and TikTok photo mode; X as a four-post thread.\n\n## Instagram / Facebook / LinkedIn / TikTok\n\n{caption}\n\n## X thread\n\n1/ {sections[0][0]} {sections[0][1]}\n\n2/ {sections[1][0]}: {sections[1][1]}\n\n3/ {sections[2][0]}: {sections[2][1]}\n\n4/ {sections[4][0]}: {sections[4][1]}\n\n## Alt text\n\n{alt}\n"
            )
            daily_note = OUT / "platforms" / "instagram" / f"day-{day:02d}-{lang}.md"
            for platform in PLATFORMS:
                daily_note = OUT / "platforms" / platform / f"day-{day:02d}-{lang}.md"
                relative = Path("../../feature-infographics") / slug / lang / "slide-01.png"
                with daily_note.open("a") as fp:
                    fp.write(f"\n## Integrated feature infographic\n\nUse the complete six-slide explainer starting at [{relative}]({relative}). Platform-ready extended copy: [feature guide](../../feature-infographics/{slug}/platform-copy-{lang}.md).\n")
            feature_rows.append([day, slug, lang, scene, 6, f"feature-infographics/{slug}/{lang}/slide-01.png"])
    with (OUT / "feature-infographics-calendar.csv").open("w", newline="") as fp:
        writer = csv.writer(fp)
        writer.writerow(["campaign_day", "feature", "language", "scene", "slides", "lead_asset"])
        writer.writerows(feature_rows)
    for lang in ("es","en"):
        locale="es-ES" if lang=="es" else "en-US"
        for src in sorted((CAPTURES/locale/"iphone-69").glob("*.png")):
            shutil.copy2(src,OUT/"source-captures"/f"{lang}-{src.name}")
    with (OUT/"calendar.csv").open("w",newline="") as fp:
        w=csv.writer(fp); w.writerow(["day","language","format","pillar","scene","suggested_local_time","lead_asset"]); w.writerows(rows)
    readme='''# MaskID — 30-day bilingual social campaign

Publish-ready campaign for Instagram, LinkedIn, X, Facebook and TikTok photo posts. Every visual is composed exclusively from authentic MaskID iPhone Simulator captures with synthetic, non-personal fixtures; no stock, generated photography or unsupported product screens are used.

## How to publish

1. Choose the platform folder and the day's language file.
2. Upload `slide-01.png`; for carousel days upload all five slides in numeric order.
3. Paste the platform-specific copy and alt text.
4. Use the proposed time as a starting point, then adapt using account analytics.
5. Reply to comments without promising automatic completeness or anonymity.

## Campaign guardrails

- Never claim 100% detection, anonymity or irreversible redaction without verifier context.
- OCR suggestions assist; the user must review every selected region.
- “Verified copy/output” is used only for the export flow after its verifier passes.
- Free and Pro claims follow the current product positioning.
- Cloud-provider access is described only through Apple's Files picker.
- The campaign does not advertise unavailable collaboration, Android, web or automatic identity removal.

## Structure

- `platforms/`: 30 Spanish and 30 English posts per network (300 caption files total).
- `assets/`: 60 daily visual sets, sized 1080×1350.
- `source-captures/`: the 20 simulator-derived source compositions used by the campaign.
- `feature-infographics/`: 10 detailed six-slide feature explainers in both languages.
- `calendar.csv`: master production and scheduling index.
- `feature-infographics-calendar.csv`: exact days where each explainer is integrated.
- `STRATEGY.md`: goals, pillars, cadence, metrics and operating rules.
'''
    (OUT/"README.md").write_text(readme)
    strategy='''# Strategy / Estrategia

## Objective / Objetivo

Build awareness and trust for MaskID while teaching a repeatable pre-share document routine. The conversion action is an App Store visit or save/share; education and trust take priority over direct promotion.

Crear notoriedad y confianza en MaskID mientras se enseña una rutina repetible antes de compartir documentos. La acción de conversión es visitar App Store o guardar/compartir; educación y confianza tienen prioridad sobre promoción directa.

## Audience / Audiencia

People and professionals sharing identity, rental, employment, banking, travel or health documents who want to reduce unnecessary exposure without misrepresenting what a recipient requires.

Personas y profesionales que comparten documentos de identidad, alquiler, empleo, banca, viajes o salud y quieren reducir exposición innecesaria sin falsear los requisitos del receptor.

## Pillars / Pilares

- Education / Educación — safe review habits, OCR limits, document checklists.
- Trust & privacy / Confianza y privacidad — on-device processing, encryption, no tracking.
- Product / Producto — capture, editor, export, Vault, styles, Free and Pro.
- Use cases / Casos de uso — identity, rentals, employment and banking documents.

## Cadence / Cadencia

One core daily idea, localized rather than literally translated, adapted to five networks. Instagram and TikTok use 4:5 photo posts; LinkedIn uses the same document carousel; Facebook uses native images; X uses the lead image and condensed copy. Recommended times are hypotheses only and must be replaced by account analytics after two weeks.

Una idea central diaria, localizada y adaptada a cinco redes. Instagram y TikTok usan publicaciones fotográficas 4:5; LinkedIn reutiliza el carrusel documental; Facebook usa imágenes nativas; X usa la imagen principal y texto condensado. Los horarios son hipótesis y deben sustituirse por datos reales tras dos semanas.

## Weekly operating loop / Ciclo semanal

Track reach, saves, shares, qualified comments, profile visits and App Store clicks. Each week keep the two strongest hooks, revise the two weakest, and never optimize by exaggerating detection accuracy or security guarantees.

Mide alcance, guardados, compartidos, comentarios cualificados, visitas al perfil y clics a App Store. Conserva cada semana los dos mejores ganchos, revisa los dos peores y nunca optimices exagerando la precisión de detección o las garantías de seguridad.
'''
    (OUT/"STRATEGY.md").write_text(strategy)
    manifest='''# Visual provenance / Procedencia visual

All source files below originate from the project's deterministic iPhone Simulator screenshot flow (`ShieldLaunchTests` with `-aso-screenshots`, language and scene launch arguments). Campaign assets only crop, scale and add typography around those real UI captures.

Todos los archivos fuente proceden del flujo determinista de capturas del simulador de iPhone del proyecto (`ShieldLaunchTests` con argumentos de escena e idioma). Los recursos de campaña solo recortan, escalan y añaden tipografía alrededor de esas capturas reales de interfaz.

Scenes: home, capture, editor, OCR, verified export, style gallery, Vault, batch processing, paywall and settings/privacy — in English and Spanish.
'''
    (OUT/"VISUAL-PROVENANCE.md").write_text(manifest)
    print(OUT)

if __name__ == "__main__": main()
