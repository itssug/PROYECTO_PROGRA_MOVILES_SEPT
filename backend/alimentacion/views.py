from decimal import Decimal
from django.db.models import Sum, Count, Q
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from core.models import Comidas, RegistroComidas, Usuarios
from core.token_model import TokenUsuario
from .serializers import (
    ComidaSerializer,
    ComidaCreateSerializer,
    RegistroComidaSerializer,
    RegistroComidaCreateSerializer,
)


# ── Helper: obtener usuario desde el token ────────────────
def obtener_usuario(request):
    """Extrae el usuario del header Authorization: Token <key>."""
    auth = request.headers.get('Authorization', '')
    key = auth.replace('Token ', '').strip()
    if not key:
        return None
    try:
        token_obj = TokenUsuario.objects.get(key=key)
        return Usuarios.objects.get(id=token_obj.usuario_id)
    except (TokenUsuario.DoesNotExist, Usuarios.DoesNotExist):
        return None


# ── 1. CATÁLOGO DE COMIDAS ────────────────────────────────
class ComidasListView(APIView):
    """
    GET  /api/alimentacion/comidas/               → listar todo
    GET  /api/alimentacion/comidas/?buscar=avena   → buscar por nombre
    GET  /api/alimentacion/comidas/?categoria=frutas → filtrar por categoría
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        qs = Comidas.objects.all()

        buscar = request.query_params.get('buscar')
        if buscar:
            qs = qs.filter(nombre__icontains=buscar)

        categoria = request.query_params.get('categoria')
        if categoria:
            qs = qs.filter(categoria__iexact=categoria)

        qs = qs.order_by('nombre')
        serializer = ComidaSerializer(qs, many=True)
        return Response(serializer.data)


class ComidaCreateView(APIView):
    """
    POST /api/alimentacion/comidas/crear/  → crear alimento personalizado
    Body: { nombre, categoria, calorias, carbohidratos, ... }
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        usuario = obtener_usuario(request)
        if not usuario:
            return Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        serializer = ComidaCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        comida = Comidas.objects.create(
            **serializer.validated_data,
            es_personalizado=1,
            usuario_id=usuario.id,
        )
        return Response(
            ComidaSerializer(comida).data,
            status=status.HTTP_201_CREATED,
        )


# ── 2. REGISTRO DE COMIDAS (lo que el usuario comió) ──────
class RegistroComidaListView(APIView):
    """
    GET /api/alimentacion/registro/?fecha=2026-06-06
    Devuelve los registros de comida del usuario para esa fecha.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        usuario = obtener_usuario(request)
        if not usuario:
            return Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        fecha = request.query_params.get('fecha')
        qs = RegistroComidas.objects.filter(
            usuario_id=usuario.id,
        ).select_related('comida').order_by('hora')

        if fecha:
            qs = qs.filter(fecha=fecha)

        serializer = RegistroComidaSerializer(qs, many=True)
        return Response(serializer.data)

    def post(self, request):
        """
        POST /api/alimentacion/registro/
        Body: { comida_id, cantidad, tipo_comida, fecha, hora, unidad?, notas? }
        Calcula automáticamente calorías, carbohidratos, etc.
        """
        usuario = obtener_usuario(request)
        if not usuario:
            return Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        serializer = RegistroComidaCreateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        comida = Comidas.objects.get(id=data['comida_id'])

        # Calcular macronutrientes proporcionales
        porcion = comida.porcion_tipica or Decimal('100')
        cantidad = Decimal(str(data['cantidad']))
        factor = cantidad / porcion

        registro = RegistroComidas.objects.create(
            usuario_id=usuario.id,
            comida_id=comida.id,
            cantidad=data['cantidad'],
            unidad=data.get('unidad', comida.unidad_medida or 'gramos'),
            tipo_comida=data['tipo_comida'],
            fecha=data['fecha'],
            hora=data['hora'],
            calorias_calculadas=(comida.calorias or 0) * factor,
            carbohidratos_calculados=(comida.carbohidratos or 0) * factor,
            azucares_calculados=(comida.azucares or 0) * factor,
            carga_glucemica_calc=(comida.carga_glucemica or 0) * factor,
            notas=data.get('notas'),
        )

        return Response(
            RegistroComidaSerializer(registro).data,
            status=status.HTTP_201_CREATED,
        )


class RegistroComidaDeleteView(APIView):
    """DELETE /api/alimentacion/registro/<id>/"""
    permission_classes = [AllowAny]
    authentication_classes = []

    def delete(self, request, pk):
        usuario = obtener_usuario(request)
        if not usuario:
            return Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        try:
            registro = RegistroComidas.objects.get(id=pk, usuario_id=usuario.id)
        except RegistroComidas.DoesNotExist:
            return Response(
                {"error": "Registro no encontrado."},
                status=status.HTTP_404_NOT_FOUND,
            )

        registro.delete()
        return Response(
            {"mensaje": "Registro eliminado."},
            status=status.HTTP_200_OK,
        )


# ── 3. RESUMEN DIARIO ────────────────────────────────────
class ResumenDiarioView(APIView):
    """
    GET /api/alimentacion/resumen/?fecha=2026-06-06
    Devuelve totales de calorías, carbohidratos, azúcares, etc.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        usuario = obtener_usuario(request)
        if not usuario:
            return Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        from datetime import date
        fecha = request.query_params.get('fecha', str(date.today()))

        registros = RegistroComidas.objects.filter(
            usuario_id=usuario.id,
            fecha=fecha,
        )

        totales = registros.aggregate(
            total_calorias=Sum('calorias_calculadas'),
            total_carbohidratos=Sum('carbohidratos_calculados'),
            total_azucares=Sum('azucares_calculados'),
            total_carga_glucemica=Sum('carga_glucemica_calc'),
            cantidad_registros=Count('id'),
        )

        # Calorías por tipo de comida
        por_tipo = {}
        tipos = registros.values('tipo_comida').annotate(
            cal=Sum('calorias_calculadas')
        )
        for t in tipos:
            por_tipo[t['tipo_comida']] = float(t['cal'] or 0)

        return Response({
            "fecha": fecha,
            "total_calorias": float(totales['total_calorias'] or 0),
            "total_carbohidratos": float(totales['total_carbohidratos'] or 0),
            "total_azucares": float(totales['total_azucares'] or 0),
            "total_carga_glucemica": float(totales['total_carga_glucemica'] or 0),
            "cantidad_registros": totales['cantidad_registros'] or 0,
            "por_tipo_comida": por_tipo,
        })