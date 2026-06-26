from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from core.models import EstadoEmocional, RegistroSueno
from .serializers import EstadoEmocionalSerializer, RegistroSuenoSerializer

class EstadoEmocionalViewSet(viewsets.ModelViewSet):
    serializer_class = EstadoEmocionalSerializer

    def get_queryset(self):
        usuario_id = self.request.query_params.get('usuario_id')
        qs = EstadoEmocional.objects.all()
        if usuario_id:
            qs = qs.filter(usuario_id=usuario_id)
        return qs.order_by('-fecha', '-hora')

class RegistroSuenoViewSet(viewsets.ModelViewSet):
    serializer_class = RegistroSuenoSerializer

    def get_queryset(self):
        usuario_id = self.request.query_params.get('usuario_id')
        qs = RegistroSueno.objects.all()
        if usuario_id:
            qs = qs.filter(usuario_id=usuario_id)
        return qs.order_by('-fecha')
    
    # ── Agrega este método para ver el error exacto ──
    def create(self, request, *args, **kwargs):
        print("DATA RECIBIDA:", request.data)  # ← verás esto en la terminal
        serializer = self.get_serializer(data=request.data)
        if not serializer.is_valid():
            print("ERRORES:", serializer.errors)  # ← aquí está el problema
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)