from rest_framework import viewsets, status
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.response import Response
from core.models import Alertas
from .serializers import AlertasSerializer
from .logic import verificar_y_crear_alerta, generar_resumen_diario, calcular_consumo_hoy


class AlertasViewSet(viewsets.ModelViewSet):
    serializer_class = AlertasSerializer
    permission_classes = [AllowAny]
    authentication_classes = []

    def get_queryset(self):
        usuario_id = self.request.query_params.get('usuario_id')
        qs = Alertas.objects.all()
        if usuario_id:
            qs = qs.filter(usuario_id=usuario_id)
        return qs.order_by('-fecha')


class VerificarAlertasView(APIView):
    """
    Llamar después de registrar una comida.
    POST /api/alertas/verificar/  body: {"usuario_id": 1}
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        usuario_id = request.data.get('usuario_id')
        if not usuario_id:
            return Response({'error': 'usuario_id requerido'},
                          status=status.HTTP_400_BAD_REQUEST)

        nuevas_alertas = verificar_y_crear_alerta(usuario_id)
        serializer = AlertasSerializer(nuevas_alertas, many=True)
        return Response({
            'alertas_generadas': len(nuevas_alertas),
            'alertas': serializer.data,
        })


class ResumenDiarioView(APIView):
    """
    GET /api/alertas/resumen-diario/?usuario_id=1
    Devuelve el consumo de hoy y genera la alerta de resumen si no existe.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        usuario_id = request.query_params.get('usuario_id')
        if not usuario_id:
            return Response({'error': 'usuario_id requerido'},
                          status=status.HTTP_400_BAD_REQUEST)

        consumo = calcular_consumo_hoy(usuario_id)
        generar_resumen_diario(usuario_id)

        from .logic import LIMITE_CARBOHIDRATOS_DIA, LIMITE_AZUCARES_DIA
        return Response({
            'carbohidratos_consumidos': consumo['carbohidratos'],
            'carbohidratos_limite': LIMITE_CARBOHIDRATOS_DIA,
            'carbohidratos_porcentaje': round(
                (consumo['carbohidratos'] / LIMITE_CARBOHIDRATOS_DIA) * 100, 1),
            'azucares_consumidos': consumo['azucares'],
            'azucares_limite': LIMITE_AZUCARES_DIA,
            'azucares_porcentaje': round(
                (consumo['azucares'] / LIMITE_AZUCARES_DIA) * 100, 1),
        })