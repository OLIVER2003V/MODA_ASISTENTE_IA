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
        
        # ELIMINAMOS el 'hide time-axis' y agregamos un título de escala
        lineas_puml = [
            "@startuml", 
            "scale 1.5",
            f"caption Escala de tiempo en milisegundos (ms) - {nombre_diagrama}"
        ]
        
        lineas_datos = datos.get("lineas", [])
        
        # 1. Definir Líneas de Tiempo (Lifelines)
        for i, linea in enumerate(lineas_datos):
            alias = f"L{i}"
            lineas_puml.append(f"robust \"{linea['nombre']}\" as {alias}")
        
        lineas_puml.append("")
        
        # 2. Recolectar y ordenar cronológicamente los tiempos
        # 2. Recolectar y ordenar cronológicamente los tiempos
        tiempos_unicos = set()
        for linea in lineas_datos:
            for ev in linea.get("eventos", []):
                tiempos_unicos.add(float(ev["t"])) # <-- Cambiar int por float
        
        # 3. Dibujar los escalones
        # 3. Dibujar los escalones
        for t in sorted(tiempos_unicos):
            lineas_puml.append(f"@{t}")
            for i, linea in enumerate(lineas_datos):
                alias = f"L{i}"
                for ev in linea.get("eventos", []):
                    if float(ev["t"]) == t: # <-- Cambiar int por float
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
    # MOTOR ENTERPRISE ARCHITECT (Secuencia, Estado, etc.)
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
        
        # 1. CREAR ELEMENTOS
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
            
            if subtipo is not None:
                nuevo_elemento.Subtype = subtipo
                
            nuevo_elemento.Update()
            ids_elementos[item["nombre"]] = {
                "id": nuevo_elemento.ElementID,
                "es_pequeno": es_pequeno
            }
            print(f"Elemento creado: {item['nombre']} [{item['tipo']}]")
            
        # 2. CREAR RELACIONES
        es_secuencia = (tipo_diagrama.lower() == "sequence")
        es_estado = (tipo_diagrama.lower() in ["statechart", "state machine", "state"])
        es_caso_uso = (tipo_diagrama.lower() == "use case")

        for rel in relaciones:
            nodo_origen = ids_elementos.get(rel["origen"])
            nodo_destino = ids_elementos.get(rel["destino"])

            if nodo_origen and nodo_destino:
                elemento_origen = repo.GetElementByID(nodo_origen["id"])
                conector = elemento_origen.Connectors.AddNew(rel.get("nombre", ""), rel["tipo"])
                conector.SupplierID = nodo_destino["id"]
                
                if rel["tipo"] == "Dependency":
                        conector.Stereotype = "trace"
                
                if es_secuencia:
                    conector.SequenceNo = relaciones.index(rel) + 1 
                    
                conector.Update()
                print(f"Conexión: {rel['origen']} -- ({rel['tipo']})--> {rel['destino']}")
                
        # 3. MOTOR DE COORDENADAS
        diagrama = paquete_actual.Diagrams.AddNew(nombre_diagrama, tipo_diagrama)
        diagrama.Update()

        if es_caso_uso:
            # --- Layout para Diagramas de Casos de Uso ---
            actores_izq = [e for e in elementos if e["tipo"] == "Actor" and e.get("posicion", "izquierda") == "izquierda"]
            actores_der = [e for e in elementos if e["tipo"] == "Actor" and e.get("posicion") == "derecha"]
            casos_uso   = [e for e in elementos if e["tipo"] == "UseCase"]
            fronteras   = [e for e in elementos if e["tipo"] == "Boundary"]

            uc_w, uc_h   = 200, 65   # tamaño de cada caso de uso
            uc_gap       = 30        # separación vertical entre casos de uso
            pad_x        = 60        # padding horizontal dentro de la frontera
            pad_top      = 60        # espacio superior para el título de la frontera
            pad_bot      = 40        # padding inferior
            act_w, act_h = 50, 80    # tamaño del actor
            actor_gap    = 80        # separación horizontal entre frontera y actor

            n_uc        = len(casos_uso)
            total_uc_h  = n_uc * uc_h + max(0, n_uc - 1) * uc_gap
            bound_w     = uc_w + 2 * pad_x
            bound_h     = total_uc_h + pad_top + pad_bot

            bound_x = 200
            bound_y = 30

            uc_x         = bound_x + (bound_w - uc_w) // 2
            uc_block_top = bound_y + pad_top
            uc_center_y  = uc_block_top + total_uc_h // 2
            act_y_start  = uc_center_y - act_h // 2

            act_left_x  = bound_x - actor_gap - act_w
            act_right_x = bound_x + bound_w + actor_gap

            for frontera in fronteras:
                eid = ids_elementos[frontera["nombre"]]["id"]
                l = bound_x;  r = bound_x + bound_w
                t = -bound_y; b = -(bound_y + bound_h)
                obj = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj.ElementID = eid
                obj.Update()
                print(f"Frontera '{frontera['nombre']}' posicionada.")

            for i, uc in enumerate(casos_uso):
                eid = ids_elementos[uc["nombre"]]["id"]
                y = uc_block_top + i * (uc_h + uc_gap)
                l = uc_x;      r = uc_x + uc_w
                t = -y;        b = -(y + uc_h)
                obj = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj.ElementID = eid
                if "color" in uc:
                    hex_c = uc["color"].lstrip('#')
                    rv, gv, bv = tuple(int(hex_c[j:j+2], 16) for j in (0, 2, 4))
                    obj.Style = f"BCol={(bv << 16) | (gv << 8) | rv};"
                obj.Update()
                print(f"UseCase '{uc['nombre']}' posicionado.")

            for i, actor in enumerate(actores_izq):
                eid = ids_elementos[actor["nombre"]]["id"]
                y = act_y_start + i * (act_h + uc_gap)
                l = act_left_x;  r = act_left_x + act_w
                t = -y;          b = -(y + act_h)
                obj = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj.ElementID = eid
                obj.Update()
                print(f"Actor izquierda '{actor['nombre']}' posicionado.")

            for i, actor in enumerate(actores_der):
                eid = ids_elementos[actor["nombre"]]["id"]
                y = act_y_start + i * (act_h + uc_gap)
                l = act_right_x; r = act_right_x + act_w
                t = -y;          b = -(y + act_h)
                obj = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj.ElementID = eid
                obj.Update()
                print(f"Actor derecha '{actor['nombre']}' posicionado.")

        else:
            # --- Layout genérico (Secuencia, Estado, Lógico, etc.) ---
            eje_x = 150
            eje_y = 50
            espacio_x_secuencia = 220
            espacio_y_estado = 130

            for item in elementos:
                datos_elem = ids_elementos[item["nombre"]]

                if datos_elem["es_pequeno"]:
                    w = 30
                    h = 30
                    offset_x = 45 if es_estado else 0
                    offset_y = 0 if es_estado else 20
                else:
                    w = 120
                    h = 70
                    offset_x = 0
                    offset_y = 0

                t = -(eje_y + offset_y)
                b = -(eje_y + offset_y + h)
                l = eje_x + offset_x
                r = eje_x + offset_x + w

                obj_diagrama = diagrama.DiagramObjects.AddNew(f"l={l};r={r};t={t};b={b};", "")
                obj_diagrama.ElementID = datos_elem["id"]
                if "color" in item:
                    hex_color = item["color"].lstrip('#')
                    rv, gv, bv = tuple(int(hex_color[k:k+2], 16) for k in (0, 2, 4))
                    bgr_color = (bv * 65536) + (gv * 256) + rv
                    obj_diagrama.Style = f"BCol={bgr_color};"
                obj_diagrama.Update()

                if es_secuencia:
                    eje_x += espacio_x_secuencia
                elif es_estado:
                    eje_y += espacio_y_estado
                else:
                    eje_x += espacio_x_secuencia
                    if eje_x > 800:
                        eje_x = 150
                        eje_y += espacio_y_estado

        repo.ReloadDiagram(diagrama.DiagramID)

        print("\n¡ÉXITO TOTAL!")
        print(f"Diagrama '{nombre_diagrama}' renderizado en Enterprise Architect.")
        
    except Exception as e:
        print(f"Error inesperado en EA: {e}")

if __name__ == "__main__":
    ejecutar_superscript()