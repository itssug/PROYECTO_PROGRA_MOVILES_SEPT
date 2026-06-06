from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from .ai_service import AIService


class AIChatView(APIView):

    permission_classes = [AllowAny]

    def post(self, request):

        mensaje = request.data.get("message")

        if not mensaje:
            return Response({"error": "Mensaje requerido"}, status=400)

        # ── Resolución de usuario ─────────────────────────────────────────────
        # Cuando implementes auth (JWT/Session), request.user.id estará
        # disponible automáticamente y puedes eliminar este bloque.
        #
        # Por ahora soportamos dos modos:
        #   1. Auth activo  → usa request.user directamente
        #   2. Sin auth     → recibe user_id en el body (temporal para dev)

        if request.user and request.user.is_authenticated:
            user_id = request.user.id
        else:
            # Temporal: Flutter manda user_id en el body mientras no hay auth
            user_id = request.data.get("user_id")
            if not user_id:
                return Response(
                    {"error": "Se requiere user_id (auth no implementado aún)"},
                    status=400,
                )

        # ── Procesamiento ─────────────────────────────────────────────────────
        try:
            ai = AIService()
            resultado = ai.process_question(mensaje, user_id)
            return Response(resultado)

        except Exception as e:
            return Response(
                {"error": f"Error interno: {str(e)}"},
                status=500,
            )