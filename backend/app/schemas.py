import httpx
from sqlalchemy.orm import Session
from . import crud


class AIService:

    def __init__(self):
        self.ollama_url = "http://localhost:11434/api/generate"

    def analyze_question(self, question: str, db: Session):

        # Obtener pacientes
        patients = crud.get_patients(db, limit=500)

        # Construir contexto médico
        context = self._build_context(patients)

    
        prompt = f"""
Eres un asistente médico especializado en diabetes.

REGLAS:
- SOLO usa información REAL de la base de datos.
- NO inventes pacientes.
- Si no hay coincidencias responde:
  "No se encontraron registros relacionados."
- Analiza factores de riesgo como:
  glucosa, IMC, presión arterial, insulina y antecedentes.

PREGUNTA:
{question}

DATOS REALES:
{context}

RESPONDE:
"""

        # IA
        response = self._call_ollama(prompt)

        # Coincidencias
        matched_records = self._find_matches(question, patients)

        return {
            "answer": response,
            "matched_records": matched_records
        }

    # ==================================================
    # CONTEXTO
    # ==================================================
    def _build_context(self, patients):

        if not patients:
            return "No hay pacientes registrados."

        context = []

        for p in patients:

            info = f"""
Paciente ID {p.id}
Nombre: {p.name}
Edad: {p.age}
Género: {p.gender}
IMC: {p.bmi}
Glucosa: {p.glucose}
Presión arterial: {p.blood_pressure}
Insulina: {p.insulin}
Antecedentes familiares: {p.family_history}
Predicción diabetes: {p.prediction}
Probabilidad: {p.probability}
Nivel de riesgo: {p.risk_level}
"""

            context.append(info)

        return "\n".join(context)

    # ==================================================
    # OLLAMA
    # ==================================================
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
                    return response.json().get("response", "Error IA")

                return "Error conectando con IA"

        except Exception as e:
            return f"Error: {str(e)}"

    # ==================================================
    # FILTRO DE COINCIDENCIAS
    # ==================================================
    def _find_matches(self, question, patients):

        matches = []

        question_lower = question.lower()

        for p in patients:

            search_text = f"""
            {p.name}
            {p.gender}
            {p.age}
            {p.glucose}
            {p.bmi}
            {p.risk_level}
            """.lower()

            keywords = question_lower.split()

            if any(keyword in search_text for keyword in keywords if len(keyword) > 3):

                matches.append({
                    "id": p.id,
                    "name": p.name,
                    "age": p.age,
                    "gender": p.gender,
                    "glucose": p.glucose,
                    "bmi": p.bmi,
                    "prediction": p.prediction,
                    "risk_level": p.risk_level
                })

        return matches[:5]