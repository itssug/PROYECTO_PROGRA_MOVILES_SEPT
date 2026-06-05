from rest_framework import serializers
from core.models import EstadoEmocional, RegistroSueno

class EstadoEmocionalSerializer(serializers.ModelSerializer):
    class Meta:
        model = EstadoEmocional
        fields = '__all__'

class RegistroSuenoSerializer(serializers.ModelSerializer):
    class Meta:
        model = RegistroSueno
        fields = '__all__'