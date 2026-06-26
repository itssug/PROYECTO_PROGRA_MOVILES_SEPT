# analitica_ia/serializers.py

from rest_framework import serializers


class PrediccionSerializer(serializers.Serializer):

    glucosa_antes = serializers.FloatField(required=False, allow_null=True)
    carbohidratos = serializers.FloatField()
    carga_glucemica = serializers.FloatField()
    horas_sueno = serializers.FloatField(required=False, allow_null=True)
    estres = serializers.IntegerField(required=False, allow_null=True)
    ejercicio = serializers.FloatField(required=False, allow_null=True)
    medicamento_tomado = serializers.IntegerField(required=False, allow_null=True)