from rest_framework import serializers
from core.models import Alertas

class AlertasSerializer(serializers.ModelSerializer):
    class Meta:
        model = Alertas
        fields = '__all__'
        extra_kwargs = {
            'usuario': {'validators': []}
        }