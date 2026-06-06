import numpy as np
from django.utils import timezone
from core.models import AnalisisGlucosa, PatronesAprendidos, Usuarios

def generar_patrones_usuario(usuario_id):
    """
    Analiza el historial de AnalisisGlucosa de un usuario y actualiza 
    la tabla PatronesAprendidos para cada alimento.
    """
    try:
        usuario = Usuarios.objects.get(id=usuario_id)
    except Usuarios.DoesNotExist:
        return {"error": f"Usuario {usuario_id} no encontrado."}

    # Obtener registros válidos con información de comida y glucosa completa
    registros = AnalisisGlucosa.objects.filter(
        usuario_id=usuario_id,
        registro_comida__isnull=False,
        glucosa_antes__isnull=False,
        glucosa_despues__isnull=False
    ).select_related("registro_comida", "estado_emocional", "sueno")

    # Agrupar por comida_id
    comidas_data = {}
    for r in registros:
        comida_id = r.registro_comida.comida_id
        if not comida_id:
            continue
            
        if comida_id not in comidas_data:
            comidas_data[comida_id] = {
                "comida_obj": r.registro_comida.comida,
                "impactos": [],
                "impactos_estres": [],
                "impactos_sin_dormir": [],
            }
        
        # Calcular el impacto (diferencia real)
        impacto = float(r.glucosa_despues - r.glucosa_antes)
        comidas_data[comida_id]["impactos"].append(impacto)
        
        # Analizar contexto de estrés alto (nivel 4 o 5)
        if r.estado_emocional and r.estado_emocional.nivel_estres >= 4:
            comidas_data[comida_id]["impactos_estres"].append(impacto)
            
        # Analizar contexto de mal sueño (menos de 6 horas)
        if r.sueno and float(r.sueno.horas_dormidas) < 6:
            comidas_data[comida_id]["impactos_sin_dormir"].append(impacto)

    patrones_generados = 0

    for comida_id, data in comidas_data.items():
        impactos = data["impactos"]
        veces = len(impactos)
        
        # Necesitamos un mínimo de datos para que el patrón sea confiable (ej. 3 veces)
        if veces < 3:
            continue
            
        impacto_promedio = np.mean(impactos)
        impacto_maximo = np.max(impactos)
        impacto_minimo = np.min(impactos)
        desviacion_estandar = np.std(impactos)
        
        # Lógica de reglas de asociación condicional
        peor_en_estres = 0
        if len(data["impactos_estres"]) >= 2:
            promedio_estres = np.mean(data["impactos_estres"])
            # Si con estrés el impacto es 15 mg/dL mayor que lo normal
            if promedio_estres > (impacto_promedio + 15):
                peor_en_estres = 1
                
        peor_sin_dormir = 0
        if len(data["impactos_sin_dormir"]) >= 2:
            promedio_sinsueno = np.mean(data["impactos_sin_dormir"])
            if promedio_sinsueno > (impacto_promedio + 15):
                peor_sin_dormir = 1

        # Nivel de confianza basado en la cantidad de registros y la variabilidad
        # Mayor N -> Mayor confianza. Mayor Desviación -> Menor confianza.
        confianza = min(0.99, (veces / 10.0) * (1.0 / (1.0 + (desviacion_estandar/20.0))))
        
        # Clasificar el alimento según el impacto promedio
        clasificacion = "segura"
        if impacto_promedio > 60:
            clasificacion = "evitar"
        elif impacto_promedio > 40:
            clasificacion = "riesgosa"
        elif impacto_promedio > 20:
            clasificacion = "moderada"

        # Actualizar o crear en la base de datos
        PatronesAprendidos.objects.update_or_create(
            usuario=usuario,
            comida=data["comida_obj"],
            defaults={
                "veces_registrada": veces,
                "impacto_promedio": round(impacto_promedio, 2),
                "impacto_maximo": round(impacto_maximo, 2),
                "impacto_minimo": round(impacto_minimo, 2),
                "desviacion_estandar": round(desviacion_estandar, 2),
                "clasificacion": clasificacion,
                "nivel_confianza": round(confianza, 2),
                "peor_en_estres": peor_en_estres,
                "peor_sin_dormir": peor_sin_dormir,
                "mejor_con_ejercicio": 0, # Placeholder para lógica futura
                "mejor_con_medicamento": 0, # Placeholder
                "ultima_actualizacion": timezone.now()
            }
        )
        patrones_generados += 1

    return {"status": "success", "patrones_generados": patrones_generados}
