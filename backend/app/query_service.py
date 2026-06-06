
from core.models import Usuarios, Glucosa, HistorialPeso


class QueryService:

    def find_relevant_patients(self, question):

        question = question.lower()

        users = Usuarios.objects.all()[:10]

        results = []

        for user in users:

            latest_glucose = Glucosa.objects.filter(
                usuario=user
            ).order_by("-fecha", "-hora").first()

            latest_weight = HistorialPeso.objects.filter(
                usuario=user
            ).order_by("-fecha").first()

            user_data = {
                "id": user.id,
                "nombre": user.nombre,
                "email": user.email,
                "glucosa": latest_glucose.nivel_glucosa if latest_glucose else None,
                "peso": latest_weight.peso if latest_weight else None,
            }

            searchable_text = f"""
            {user.nombre}
            {user.email}
            {user_data['glucosa']}
            {user_data['peso']}
            """.lower()

            if any(word in searchable_text for word in question.split()):
                results.append(user_data)

        return results