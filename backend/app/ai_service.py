
import httpx

from .query_service import QueryService
from .memory_service import MemoryService


class AIService:

    def __init__(self):

        self.ollama_url = "http://localhost:11434/api/generate"

        self.query_service = QueryService()

        self.memory_service = MemoryService()

    def process_question(self, question, user):

        # guardar mensaje usuario
        self.memory_service.save_message(
            user=user,
            role="user",
            message=question
        )

        # obtener datos relevantes
        patients = self.query_service.find_relevant_patients(question)

        # contexto
        context = self._build_context(patients)

        # historial
        history = self.memory_service.get_recent_history(user)

        # prompt
        prompt = self._build_prompt(
            question,
            context,
            history
        )

        # respuesta IA
        answer = self._call_ollama(prompt)

        # guardar respuesta
        self.memory_service.save_message(
            user=user,
            role="assistant",
            message=answer
        )

        return {
            "answer": answer,
            "patients": patients
        }

    def _build_context(self, patients):

        if not patients:
            return "No hay datos relacionados."

        text = ""

        for p in patients:

            text += f"""
Usuario:
ID: {p['id']}
Nombre: {p['nombre']}
Email: {p['email']}
Glucosa: {p['glucosa']}
Peso: {p['peso']}

"""

        return text

    def _build_prompt(self, question, context, history):

        history_text = ""

        for h in history:

            history_text += f"""
{h['role']}: {h['message']}
"""

        prompt = f"""
Eres un asistente médico especializado en diabetes.

REGLAS:
- SOLO usa datos reales proporcionados.
- NO inventes información.
- Si no hay datos responde claramente.
- Responde de manera breve y clara.

HISTORIAL:
{history_text}

DATOS:
{context}

PREGUNTA:
{question}

RESPUESTA:
"""

        return prompt

    def _call_ollama(self, prompt):

        try:

            with httpx.Client(timeout=120.0) as client:

                response = client.post(
                    self.ollama_url,
                    json={
                        "model": "gemma:2b",
                        "prompt": prompt,
                        "stream": False
                    }
                )

                if response.status_code == 200:
                    return response.json().get("response", "")

                return "Error conectando con Ollama."

        except Exception as e:

            return str(e)