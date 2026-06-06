# analitica_ia/serializers.py

from rest_framework import serializers


class PrediccionSerializer(serializers.Serializer):

    glucosa_antes = serializers.FloatField()

    carbohidratos = serializers.FloatField()

    carga_glucemica = serializers.FloatField()

    horas_sueno = serializers.FloatField()

    estres = serializers.IntegerField()

    ejercicio = serializers.FloatField()