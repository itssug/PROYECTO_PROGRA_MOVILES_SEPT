
from rest_framework import serializers
from .models import ActividadFisica


TIPOS_VALIDOS = [
    'caminata', 'trote', 'ciclismo', 'natacion', 'pesas',
    'yoga', 'baile', 'futbol', 'otro_aerobico', 'otro_anaerobico',
]

INTENSIDADES_VALIDAS = ['leve', 'moderada', 'intensa']


class ActividadFisicaSerializer(serializers.ModelSerializer):
    """
    Serializer completo para el CRUD de actividades físicas.
    Valida tipos, intensidades y rangos de valores.
    """

    class Meta:
        model = ActividadFisica
        fields = [
            'id', 'usuario_id', 'tipo', 'intensidad', 'duracion',
            'calorias_quemadas', 'pasos', 'frecuencia_cardiaca_prom',
            'fecha', 'hora_inicio', 'glucosa_pre', 'glucosa_post', 'notas',
        ]
        read_only_fields = ['id', 'usuario_id']

    def validate_tipo(self, value):
        if value not in TIPOS_VALIDOS:
            raise serializers.ValidationError(
                f'Tipo inválido. Opciones: {", ".join(TIPOS_VALIDOS)}'
            )
        return value

    def validate_intensidad(self, value):
        if value and value not in INTENSIDADES_VALIDAS:
            raise serializers.ValidationError(
                f'Intensidad inválida. Opciones: {", ".join(INTENSIDADES_VALIDAS)}'
            )
        return value

    def validate_duracion(self, value):
        if value <= 0:
            raise serializers.ValidationError('La duración debe ser mayor a 0 minutos.')
        if value > 720:
            raise serializers.ValidationError('La duración no puede exceder 720 minutos.')
        return value

    def validate_calorias_quemadas(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError('Las calorías no pueden ser negativas.')
        return value

    def validate_pasos(self, value):
        if value is not None and value < 0:
            raise serializers.ValidationError('Los pasos no pueden ser negativos.')
        return value

    def validate_glucosa_pre(self, value):
        if value is not None and (value < 20 or value > 600):
            raise serializers.ValidationError('Glucosa PRE fuera de rango (20-600 mg/dL).')
        return value

    def validate_glucosa_post(self, value):
        if value is not None and (value < 20 or value > 600):
            raise serializers.ValidationError('Glucosa POST fuera de rango (20-600 mg/dL).')
        return value


class ActividadFisicaListSerializer(serializers.ModelSerializer):
    """Serializer simplificado para listas."""
    calorias_quemadas = serializers.FloatField(default=0)
    glucosa_pre = serializers.FloatField(allow_null=True)
    glucosa_post = serializers.FloatField(allow_null=True)

    class Meta:
        model = ActividadFisica
        fields = [
            'id', 'tipo', 'intensidad', 'duracion',
            'calorias_quemadas', 'pasos', 'frecuencia_cardiaca_prom',
            'fecha', 'hora_inicio', 'glucosa_pre', 'glucosa_post', 'notas',
        ]
