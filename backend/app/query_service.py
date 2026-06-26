import os
from datetime import date, timedelta
from django.conf import settings
from core.models import Usuarios, Glucosa, Objetivos, ResumenDiario, RegistroComidas


class QueryService:

    def get_user_context(self, user_id: int) -> dict:
        """
        Trae el contexto completo de glucosa del usuario.
        No filtra por palabras — siempre carga los datos, Gemini decide qué usar.
        """
        try:
            user = Usuarios.objects.get(id=user_id)
        except Usuarios.DoesNotExist:
            return {"error": f"Usuario {user_id} no encontrado"}

        return {
            "perfil":        self._get_perfil(user),
            "ultima_glucosa": self._get_ultima_glucosa(user),
            "glucosa_hoy":   self._get_glucosa_hoy(user),
            "glucosa_semana": self._get_glucosa_semana(user),
            "resumen_semana": self._get_resumen_semana(user),
            "glucosa_global": self._get_glucosa_global(user),
            "objetivos":     self._get_objetivos(user),
            "consumos_hoy":  self._get_consumos_hoy(user),
            "modelo_prediccion": self._get_modelo_prediccion(user),
        }

    # ── Sistema ML ────────────────────────────────────────────────────────────

    def _get_modelo_prediccion(self, user) -> str:
        ruta_usuario = os.path.join(
            settings.BASE_DIR,
            "media",
            "models",
            f"user_{user.id}_rf.joblib"
        )
        if os.path.exists(ruta_usuario):
            return "Personalizado (Entrenado con tus propios datos)"
        else:
            return "Global (Modelo general por defecto)"

    # ── Perfil básico ─────────────────────────────────────────────────────────

    def _get_perfil(self, user) -> dict:
        return {
            "nombre":            user.nombre,
            "anios_diagnostico": user.anios_diagnostico,
            "usa_insulina":      bool(user.usa_insulina),
            "nivel_actividad":   user.nivel_actividad_base,
            "hba1c_inicial":     str(user.hba1c_inicial) if user.hba1c_inicial else None,
        }

    # ── Glucosa de hoy ────────────────────────────────────────────────────────

    def _get_glucosa_hoy(self, user) -> list:
        registros = (
            Glucosa.objects
            .filter(usuario=user, fecha=date.today())
            .order_by("hora")
        )
        return [
            {
                "hora":          str(r.hora),
                "nivel":         str(r.nivel_glucosa),
                "tipo_medicion": r.tipo_medicion,
                "clasificacion": r.clasificacion,
            }
            for r in registros
        ]

    # ── Última glucosa registrada ─────────────────────────────────────────────

    def _get_ultima_glucosa(self, user) -> dict:
        r = Glucosa.objects.filter(usuario=user).order_by("-fecha", "-hora").first()
        if not r:
            return {}
        return {
            "fecha":         str(r.fecha),
            "hora":          str(r.hora),
            "nivel":         str(r.nivel_glucosa),
            "tipo_medicion": r.tipo_medicion,
            "clasificacion": r.clasificacion,
        }

    # ── Consumos de hoy ───────────────────────────────────────────────────────

    def _get_consumos_hoy(self, user) -> dict:
        comidas = RegistroComidas.objects.filter(usuario=user, fecha=date.today())
        calorias = sum([float(c.calorias_calculadas or 0) for c in comidas])
        carbohidratos = sum([float(c.carbohidratos_calculados or 0) for c in comidas])
        return {
            "calorias": round(calorias, 2),
            "carbohidratos": round(carbohidratos, 2),
            "total_comidas": comidas.count()
        }

    # ── Últimos 7 días ────────────────────────────────────────────────────────

    def _get_glucosa_semana(self, user) -> dict:
        hace_7_dias = date.today() - timedelta(days=7)
        registros = Glucosa.objects.filter(
            usuario=user,
            fecha__gte=hace_7_dias,
        )

        if not registros.exists():
            return {}

        niveles = [float(r.nivel_glucosa) for r in registros]

        return {
            "promedio":      round(sum(niveles) / len(niveles), 1),
            "maximo":        max(niveles),
            "minimo":        min(niveles),
            "total_mediciones": len(niveles),
            "fuera_de_rango": sum(1 for n in niveles if n > 180 or n < 70),
        }

    # ── Resumen diario (últimos 7 días) ───────────────────────────────────────

    def _get_resumen_semana(self, user) -> list:
        hace_7_dias = date.today() - timedelta(days=7)
        resumenes = (
            ResumenDiario.objects
            .filter(usuario=user, fecha__gte=hace_7_dias)
            .order_by("-fecha")
        )
        return [
            {
                "fecha":            str(r.fecha),
                "glucosa_promedio": str(r.glucosa_promedio),
                "glucosa_max":      str(r.glucosa_max),
                "glucosa_min":      str(r.glucosa_min),
                "tiempo_en_rango":  str(r.tiempo_en_rango),
            }
            for r in resumenes
        ]

    # ── Objetivos activos ─────────────────────────────────────────────────────

    def _get_objetivos(self, user) -> dict:
        obj = Objetivos.objects.filter(usuario=user, activo=1).first()
        if not obj:
            return {}
        return {
            "glucosa_ayunas_min": str(obj.glucosa_ayunas_min),
            "glucosa_ayunas_max": str(obj.glucosa_ayunas_max),
            "glucosa_post_min":   str(obj.glucosa_post_min),
            "glucosa_post_max":   str(obj.glucosa_post_max),
            "hba1c_objetivo":     str(obj.hba1c_objetivo) if obj.hba1c_objetivo else None,
        }
    def _get_glucosa_global(self, user) -> dict:
        registros = Glucosa.objects.filter(usuario=user)
        if not registros.exists():
            return {}

        niveles = [float(r.nivel_glucosa) for r in registros]

        return {
            "promedio":      round(sum(niveles) / len(niveles), 1),
            "maximo":        max(niveles),
            "minimo":        min(niveles),
            "total_mediciones": len(niveles),
            "fuera_de_rango": sum(1 for n in niveles if n > 180 or n < 70),
        }