import os
from google import genai
from .query_service import QueryService
from .memory_service import MemoryService
from openai import OpenAI


class AIService:

    def __init__(self):
        self.client = OpenAI(
            api_key="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",
            base_url="https://api.groq.com/openai/v1"
        )

        self.query_service = QueryService()
        self.memory_service = MemoryService()

    def process_question(self, question: str, user_id: int) -> dict:

        self.memory_service.save_message(user_id=user_id, role="user", message=question)

        # Siempre trae el contexto del usuario, sin importar qué preguntó
        context_data = self.query_service.get_user_context(user_id)

        history = self.memory_service.get_recent_history(user_id)
        prompt  = self._build_prompt(question, context_data, history)
        answer  = self._call_ai(prompt)

        self.memory_service.save_message(user_id=user_id, role="assistant", message=answer)

        return {"answer": answer}

    def _build_prompt(self, question: str, context: dict, history: list) -> str:
        history_text = "\n".join(
            f"{h['role'].upper()}: {h['message']}" for h in history
        ) or "Sin historial previo."

        perfil    = context.get("perfil", {})
        ultima_g  = context.get("ultima_glucosa", {})
        g_hoy     = context.get("glucosa_hoy", [])
        g_semana  = context.get("glucosa_semana", {})
        g_global  = context.get("glucosa_global", {})
        objetivos = context.get("objetivos", {})
        consumos  = context.get("consumos_hoy", {})
        modelo_ml = context.get("modelo_prediccion", "Desconocido")

        if g_hoy:
            glucosa_hoy_text = "\n".join(
                f"  - {r['hora']} → {r['nivel']} mg/dL ({r['tipo_medicion']}, {r['clasificacion']})"
                for r in g_hoy
            )
        else:
            glucosa_hoy_text = "  Sin mediciones registradas hoy."

        if g_semana:
            semana_text = (
                f"  Promedio: {g_semana['promedio']} mg/dL | "
                f"Máx: {g_semana['maximo']} | "
                f"Mín: {g_semana['minimo']} | "
                f"Mediciones: {g_semana['total_mediciones']} | "
                f"Fuera de rango: {g_semana['fuera_de_rango']}"
            )
        else:
            semana_text = "  Sin datos de la última semana."

        if objetivos:
            obj_text = (
                f"  Glucosa en ayunas: {objetivos['glucosa_ayunas_min']}–{objetivos['glucosa_ayunas_max']} mg/dL\n"
                f"  Glucosa postprandial: {objetivos['glucosa_post_min']}–{objetivos['glucosa_post_max']} mg/dL"
            )
        else:
            obj_text = "  Sin objetivos definidos."
        
        if g_global:
            global_text = (
                f"  Promedio total: {g_global['promedio']} mg/dL | "
                f"Máx total: {g_global['maximo']} | "
                f"Mín total: {g_global['minimo']} | "
                f"Mediciones totales: {g_global['total_mediciones']} | "
                f"Fuera de rango total: {g_global['fuera_de_rango']}"
            )
        else:
            global_text = "  Sin datos históricos suficientes."

        if ultima_g:
            ultima_g_text = f"  Nivel: {ultima_g['nivel']} mg/dL | Fecha: {ultima_g['fecha']} {ultima_g['hora']} | Tipo: {ultima_g['tipo_medicion']}"
        else:
            ultima_g_text = "  Sin mediciones registradas."

        if consumos:
            consumos_text = f"  Calorías: {consumos['calorias']} kcal | Carbohidratos: {consumos['carbohidratos']} g | Comidas registradas: {consumos['total_comidas']}"
        else:
            consumos_text = "  Sin alimentos registrados hoy."

        return f"""Eres un asistente médico especializado en diabetes tipo II.
Estás hablando directamente con el paciente. Usa sus datos reales para responder.

REGLAS:
- Usa SOLO los datos proporcionados, nunca inventes valores.
- Si no hay datos suficientes para responder, dilo claramente.
- Sé breve, cálido y útil. Responde siempre en español.
- Si el usuario saluda o hace preguntas generales, responde normalmente usando su nombre.
- Si pregunta sobre sus niveles, usa los datos reales de abajo.

PERFIL DEL PACIENTE:
  Nombre: {perfil.get('nombre', 'Usuario')}
  Años con diagnóstico: {perfil.get('anios_diagnostico', 'N/A')}
  Usa insulina: {'Sí' if perfil.get('usa_insulina') else 'No'}
  Nivel de actividad: {perfil.get('nivel_actividad', 'N/A')}
  HbA1c inicial: {perfil.get('hba1c_inicial', 'N/A')}

ÚLTIMA GLUCOSA REGISTRADA:
{ultima_g_text}

GLUCOSA DE HOY:
{glucosa_hoy_text}

CONSUMO DE ALIMENTOS DE HOY:
{consumos_text}

RESUMEN ÚLTIMOS 7 DÍAS:
{semana_text}

GLUCOSA GLOBAL:
{global_text}

OBJETIVOS DE GLUCOSA:
{obj_text}

SISTEMA DE PREDICCIÓN ML (MACHINE LEARNING):
Actualmente, para las predicciones de glucosa de este paciente se está utilizando el modelo: {modelo_ml}.
(Nota importante para ti como asistente: El sistema cuenta con 2 modelos: el Global para pacientes nuevos y el Personalizado para pacientes con suficientes datos. Menciónale al usuario cuál se está usando y por qué si pregunta por las predicciones o sobre la Inteligencia Artificial).

HISTORIAL DE CONVERSACIÓN:
{history_text}

PREGUNTA DEL PACIENTE:
{question}
"""

    def _call_gemini(self, prompt: str) -> str:
        try:
            response = self.client.models.generate_content(
                model="gemini-2.0-flash",
                contents=prompt,
            )
            return response.text
        except Exception as e:
            return f"Error al contactar con la IA: {str(e)}"
    def _call_ai(self, prompt: str) -> str:

        try:

            response = self.client.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=[
                    {
                        "role": "system",
                        "content": "Eres un asistente especializado en diabetes tipo II."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                temperature=0.7,
                max_tokens=500
            )

            return response.choices[0].message.content

        except Exception as e:
            return f"Error al contactar con la IA: {str(e)}"