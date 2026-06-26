import pandas as pd

from core.models import AnalisisGlucosa


class DatasetBuilder:

    def construir_dataset(self, usuario_id):

        dataset = []

        registros = AnalisisGlucosa.objects.filter(usuario_id=usuario_id).select_related(
            "registro_comida",
            "sueno",
            "estado_emocional",
            "actividad"
        )

        for r in registros:

            # Manejo de nulos por si alguna relacion no existe
            carbos = r.registro_comida.carbohidratos_calculados if r.registro_comida else 0
            cg = r.registro_comida.carga_glucemica_calc if r.registro_comida else 0
            horas_sueno = r.sueno.horas_dormidas if r.sueno else 8
            estres = r.estado_emocional.nivel_estres if r.estado_emocional else 1
            ejercicio = r.actividad.duracion if r.actividad else 0

            dataset.append({
                "glucosa_antes": r.glucosa_antes,
                "carbohidratos": carbos,
                "carga_glucemica": cg,
                "horas_sueno": horas_sueno,
                "estres": estres,
                "ejercicio": ejercicio,
                "medicamento_tomado": getattr(r, 'medicamento_tomado', 0),
                "glucosa_despues": r.glucosa_despues
            })

        return pd.DataFrame(dataset)

    def construir_dataset_global(self):

        dataset = []

        registros = AnalisisGlucosa.objects.all().select_related(
            "registro_comida",
            "sueno",
            "estado_emocional",
            "actividad"
        )

        for r in registros:

            carbos = r.registro_comida.carbohidratos_calculados if r.registro_comida else 0
            cg = r.registro_comida.carga_glucemica_calc if r.registro_comida else 0
            horas_sueno = r.sueno.horas_dormidas if r.sueno else 8
            estres = r.estado_emocional.nivel_estres if r.estado_emocional else 1
            ejercicio = r.actividad.duracion if r.actividad else 0

            dataset.append({
                "glucosa_antes": r.glucosa_antes,
                "carbohidratos": carbos,
                "carga_glucemica": cg,
                "horas_sueno": horas_sueno,
                "estres": estres,
                "ejercicio": ejercicio,
                "medicamento_tomado": getattr(r, 'medicamento_tomado', 0),
                "glucosa_despues": r.glucosa_despues
            })

        return pd.DataFrame(dataset)