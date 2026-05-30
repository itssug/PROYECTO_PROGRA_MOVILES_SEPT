from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

import requests

# IMPORTAR MODELOS
from core.models import Usuarios, Glucosa, RegistroComidas


class AIChatView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        return Response({
            "status": "API funcionando"
        })

    def post(self, request):

        try:
            mensaje = request.data.get("message", "").lower()

            if not mensaje:
                return Response({
                    "error": "Debes enviar un mensaje"
                }, status=400)

            contexto_bd = ""

            # =========================
            # CONSULTAS A LA BD
            # =========================

            # TOTAL USUARIOS
            if "usuarios" in mensaje:
                total = Usuarios.objects.count()

                contexto_bd += f"""
                En la base de datos existen {total} usuarios registrados.
                """

            # ÚLTIMAS GLUCOSAS
            if "glucosa" in mensaje:

                glucosas = Glucosa.objects.all().order_by('-fecha')[:5]

                texto_glucosa = ""

                for g in glucosas:
                    texto_glucosa += f"""
                    Usuario: {g.usuario.nombre}
                    Nivel glucosa: {g.nivel_glucosa}
                    Fecha: {g.fecha}
                    """

                contexto_bd += texto_glucosa

            # COMIDAS
            if "comida" in mensaje or "comidas" in mensaje:

                comidas = RegistroComidas.objects.select_related('comida').all()[:5]

                texto_comidas = ""

                for c in comidas:
                    texto_comidas += f"""
                    Usuario: {c.usuario.nombre}
                    Comida: {c.comida.nombre}
                    Cantidad: {c.cantidad}
                    """

                contexto_bd += texto_comidas

            # =========================
            # PROMPT FINAL
            # =========================

            prompt = f"""
            Eres un asistente médico para diabetes.

            Información obtenida de la base de datos:
            {contexto_bd}

            Pregunta del usuario:
            {mensaje}
            """

            response = requests.post(
                "http://localhost:11434/api/generate",
                json={
                    "model": "gemma:2b",
                    "prompt": prompt,
                    "stream": False
                }
            )

            data = response.json()

            return Response({
                "pregunta": mensaje,
                "contexto_bd": contexto_bd,
                "respuesta": data.get("response", "Sin respuesta")
            })

        except Exception as e:
            return Response({
                "error": str(e)
            }, status=500)