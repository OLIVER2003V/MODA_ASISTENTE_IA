import win32com.client
import json
import os

def ejecutar_superscript(archivo_json='diagrama.json'):
    print(f"Cargando plano desde: {archivo_json}...")

    if not os.path.exists(archivo_json):
        print(f"ERROR: No se encontró el archivo {archivo_json}.")
        return

    with open(archivo_json, 'r', encoding='utf-8') as f:
        datos = json.load(f)

    config_diag = datos.get("configuracion", {})
    tipo_diagrama = config_diag.get("tipo", "Logical")
    nombre_diagrama = config_diag.get("nombre", "Diagrama Generado")

    # ==========================================================
    # MOTOR PLANTUML (Exclusivo para Diagramas de Tiempo)
    # ==========================================================
    if tipo_diagrama.lower() == "timing":
        print("\nDetectado Diagrama de Tiempo.")
        print("Generando archivo PlantUML...")

        lineas_puml = [
            "@startuml",
            "scale 1.5",
            f"caption Escala de tiempo en milisegundos (ms) - {nombre_diagrama}"
        ]

        lineas_datos = datos.get("lineas", [])

        for i, linea in enumerate(lineas_datos):
            alias = f"L{i}"
            lineas_puml.append(f"robust \"{linea['nombre']}\" as {alias}")

        lineas_puml.append("")

        tiempos_unicos = set()
        for linea in lineas_datos:
            for ev in linea.get("eventos", []):
                tiempos_unicos.add(float(ev["t"]))

        for t in sorted(tiempos_unicos):
            lineas_puml.append(f"@{t}")
            for i, linea in enumerate(lineas_datos):
                alias = f"L{i}"
                for ev in linea.get("eventos", []):
                    if float(ev["t"]) == t:
                        lineas_puml.append(f"{alias} is \"{ev['estado']}\"")

        lineas_puml.append("@enduml")
        contenido = "\n".join(lineas_puml)

        archivo_salida = "diagrama_tiempo.puml"
        with open(archivo_salida, 'w', encoding='utf-8') as f:
            f.write(contenido)

        print(f"\n¡ÉXITO! Se generó el diagrama escalonado.")
        print("Copia el texto de abajo y pégalo en https://www.planttext.com/")
        print("-" * 40)
        print(contenido)
        print("-" * 40)
        return

    # ==========================================================
    # MOTOR ENTERPRISE ARCHITECT
    # ==========================================================
    print("Conectando con Enterprise Architect...")
    try:
        eaApp = win32com.client.Dispatch("EA.App")
        repo = eaApp.Repository
        paquete_actual = repo.GetTreeSelectedPackage()

        if paquete_actual is None:
            print("ERROR: Selecciona un paquete/carpeta en el explorador de EA primero.")
            return

        print(f"--- Generando modelo en: {paquete_actual.Name} ---")

        elementos = datos.get("elementos", [])
        relaciones = datos.get("relaciones", [])
        ids_elementos = {}

        # ----------------------------------------------------------
        # 1. CREAR ELEMENTOS
        # ----------------------------------------------------------
        for item in elementos:
            tipo_ea = item["tipo"]
            subtipo = None
            es_pequeno = False

            if tipo_ea == "Initial":
                tipo_ea = "StateNode"
                subtipo = 3
                es_pequeno = True
            elif tipo_ea in ["Final", "FinalState"]:
                tipo_ea = "StateNode"
                subtipo = 4
                es_pequeno = True

            nuevo_elemento = paquete_actual.Elements.AddNew(item["nombre"], tipo_ea)

            if "notas" in item:
                nuevo_elemento.Notes = item["notas"]

            # Soporte de estereotipos (<<device>>, <<executionEnvironment>>, etc.)
            if "stereotipo" in item:
                nuevo_elemento.Stereotype = item["stereotipo"]

            if subtipo is not None:
                nuevo_elemento.Subtype = subtipo

            for i, attr_data in enumerate(item.get("atributos", [])):
                attr = nuevo_elemento.Attributes.AddNew(
                    attr_data.get("nombre", ""),
                    attr_data.get("tipo", "")
                )
                attr.Visibility = "Private"
                attr.Pos = i
                attr.Update()

            nuevo_elemento.Update()
            ids_elementos[item["nombre"]] = {
                "id": nuevo_elemento.ElementID,
                "es_pequeno": es_pequeno
            }
            print(f"Elemento creado: {item['nombre']} [{item['tipo']}]")

        # ----------------------------------------------------------
        # 1.5 ESTABLECER ANIDAMIENTO PADRE-HIJO
        # ----------------------------------------------------------
        for item in elementos:
            if "padre" in item:
                padre_datos = ids_elementos.get(item["padre"])
                if padre_datos:
                    hijo = repo.GetElementByID(ids_elementos[item["nombre"]]["id"])
                    padre_elem = repo.GetElementByID(padre_datos["id"])
                    if padre_elem.Type == "Package":
                        # Para paquetes EA requiere PackageID, no ParentID
                        pkgs = paquete_actual.Packages
                        for i in range(pkgs.Count):
                            pkg = pkgs.GetAt(i)
                            if pkg.Element.ElementID == padre_datos["id"]:
                                hijo.PackageID = pkg.PackageID
                                break
                    else:
                        hijo.ParentID = padre_datos["id"]
                    hijo.Update()
                    print(f"  Anidado: '{item['nombre']}' -> '{item['padre']}'")
                else:
                    print(f"  AVISO: padre '{item['padre']}' no encontrado para '{item['nombre']}'")

        # ----------------------------------------------------------
        # 1.7 CREAR COMBINED FRAGMENTS (alt, opt, loop, ref...)
        # ----------------------------------------------------------
        for frag in datos.get("fragmentos", []):
            frag_elem = paquete_actual.Elements.AddNew("", "InteractionFragment")
            frag_elem.Stereotype = frag.get("tipo", "alt")
            frag_elem.Update()
            ids_elementos[frag["titulo"]] = {"id": frag_elem.ElementID, "es_pequeno": False}
            print(f"Fragmento: [{frag.get('tipo','')}]")

        # ----------------------------------------------------------
        # 2. CREAR RELACIONES
        # ----------------------------------------------------------
        es_secuencia    = (tipo_diagrama.lower() == "sequence")
        es_estado       = (tipo_diagrama.lower() in ["statechart", "state machine", "state"])
        es_caso_uso     = (tipo_diagrama.lower() == "use case")
        es_deployment   = (tipo_diagrama.lower() == "deployment")
        es_comunicacion = (tipo_diagrama.lower() in ["collaboration", "communication"])
        ids_conectores = []

        for rel in relaciones:
            if es_comunicacion:
                continue  # Para diagramas de comunicacion los conectores se crean DESPUES del layout
            nodo_origen  = ids_elementos.get(rel["origen"])
            nodo_destino = ids_elementos.get(rel["destino"])

            if nodo_origen and nodo_destino:
                elemento_origen = repo.GetElementByID(nodo_origen["id"])
                conector = elemento_origen.Connectors.AddNew(rel.get("nombre", ""), rel["tipo"])
                conector.SupplierID = nodo_destino["id"]

                # Flecha dirigida cuando el JSON marca "dirigido": true
                if rel.get("dirigido"):
                    conector.Direction = "Source -> Destination"

                # Subtipo: 0=sincrono (→), 3=retorno dashed (⤶), 4=asincrono (⇒)
                if "subtipo" in rel:
                    conector.Subtype = rel["subtipo"]

                # Mensajes de comunicación: flecha dirigida de origen a destino
                if es_comunicacion and rel["tipo"] == "Message":
                    conector.Direction = "Source -> Destination"

                # <<trace>> solo aplica en diagramas no-deployment y no-comunicacion
                if rel["tipo"] == "Dependency" and not es_deployment and not es_comunicacion:
                    conector.Stereotype = "trace"

                if es_secuencia:
                    conector.SequenceNo = relaciones.index(rel) + 1

                if "mult_origen" in rel:
                    conector.ClientEnd.Cardinality = rel["mult_origen"]
                    conector.ClientEnd.Update()
                if "mult_destino" in rel:
                    conector.SupplierEnd.Cardinality = rel["mult_destino"]
                    conector.SupplierEnd.Update()

                conector.Update()
                ids_conectores.append(conector.ConnectorID)
                print(f"Conexion: {rel['origen']} --({rel['tipo']})--> {rel['destino']}")

        # ----------------------------------------------------------
        # 3. MOTOR DE COORDENADAS / LAYOUT
        # ----------------------------------------------------------
        diagrama = paquete_actual.Diagrams.AddNew(nombre_diagrama, tipo_diagrama)
        diagrama.Update()

        # --- LAYOUT: CASOS DE USO ---
        if es_caso_uso:
            actores_izq = [e for e in elementos if e["tipo"] == "Actor" and e.get("posicion", "izquierda") == "izquierda"]
            actores_der = [e for e in elementos if e["tipo"] == "Actor" and e.get("posicion") == "derecha"]
            casos_uso   = [e for e in elementos if e["tipo"] == "UseCase"]
            fronteras   = [e for e in elementos if e["tipo"] == "Boundary"]

            uc_w, uc_h   = 200, 65
            uc_gap       = 30
            pad_x        = 60
            pad_top      = 60
            pad_bot      = 40
            act_w, act_h = 50, 80
            actor_gap    = 80

            n_uc        = len(casos_uso)
            total_uc_h  = n_uc * uc_h + max(0, n_uc - 1) * uc_gap
            bound_w     = uc_w + 2 * pad_x
            bound_h     = total_uc_h + pad_top + pad_bot
            bound_x     = 200
            bound_y     = 30
            uc_x        = bound_x + (bound_w - uc_w) // 2
            uc_block_top = bound_y + pad_top
            uc_center_y  = uc_block_top + total_uc_h // 2
            act_y_start  = uc_center_y - act_h // 2
            act_left_x   = bound_x - actor_gap - act_w
            act_right_x  = bound_x + bound_w + actor_gap

            for frontera in fronteras:
                eid = ids_elementos[frontera["nombre"]]["id"]
                obj = diagrama.DiagramObjects.AddNew(
                    f"l={bound_x};r={bound_x+bound_w};t={-bound_y};b={-(bound_y+bound_h)};", "")
                obj.ElementID = eid
                obj.Update()

            for i, uc in enumerate(casos_uso):
                eid = ids_elementos[uc["nombre"]]["id"]
                y = uc_block_top + i * (uc_h + uc_gap)
                obj = diagrama.DiagramObjects.AddNew(
                    f"l={uc_x};r={uc_x+uc_w};t={-y};b={-(y+uc_h)};", "")
                obj.ElementID = eid
                if "color" in uc:
                    hex_c = uc["color"].lstrip('#')
                    rv, gv, bv = tuple(int(hex_c[j:j+2], 16) for j in (0, 2, 4))
                    obj.Style = f"BCol={(bv << 16) | (gv << 8) | rv};"
                obj.Update()

            for i, actor in enumerate(actores_izq):
                eid = ids_elementos[actor["nombre"]]["id"]
                y = act_y_start + i * (act_h + uc_gap)
                obj = diagrama.DiagramObjects.AddNew(
                    f"l={act_left_x};r={act_left_x+act_w};t={-y};b={-(y+act_h)};", "")
                obj.ElementID = eid
                obj.Update()

            for i, actor in enumerate(actores_der):
                eid = ids_elementos[actor["nombre"]]["id"]
                y = act_y_start + i * (act_h + uc_gap)
                obj = diagrama.DiagramObjects.AddNew(
                    f"l={act_right_x};r={act_right_x+act_w};t={-y};b={-(y+act_h)};", "")
                obj.ElementID = eid
                obj.Update()

        # --- LAYOUT: DEPLOYMENT (posicionamiento personalizado por elemento) ---
        elif es_deployment:
            for item in elementos:
                datos_elem = ids_elementos[item["nombre"]]

                x = item.get("x", 80)
                y = item.get("y", 80)
                w = item.get("w", 150)
                h = item.get("h", 80)

                l = x
                r = x + w
                t = -y
                b = -(y + h)

                obj = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj.ElementID = datos_elem["id"]

                if "color" in item:
                    hex_c = item["color"].lstrip('#')
                    rv, gv, bv = tuple(int(hex_c[j:j+2], 16) for j in (0, 2, 4))
                    obj.Style = f"BCol={(bv << 16) | (gv << 8) | rv};"

                obj.Update()
                print(f"  [{item['nombre']}] -> ({x},{y}) {w}x{h}")

        # --- LAYOUT: GENERICO (Secuencia, Estado, Logico, etc.) ---
        else:
            eje_x = 150
            eje_y = 50
            espacio_x_secuencia = 220
            espacio_y_estado = 130

            for item in elementos:
                datos_elem = ids_elementos[item["nombre"]]

                if "x" in item and "y" in item:
                    # Posicionamiento manual: soportado en cualquier tipo de diagrama
                    w = item.get("w", 120)
                    h = item.get("h", 70)
                    l = item["x"]
                    r = item["x"] + w
                    t = -item["y"]
                    b = -(item["y"] + h)
                else:
                    if datos_elem["es_pequeno"]:
                        w, h = 30, 30
                        offset_x = 45 if es_estado else 0
                        offset_y = 0 if es_estado else 20
                    else:
                        w, h = 120, 70
                        offset_x = 0
                        offset_y = 0

                    t = -(eje_y + offset_y)
                    b = -(eje_y + offset_y + h)
                    l = eje_x + offset_x
                    r = eje_x + offset_x + w

                    if es_secuencia:
                        eje_x += espacio_x_secuencia
                    elif es_estado:
                        eje_y += espacio_y_estado
                    else:
                        eje_x += espacio_x_secuencia
                        if eje_x > 800:
                            eje_x = 150
                            eje_y += espacio_y_estado

                obj_diagrama = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj_diagrama.ElementID = datos_elem["id"]
                if "color" in item:
                    hex_color = item["color"].lstrip('#')
                    rv, gv, bv = tuple(int(hex_color[k:k+2], 16) for k in (0, 2, 4))
                    bgr_color = (bv * 65536) + (gv * 256) + rv
                    obj_diagrama.Style = f"BCol={bgr_color};"
                obj_diagrama.Update()

        # --- COMBINED FRAGMENTS: posicionar en el diagrama con coordenadas del JSON ---
        for frag in datos.get("fragmentos", []):
            clave = frag.get("titulo", "")
            if clave in ids_elementos:
                x = frag.get("x", 100); y = frag.get("y", 200)
                w = frag.get("w", 500); h = frag.get("h", 200)
                frag_id = ids_elementos[clave]["id"]
                frag_obj = diagrama.DiagramObjects.AddNew(f"l={x};r={x+w};t={-y};b={-(y+h)};", "")
                frag_obj.ElementID = frag_id
                frag_obj.Update()
                print(f"  Fragmento en diagrama: [{frag.get('tipo','')}] ({x},{y}) {w}x{h}")

                # NOTA: InteractionOperand no es un tipo válido en EA COM API.
                # Los guards deben agregarse manualmente desde el toolbox de EA.

        # --- CONECTORES COMMUNICATION: se crean DESPUÉS del layout para que EA los vincule al diagrama ---
        if es_comunicacion:
            for rel in relaciones:
                nodo_origen  = ids_elementos.get(rel["origen"])
                nodo_destino = ids_elementos.get(rel["destino"])
                if nodo_origen and nodo_destino:
                    elem_origen = repo.GetElementByID(nodo_origen["id"])
                    conn = elem_origen.Connectors.AddNew(rel.get("nombre", ""), rel["tipo"])
                    conn.SupplierID = nodo_destino["id"]
                    conn.Direction  = "Source -> Destination"
                    conn.Update()
                    print(f"Conexion: {rel['origen']} --({rel['tipo']})--> {rel['destino']}")

        repo.ReloadDiagram(diagrama.DiagramID)

        print("\n¡EXITO TOTAL!")
        print(f"Diagrama '{nombre_diagrama}' renderizado en Enterprise Architect.")

    except Exception as e:
        print(f"Error inesperado en EA: {e}")

if __name__ == "__main__":
    ejecutar_superscript()
