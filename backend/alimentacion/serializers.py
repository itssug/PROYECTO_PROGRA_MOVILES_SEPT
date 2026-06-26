from rest_framework import serializers
from core.models import Comidas, RegistroComidas, ResumenDiario

class ComidaSerializer(serializers.ModelSerializer):
    indiceGlucemico = serializers.IntegerField(source='indice_glucemico', read_only=True)
    cargaGlucemica = serializers.DecimalField(source='carga_glucemica', max_digits=5, decimal_places=2, read_only=True)
    unidadMedida = serializers.CharField(source='unidad_medida', read_only=True)
    porcionTipica = serializers.DecimalField(source='porcion_tipica', max_digits=6, decimal_places=2, read_only=True)
    esPersonalizado = serializers.BooleanField(source='es_personalizado', read_only=True)

    class Meta:
        model = Comidas
        fields = [
            'id', 'nombre', 'categoria', 'calorias', 'carbohidratos', 
            'azucares', 'proteinas', 'grasas', 'indiceGlucemico', 
            'cargaGlucemica', 'unidadMedida', 'porcionTipica', 'esPersonalizado',
            'descripcion', 'sodio'
        ]

class RegistroComidaSerializer(serializers.ModelSerializer):
    comidaId = serializers.IntegerField(source='comida.id', read_only=True)
    comidaNombre = serializers.CharField(source='comida.nombre', read_only=True)
    comidaCategoria = serializers.CharField(source='comida.categoria', read_only=True)
    tipoComida = serializers.CharField(source='tipo_comida')
    tipoComidaDisplay = serializers.SerializerMethodField()
    caloriasCalculadas = serializers.DecimalField(source='calorias_calculadas', max_digits=6, decimal_places=2, read_only=True)
    carbohidratosCalculados = serializers.DecimalField(source='carbohidratos_calculados', max_digits=6, decimal_places=2, read_only=True)
    azucaresCalculados = serializers.DecimalField(source='azucares_calculados', max_digits=6, decimal_places=2, read_only=True)
    cargaGlucemica = serializers.DecimalField(source='carga_glucemica_calc', max_digits=5, decimal_places=2, read_only=True)

    class Meta:
        model = RegistroComidas
        fields = [
            'id', 'comidaId', 'comidaNombre', 'comidaCategoria', 'cantidad', 
            'unidad', 'tipoComida', 'tipoComidaDisplay', 'fecha', 'hora', 
            'caloriasCalculadas', 'carbohidratosCalculados', 'azucaresCalculados', 
            'cargaGlucemica', 'notas'
        ]
        
    def get_tipoComidaDisplay(self, obj):
        return obj.tipo_comida.capitalize() if obj.tipo_comida else ''

class ResumenDiarioSerializer(serializers.ModelSerializer):
    totalCalorias = serializers.DecimalField(source='calorias_totales', max_digits=7, decimal_places=2, read_only=True)
    totalCarbohidratos = serializers.DecimalField(source='carbohidratos_totales', max_digits=6, decimal_places=2, read_only=True)
    totalAzucares = serializers.SerializerMethodField()
    totalCargaGlucemica = serializers.DecimalField(source='carga_glucemica_total', max_digits=6, decimal_places=2, read_only=True)
    cantidadRegistros = serializers.IntegerField(source='cantidad_mediciones', read_only=True)
    porTipoComida = serializers.SerializerMethodField()

    class Meta:
        model = ResumenDiario
        fields = [
            'fecha', 'totalCalorias', 'totalCarbohidratos', 'totalAzucares', 
            'totalCargaGlucemica', 'cantidadRegistros', 'porTipoComida'
        ]

    def get_totalAzucares(self, obj):
        # El modelo ResumenDiario no tiene campo para azucares totales, pero lo calculamos desde los registros de comida.
        # Alternativamente podríamos devolver 0 y luego calcularlo en la vista, pero si la vista se lo pasa al objeto, lo leemos de ahí.
        return getattr(obj, 'azucares_totales_calculados', 0)

    def get_porTipoComida(self, obj):
        return getattr(obj, 'por_tipo_comida_calculado', {})
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


# ── NUEVO: Serializer para editar un registro existente ──────
class RegistroComidaUpdateSerializer(serializers.Serializer):
    """Serializer para editar un registro de comida."""
    cantidad = serializers.DecimalField(max_digits=7, decimal_places=2, required=False)
    tipo_comida = serializers.CharField(max_length=12, required=False)
    hora = serializers.TimeField(required=False)
    unidad = serializers.CharField(max_length=9, required=False)
    notas = serializers.CharField(required=False, allow_blank=True, allow_null=True)

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
