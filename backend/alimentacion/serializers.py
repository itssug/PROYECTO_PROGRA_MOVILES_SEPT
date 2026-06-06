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
