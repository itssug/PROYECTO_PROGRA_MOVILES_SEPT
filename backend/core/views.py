from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum, Avg, Count
from datetime import datetime, timedelta
from .models import ActividadFisica, Usuarios
from .serializers import ActividadFisicaSerializer, ActividadFisicaListSerializer

def get_usuario_id(request):
    """Obtiene usuario_id del header o usa 1 como default para pruebas."""
    return int(request.headers.get('X-Usuario-Id', 1))

@api_view(['GET', 'POST'])
def actividades_list_create(request):
    usuario_id = get_usuario_id(request)

    if request.method == 'GET':
        fecha_desde = request.query_params.get('fecha_desde')
        fecha_hasta = request.query_params.get('fecha_hasta')
        tipo = request.query_params.get('tipo')

        qs = ActividadFisica.objects.filter(
            usuario_id=usuario_id
        ).order_by('-fecha', '-hora_inicio')

        if fecha_desde:
            qs = qs.filter(fecha__gte=fecha_desde)
        if fecha_hasta:
            qs = qs.filter(fecha__lte=fecha_hasta)
        if tipo:
            qs = qs.filter(tipo=tipo)

        serializer = ActividadFisicaListSerializer(qs, many=True)
        return Response({
            'actividades': serializer.data,
            'total': qs.count(),
        }, status=status.HTTP_200_OK)

    elif request.method == 'POST':
        serializer = ActividadFisicaSerializer(data=request.data)
        if serializer.is_valid():
            fecha = serializer.validated_data.get('fecha') or datetime.today().date()
            actividad = serializer.save(
                usuario_id=usuario_id,
                fecha=fecha,
            )
            return Response({
                'mensaje': 'Actividad registrada correctamente',
                'id': actividad.id,
            }, status=status.HTTP_201_CREATED)
        else:
            return Response({
                'error': 'Datos inválidos',
                'detalles': serializer.errors,
            }, status=status.HTTP_400_BAD_REQUEST)


@api_view(['GET', 'PUT', 'DELETE'])
def actividad_detail(request, pk):
    usuario_id = get_usuario_id(request)

    try:
        actividad = ActividadFisica.objects.get(pk=pk, usuario_id=usuario_id)
    except ActividadFisica.DoesNotExist:
        return Response(
            {'error': 'Actividad no encontrada'},
            status=status.HTTP_404_NOT_FOUND,
        )

    if request.method == 'GET':
        serializer = ActividadFisicaSerializer(actividad)
        return Response(serializer.data)

    elif request.method == 'PUT':
        serializer = ActividadFisicaSerializer(
            actividad, data=request.data, partial=True
        )
        if serializer.is_valid():
            serializer.save()
            return Response({'mensaje': 'Actividad actualizada correctamente'})
        return Response({
            'error': 'Datos inválidos',
            'detalles': serializer.errors,
        }, status=status.HTTP_400_BAD_REQUEST)

    elif request.method == 'DELETE':
        actividad.delete()
        return Response(
            {'mensaje': 'Actividad eliminada'},
            status=status.HTTP_200_OK,
        )
@api_view(['GET'])
def actividades_estadisticas(request):
    usuario_id = get_usuario_id(request)
    periodo = request.query_params.get('periodo', '7')

    try:
        dias = int(periodo)
        if dias not in [7, 30, 90]:
            dias = 7
    except ValueError:
        dias = 7

    fecha_desde = datetime.today() - timedelta(days=dias)

    qs = ActividadFisica.objects.filter(
        usuario_id=usuario_id,
        fecha__gte=fecha_desde.date(),
    )

    totales = qs.aggregate(
        total_actividades=Count('id'),
        total_minutos=Sum('duracion'),
        total_calorias=Sum('calorias_quemadas'),
        total_pasos=Sum('pasos'),
    )

    por_tipo = list(
        qs.values('tipo')
        .annotate(
            cantidad=Count('id'),
            minutos=Sum('duracion'),
            calorias=Sum('calorias_quemadas'),
        )
        .order_by('-cantidad')
    )

    por_dia = []
    for i in range(dias):
        dia = (datetime.today() - timedelta(days=dias - 1 - i)).date()
        agg = qs.filter(fecha=dia).aggregate(
            minutos=Sum('duracion'),
            calorias=Sum('calorias_quemadas'),
            pasos=Sum('pasos'),
        )
        por_dia.append({
            'fecha': str(dia),
            'minutos': agg['minutos'] or 0,
            'calorias': float(agg['calorias']) if agg['calorias'] else 0,
            'pasos': agg['pasos'] or 0,
        })

    con_glucosa = qs.filter(
        glucosa_pre__isnull=False,
        glucosa_post__isnull=False,
    )
    impacto_glucosa = []
    for a in con_glucosa:
        diferencia = float(a.glucosa_post) - float(a.glucosa_pre)
        impacto_glucosa.append({
            'fecha': str(a.fecha),
            'tipo': a.tipo,
            'duracion': a.duracion,
            'intensidad': a.intensidad,
            'glucosa_pre': float(a.glucosa_pre),
            'glucosa_post': float(a.glucosa_post),
            'diferencia': round(diferencia, 2),
        })

    semana_actual = datetime.today() - timedelta(days=7)
    minutos_semana = ActividadFisica.objects.filter(
        usuario_id=usuario_id,
        fecha__gte=semana_actual.date(),
    ).aggregate(total=Sum('duracion'))['total'] or 0

    return Response({
        'periodo_dias': dias,
        'totales': {
            'actividades': totales['total_actividades'] or 0,
            'minutos': totales['total_minutos'] or 0,
            'calorias': float(totales['total_calorias']) if totales['total_calorias'] else 0,
            'pasos': totales['total_pasos'] or 0,
        },
        'por_tipo': [
            {
                'tipo': t['tipo'],
                'cantidad': t['cantidad'],
                'minutos': t['minutos'] or 0,
                'calorias': float(t['calorias']) if t['calorias'] else 0,
            }
            for t in por_tipo
        ],
        'por_dia': por_dia,
        'impacto_glucosa': impacto_glucosa,
        'meta_semanal': {
            'objetivo_minutos': 150,
            'completado_minutos': minutos_semana,
            'porcentaje': min(100, round((minutos_semana / 150) * 100, 1)),
        },
    })

@api_view(['GET'])
def actividades_hoy(request):
    usuario_id = get_usuario_id(request)
    hoy = datetime.today().date()

    qs = ActividadFisica.objects.filter(usuario_id=usuario_id, fecha=hoy)
    totales = qs.aggregate(
        actividades=Count('id'),
        minutos=Sum('duracion'),
        calorias=Sum('calorias_quemadas'),
        pasos=Sum('pasos'),
    )

    actividades = []
    for a in qs.order_by('hora_inicio'):
        actividades.append({
            'id': a.id,
            'tipo': a.tipo,
            'intensidad': a.intensidad,
            'duracion': a.duracion,
            'calorias_quemadas': float(a.calorias_quemadas) if a.calorias_quemadas else 0,
            'pasos': a.pasos or 0,
            'hora_inicio': str(a.hora_inicio) if a.hora_inicio else None,
        })

    return Response({
        'fecha': str(hoy),
        'resumen': {
            'actividades': totales['actividades'] or 0,
            'minutos': totales['minutos'] or 0,
            'calorias': float(totales['calorias']) if totales['calorias'] else 0,
            'pasos': totales['pasos'] or 0,
        },
        'actividades': actividades,
    })
