from rest_framework import serializers
from core.models import Comidas, RegistroComidas

# ENUMs reales de la BD MySQL
CATEGORIAS_VALIDAS = [
    'cereales', 'legumbres', 'frutas', 'verduras', 'lacteos',
    'carnes', 'bebidas', 'snacks', 'comida_rapida', 'preparado', 'otro',
]
UNIDADES_VALIDAS = ['gramos', 'ml', 'unidad', 'taza', 'cucharada']


class ComidaSerializer(serializers.ModelSerializer):
    """Serializer para el catálogo de alimentos."""
    class Meta:
        model = Comidas
        fields = [
            'id', 'nombre', 'descripcion', 'categoria',
            'calorias', 'carbohidratos', 'azucares', 'fibra',
            'proteinas', 'grasas', 'sodio',
            'indice_glucemico', 'carga_glucemica',
            'unidad_medida', 'porcion_tipica',
            'es_personalizado', 'usuario_id',
        ]


class ComidaCreateSerializer(serializers.ModelSerializer):
    """Serializer para crear alimentos personalizados."""
    class Meta:
        model = Comidas
        fields = [
            'nombre', 'descripcion', 'categoria',
            'calorias', 'carbohidratos', 'azucares', 'fibra',
            'proteinas', 'grasas', 'sodio',
            'indice_glucemico', 'carga_glucemica',
            'unidad_medida', 'porcion_tipica',
        ]

    def validate_categoria(self, value):
        if value not in CATEGORIAS_VALIDAS:
            raise serializers.ValidationError(
                f"Categoría inválida. Opciones: {', '.join(CATEGORIAS_VALIDAS)}"
            )
        return value

    def validate_unidad_medida(self, value):
        if value and value not in UNIDADES_VALIDAS:
            raise serializers.ValidationError(
                f"Unidad inválida. Opciones: {', '.join(UNIDADES_VALIDAS)}"
            )
        return value


class RegistroComidaSerializer(serializers.ModelSerializer):
    """Serializer para leer registros de comidas con datos de la comida."""
    comida_nombre = serializers.CharField(source='comida.nombre', read_only=True)
    comida_categoria = serializers.CharField(source='comida.categoria', read_only=True)

    class Meta:
        model = RegistroComidas
        fields = [
            'id', 'usuario_id', 'comida_id',
            'comida_nombre', 'comida_categoria',
            'cantidad', 'unidad', 'tipo_comida',
            'fecha', 'hora',
            'calorias_calculadas', 'carbohidratos_calculados',
            'azucares_calculados', 'carga_glucemica_calc',
            'notas',
        ]


class RegistroComidaCreateSerializer(serializers.Serializer):
    """Serializer para crear un registro de comida con cálculo automático."""
    comida_id = serializers.IntegerField()
    cantidad = serializers.DecimalField(max_digits=7, decimal_places=2)
    tipo_comida = serializers.CharField(max_length=12)
    fecha = serializers.DateField()
    hora = serializers.TimeField()
    unidad = serializers.CharField(max_length=9, required=False, default='gramos')
    notas = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_comida_id(self, value):
        if not Comidas.objects.filter(id=value).exists():
            raise serializers.ValidationError("Comida no encontrada en el catálogo.")
        return value

    def validate_tipo_comida(self, value):
        validos = ['desayuno', 'media_manana', 'almuerzo', 'merienda', 'cena', 'snack']
        if value not in validos:
            raise serializers.ValidationError(
                f"Tipo de comida inválido. Opciones: {', '.join(validos)}"
            )
        return value

    def validate_unidad(self, value):
        if value and value not in UNIDADES_VALIDAS:
            raise serializers.ValidationError(
                f"Unidad inválida. Opciones: {', '.join(UNIDADES_VALIDAS)}"
            )
        return value