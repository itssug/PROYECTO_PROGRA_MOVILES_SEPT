import os
from google import genai
from .query_service import QueryService
from .memory_service import MemoryService


class AIService:

    def __init__(self):
        self.client = genai.Client(
            api_key=""  # ← nunca hardcodear la key
        )
        self.query_service = QueryService()
        self.memory_service = MemoryService()

    def process_question(self, question: str, user_id: int) -> dict:
        """
        Recibe user_id (int) en vez del objeto User de Django,
        así funciona con y sin autenticación.
        """

        # Guardar mensaje del usuario
        self.memory_service.save_message(
            user_id=user_id,
            role="user",
            message=question,
        )

        # Datos relevantes del paciente
        patients = self.query_service.find_relevant_patients(question)

        # Construir prompt
        context = self._build_context(patients)
        history = self.memory_service.get_recent_history(user_id)
        prompt  = self._build_prompt(question, context, history)

        # Llamar a Gemini
        answer = self._call_gemini(prompt)

        # Guardar respuesta
        self.memory_service.save_message(
            user_id=user_id,
            role="assistant",
            message=answer,
        )

        # ← "answer" (no "respuesta") para que Flutter lo lea correctamente
        return {
            "answer": answer,
            "patients": patients,
        }

    # ── Helpers ───────────────────────────────────────────────────────────────

    def _build_context(self, patients: list) -> str:
        if not patients:
            return "No hay datos relacionados."

        lines = []
        for p in patients:
            lines.append(
                f"ID: {p['id']} | Nombre: {p['nombre']} | "
                f"Glucosa: {p['glucosa']} mg/dL | Peso: {p['peso']} kg"
            )
        return "\n".join(lines)

    def _build_prompt(self, question: str, context: str, history: list) -> str:
        history_text = "\n".join(
            f"{h['role'].upper()}: {h['message']}" for h in history
        )

        return f"""Eres un asistente especializado en diabetes tipo II.

REGLAS:
- SOLO usa los datos proporcionados.
- NO inventes información médica.
- Si faltan datos, dilo claramente.
- Responde de forma breve, clara y útil.
- Responde siempre en español.

HISTORIAL RECIENTE:
{history_text or "Sin historial previo."}

DATOS DEL PACIENTE:
{context}

PREGUNTA:
{question}
"""

    def _call_gemini(self, prompt: str) -> str:
        try:
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
            )
            return response.text
        except Exception as e:
            return f"Error al contactar con la IA: {str(e)}"