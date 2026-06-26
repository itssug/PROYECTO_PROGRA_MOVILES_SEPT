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
    RegistroComidaUpdateSerializer,  # ← NUEVO
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
    """
    PUT    /api/alimentacion/registro/<id>/  → editar registro  ← NUEVO
    DELETE /api/alimentacion/registro/<id>/  → eliminar registro
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def _get_registro(self, request, pk):
        """Helper: obtiene usuario y registro, o devuelve error."""
        usuario = obtener_usuario(request)
        if not usuario:
            return None, None, Response(
                {"error": "Token inválido."},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        try:
            registro = RegistroComidas.objects.select_related('comida').get(
                id=pk, usuario_id=usuario.id,
            )
            return usuario, registro, None
        except RegistroComidas.DoesNotExist:
            return usuario, None, Response(
                {"error": "Registro no encontrado."},
                status=status.HTTP_404_NOT_FOUND,
            )

    # ── NUEVO: Editar un registro ──────────────────────────
    def put(self, request, pk):
        usuario, registro, error = self._get_registro(request, pk)
        if error:
            return error

        serializer = RegistroComidaUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data

        # Si cambió la cantidad → recalcular valores nutricionales
        if 'cantidad' in data:
            registro.cantidad = data['cantidad']
            comida = registro.comida
            porcion = comida.porcion_tipica or Decimal('100')
            factor = Decimal(str(data['cantidad'])) / porcion
            registro.calorias_calculadas = (comida.calorias or 0) * factor
            registro.carbohidratos_calculados = (comida.carbohidratos or 0) * factor
            registro.azucares_calculados = (comida.azucares or 0) * factor
            registro.carga_glucemica_calc = (comida.carga_glucemica or 0) * factor

        if 'tipo_comida' in data:
            registro.tipo_comida = data['tipo_comida']
        if 'hora' in data:
            registro.hora = data['hora']
        if 'unidad' in data:
            registro.unidad = data['unidad']
        if 'notas' in data:
            registro.notas = data['notas']

        registro.save()
        return Response(
            RegistroComidaSerializer(registro).data,
            status=status.HTTP_200_OK,
        )

    def delete(self, request, pk):
        _, registro, error = self._get_registro(request, pk)
        if error:
            return error

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


class ResumenHistoricoView(APIView):
    """
    GET /api/alimentacion/historico/?dias=7
    Devuelve los datos de los últimos X días y la meta de calorías del usuario.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        usuario = obtener_usuario(request)
        if not usuario:
            return Response({"error": "Token inválido."}, status=status.HTTP_401_UNAUTHORIZED)

        from datetime import date, timedelta
        from core.models import Objetivos

        dias = int(request.query_params.get('dias', 7))
        hoy = date.today()
        fecha_inicio = hoy - timedelta(days=dias - 1)

        # 1. Obtener la meta real del usuario de la tabla `objetivos`
        objetivo_activo = Objetivos.objects.filter(usuario_id=usuario.id, activo=1).first()
        meta_calorias = float(objetivo_activo.calorias_diarias) if objetivo_activo and objetivo_activo.calorias_diarias else 1800.0

        # 2. Traer registros de la última semana
        registros = RegistroComidas.objects.filter(
            usuario_id=usuario.id,
            fecha__range=[fecha_inicio, hoy]
        ).select_related('comida')

        # 3. Preparar diccionario de días
        historial = {
            (fecha_inicio + timedelta(days=i)).strftime('%Y-%m-%d'): {
                'calorias': 0, 'carbos': 0, 'proteinas': 0, 'grasas': 0
            } for i in range(dias)
        }

        # 4. Sumar la data
        for r in registros:
            fecha_str = r.fecha.strftime('%Y-%m-%d')
            if fecha_str in historial:
                historial[fecha_str]['calorias'] += float(r.calorias_calculadas or 0)
                historial[fecha_str]['carbos'] += float(r.carbohidratos_calculados or 0)

                porcion = float(r.comida.porcion_tipica or 100)
                factor = float(r.cantidad) / porcion if porcion > 0 else 0
                historial[fecha_str]['proteinas'] += float(r.comida.proteinas or 0) * factor
                historial[fecha_str]['grasas'] += float(r.comida.grasas or 0) * factor

        # Formatear la salida
        datos_dias = [{"fecha": f, **datos} for f, datos in historial.items()]

        return Response({
            "meta_calorias_diarias": meta_calorias,
            "historial": datos_dias
        }, status=status.HTTP_200_OK)


class DietasCatologoView(APIView):
    """
    GET /api/alimentacion/dietas/
    Sirve el catálogo de dietas de forma estática.
    """
    permission_classes = [AllowAny]
    authentication_classes = []

    def get(self, request):
        dietas = [
            {
                "id": "d1",
                "name": "Estilo de Vida Mediterráneo",
                "description": "Rica en grasas saludables, granos enteros y proteínas magras. Ideal para la salud del corazón.",
                "goal": "Salud Cardíaca & Mantenimiento",
                "calories": 2000,
                "proteinGrams": 90, "proteinPercent": 20,
                "carbsGrams": 220, "carbsPercent": 50,
                "fatGrams": 75, "fatPercent": 30
            },
            {
                "id": "d2",
                "name": "Quemador de Grasa Bajo en Carbos",
                "description": "Limita severamente los carbohidratos para poner el cuerpo en un estado de quema de grasa.",
                "goal": "Pérdida Rápida de Grasa",
                "calories": 1600,
                "proteinGrams": 120, "proteinPercent": 35,
                "carbsGrams": 50, "carbsPercent": 10,
                "fatGrams": 100, "fatPercent": 55
            },
            {
                "id": "d3",
                "name": "Vitalidad Vegana",
                "description": "Plan 100% basado en plantas enfocado en vegetales densos en nutrientes y legumbres.",
                "goal": "Energía Limpia & Digestión",
                "calories": 1800,
                "proteinGrams": 70, "proteinPercent": 15,
                "carbsGrams": 250, "carbsPercent": 60,
                "fatGrams": 55, "fatPercent": 25
            },
            {
                "id": "d4",
                "name": "Plan de Equilibrio Diabético",
                "description": "Diseñado específicamente con alimentos de bajo índice glucémico para mantener niveles estables de azúcar.",
                "goal": "Estabilidad Glucémica",
                "calories": 1700,
                "proteinGrams": 100, "proteinPercent": 25,
                "carbsGrams": 150, "carbsPercent": 40,
                "fatGrams": 65, "fatPercent": 35
            }
        ]
        return Response(dietas, status=status.HTTP_200_OK)