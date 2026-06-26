from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum, Q
from django.utils.dateparse import parse_date
from decimal import Decimal
import datetime

from core.models import Comidas, RegistroComidas, ResumenDiario, Usuarios
from core.token_model import TokenUsuario
from .serializers import ComidaSerializer, RegistroComidaSerializer, ResumenDiarioSerializer

def get_user_from_request(request):
    auth_header = request.headers.get('Authorization', '')
    key = auth_header.replace('Bearer ', '').replace('Token ', '').strip()
    if not key:
        return None
    try:
        token_obj = TokenUsuario.objects.get(key=key)
        return Usuarios.objects.get(id=token_obj.usuario_id)
    except Exception:
        return None

class CatalogoView(APIView):
    def get(self, request):
        categoria = request.GET.get('categoria', None)
        if categoria:
            comidas = Comidas.objects.filter(categoria__iexact=categoria)
        else:
            comidas = Comidas.objects.all()
        
        serializer = ComidaSerializer(comidas, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        usuario = get_user_from_request(request)
        if not usuario:
            return Response({'error': 'No autorizado'}, status=status.HTTP_401_UNAUTHORIZED)
            
        data = request.data
        comida = Comidas.objects.create(
            nombre=data.get('nombre'),
            categoria=data.get('categoria'),
            calorias=data.get('calorias'),
            carbohidratos=data.get('carbohidratos'),
            azucares=data.get('azucares'),
            proteinas=data.get('proteinas'),
            grasas=data.get('grasas'),
            indice_glucemico=data.get('indiceGlucemico'),
            carga_glucemica=0, # To be calculated if needed
            unidad_medida=data.get('unidadMedida', 'gramos'),
            porcion_tipica=data.get('porcionTipica', 100),
            es_personalizado=1,
            usuario_id=usuario.id
        )
        serializer = ComidaSerializer(comida)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

class BuscarAlimentosView(APIView):
    def get(self, request):
        query = request.GET.get('q', '')
        comidas = Comidas.objects.filter(nombre__icontains=query)
        serializer = ComidaSerializer(comidas, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

class RegistrosDiaView(APIView):
    def get(self, request):
        usuario = get_user_from_request(request)
        if not usuario:
            return Response({'error': 'No autorizado'}, status=status.HTTP_401_UNAUTHORIZED)
            
        fecha_str = request.GET.get('fecha')
        if not fecha_str:
            fecha_str = datetime.date.today().strftime('%Y-%m-%d')
            
        fecha = parse_date(fecha_str)
        registros = RegistroComidas.objects.filter(usuario=usuario, fecha=fecha).select_related('comida')
        serializer = RegistroComidaSerializer(registros, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def post(self, request):
        usuario = get_user_from_request(request)
        if not usuario:
            return Response({'error': 'No autorizado'}, status=status.HTTP_401_UNAUTHORIZED)
            
        data = request.data
        try:
            comida = Comidas.objects.get(id=data.get('comidaId'))
        except Comidas.DoesNotExist:
            return Response({'error': 'Comida no encontrada'}, status=status.HTTP_404_NOT_FOUND)
            
        cantidad = Decimal(str(data.get('cantidad', 0)))
        porcion_tipica = comida.porcion_tipica if comida.porcion_tipica else Decimal('100')
        factor = cantidad / porcion_tipica if porcion_tipica > 0 else Decimal('1')
        
        calorias_calc = (comida.calorias or 0) * factor
        carbos_calc = (comida.carbohidratos or 0) * factor
        azucares_calc = (comida.azucares or 0) * factor
        carga_gl_calc = (comida.carga_glucemica or 0) * factor
        
        registro = RegistroComidas.objects.create(
            usuario=usuario,
            comida=comida,
            cantidad=cantidad,
            unidad=data.get('unidad', 'gramos'),
            tipo_comida=data.get('tipoComida', ''),
            fecha=data.get('fecha'),
            hora=data.get('hora'),
            calorias_calculadas=calorias_calc,
            carbohidratos_calculados=carbos_calc,
            azucares_calculados=azucares_calc,
            carga_glucemica_calc=carga_gl_calc,
            notas=data.get('notas', '')
        )
        
        # After saving, we could update ResumenDiario here
        self._update_resumen_diario(usuario, registro.fecha)
        
        serializer = RegistroComidaSerializer(registro)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
        
    def _update_resumen_diario(self, usuario, fecha):
        registros = RegistroComidas.objects.filter(usuario=usuario, fecha=fecha)
        resumen, _ = ResumenDiario.objects.get_or_create(usuario=usuario, fecha=fecha)
        
        resumen.calorias_totales = sum(r.calorias_calculadas or 0 for r in registros)
        resumen.carbohidratos_totales = sum(r.carbohidratos_calculados or 0 for r in registros)
        resumen.carga_glucemica_total = sum(r.carga_glucemica_calc or 0 for r in registros)
        resumen.cantidad_mediciones = registros.count()
        resumen.save()

class RegistroDetalleView(APIView):
    def delete(self, request, pk):
        usuario = get_user_from_request(request)
        if not usuario:
            return Response({'error': 'No autorizado'}, status=status.HTTP_401_UNAUTHORIZED)
            
        try:
            registro = RegistroComidas.objects.get(id=pk, usuario=usuario)
            fecha = registro.fecha
            registro.delete()
            
            # Recalculate resumen
            RegistrosDiaView()._update_resumen_diario(usuario, fecha)
            
            return Response(status=status.HTTP_204_NO_CONTENT)
        except RegistroComidas.DoesNotExist:
            return Response({'error': 'Registro no encontrado'}, status=status.HTTP_404_NOT_FOUND)

class ResumenDiaView(APIView):
    def get(self, request):
        usuario = get_user_from_request(request)
        if not usuario:
            return Response({'error': 'No autorizado'}, status=status.HTTP_401_UNAUTHORIZED)
            
        fecha_str = request.GET.get('fecha')
        if not fecha_str:
            fecha_str = datetime.date.today().strftime('%Y-%m-%d')
            
        fecha = parse_date(fecha_str)
        resumen, _ = ResumenDiario.objects.get_or_create(usuario=usuario, fecha=fecha)
        
        # Calculate dynamic fields
        registros = RegistroComidas.objects.filter(usuario=usuario, fecha=fecha)
        resumen.azucares_totales_calculados = float(sum(r.azucares_calculados or 0 for r in registros))
        
        # Group by tipo_comida
        por_tipo = {}
        for r in registros:
            tc = r.tipo_comida
            if tc:
                por_tipo[tc] = por_tipo.get(tc, 0) + float(r.calorias_calculadas or 0)
        
        resumen.por_tipo_comida_calculado = por_tipo
        
        serializer = ResumenDiarioSerializer(resumen)
        return Response(serializer.data, status=status.HTTP_200_OK)
