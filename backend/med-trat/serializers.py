from rest_framework import serializers
from core.models import Medicamentos, RegistroMedicamentos


# ── Medicamentos ──────────────────────────────────────────────────────────────

class MedicamentoSerializer(serializers.ModelSerializer):
    """
    Serializer completo para crear/editar un medicamento.
    El campo usuario_id se inyecta desde la view — el cliente no lo manda.
    """

    # Solo lectura — se calcula en el servidor
    usuario_id = serializers.IntegerField(read_only=True)

    class Meta:
        model  = Medicamentos
        fields = [
            'id',
            'usuario_id',
            'nombre',
            'tipo',
            'dosis',
            'unidad',
            'hora_toma',
            'relacion_comida',
            'frecuencia',
            'fecha_inicio',
            'fecha_fin',
            'activo',
            'notas',
        ]

    # ── Validaciones ──────────────────────────────────────────────────────────

    def validate_tipo(self, value):
        opciones = [
            'biguanida', 'sulfonilurea', 'inhibidor_sglt2',
            'agonista_glp1', 'inhibidor_dpp4',
            'insulina_basal', 'insulina_rapida', 'otro',
        ]
        if value and value not in opciones:
            raise serializers.ValidationError(
                f"Tipo inválido. Opciones: {', '.join(opciones)}"
            )
        return value

    def validate_frecuencia(self, value):
        opciones = ['diario', 'cada_8h', 'cada_12h', 'semanal', 'segun_necesidad']
        if value and value not in opciones:
            raise serializers.ValidationError(
                f"Frecuencia inválida. Opciones: {', '.join(opciones)}"
            )
        return value

    def validate_relacion_comida(self, value):
        opciones = ['antes', 'durante', 'despues', 'independiente']
        if value and value not in opciones:
            raise serializers.ValidationError(
                f"Relación con comida inválida. Opciones: {', '.join(opciones)}"
            )
        return value

    def validate(self, data):
        fecha_inicio = data.get('fecha_inicio')
        fecha_fin    = data.get('fecha_fin')
        if fecha_inicio and fecha_fin and fecha_fin < fecha_inicio:
            raise serializers.ValidationError(
                {"fecha_fin": "La fecha de fin no puede ser anterior a la de inicio."}
            )
        return data


class MedicamentoListSerializer(serializers.ModelSerializer):
    """
    Versión reducida para listados — menos campos, más rápido.
    """
    class Meta:
        model  = Medicamentos
        fields = [
            'id',
            'nombre',
            'tipo',
            'dosis',
            'unidad',
            'hora_toma',
            'frecuencia',
            'activo',
        ]


# ── RegistroMedicamentos ──────────────────────────────────────────────────────

class RegistroMedicamentoSerializer(serializers.ModelSerializer):
    """
    Serializer para confirmar/registrar la toma de un medicamento.
    Incluye el nombre del medicamento como campo de solo lectura.
    """

    # Dato extra de solo lectura para que Flutter no tenga que hacer otro request
    medicamento_nombre = serializers.CharField(
        source='medicamento.nombre',
        read_only=True,
    )
    medicamento_tipo = serializers.CharField(
        source='medicamento.tipo',
        read_only=True,
    )
    usuario_id = serializers.IntegerField(read_only=True)

    class Meta:
        model  = RegistroMedicamentos
        fields = [
            'id',
            'usuario_id',
            'medicamento',        # ID para escribir
            'medicamento_nombre', # nombre para leer
            'medicamento_tipo',   # tipo para leer
            'fecha',
            'hora',
            'dosis_tomada',
            'fue_tomado',
            'notas',
        ]

    def validate_fue_tomado(self, value):
        # En la BD es IntegerField (0/1), validamos que solo llegue eso
        if value not in [0, 1]:
            raise serializers.ValidationError("Debe ser 0 (no tomado) o 1 (tomado).")
        return value

    def validate(self, data):
        # Si fue_tomado=1, dosis_tomada debería estar presente
        if data.get('fue_tomado') == 1 and not data.get('dosis_tomada'):
            raise serializers.ValidationError(
                {"dosis_tomada": "Indica la dosis tomada al confirmar la toma."}
            )
        return data


class RegistroMedicamentoListSerializer(serializers.ModelSerializer):
    """
    Versión reducida para el historial.
    """
    medicamento_nombre = serializers.CharField(
        source='medicamento.nombre',
        read_only=True,
    )

    class Meta:
        model  = RegistroMedicamentos
        fields = [
            'id',
            'medicamento',
            'medicamento_nombre',
            'fecha',
            'hora',
            'dosis_tomada',
            'fue_tomado',
        ]