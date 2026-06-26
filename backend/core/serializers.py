# ============================================================
# ARCHIVO: core/serializers.py
# ============================================================
from rest_framework import serializers
from .models import Usuarios, Glucosa
import hashlib
from django.db import connection


class RegistroSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=8)
    confirmar_password = serializers.CharField(write_only=True)

    class Meta:
        model = Usuarios
        fields = [
            'nombre', 'email', 'password', 'confirmar_password',
            'fecha_nacimiento', 'sexo', 'peso', 'altura',
            'anios_diagnostico', 'hba1c_inicial', 'usa_insulina',
            'tiene_hipertension', 'tiene_dislipidemia', 'es_fumador',
            'nivel_actividad_base',
        ]

    def validate_email(self, value):
        if Usuarios.objects.filter(email=value).exists():
            raise serializers.ValidationError("Este correo ya está registrado.")
        return value.lower()

    def validate(self, data):
        if data['password'] != data['confirmar_password']:
            raise serializers.ValidationError({"confirmar_password": "Las contraseñas no coinciden."})
        return data

    def create(self, validated_data):
        validated_data.pop('confirmar_password')
        raw_password = validated_data.pop('password')
        # SHA-256 simple — reemplaza con make_password si usas django.contrib.auth
        validated_data['password'] = hashlib.sha256(raw_password.encode()).hexdigest()
        usuario = Usuarios.objects.create(**validated_data)
        return usuario


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField()

    def validate(self, data):
        import hashlib
        try:
            usuario = Usuarios.objects.get(email=data['email'].lower())
        except Usuarios.DoesNotExist:
            raise serializers.ValidationError("Credenciales incorrectas.")

        hashed = hashlib.sha256(data['password'].encode()).hexdigest()
        if usuario.password != hashed:
            raise serializers.ValidationError("Credenciales incorrectas.")

        data['usuario'] = usuario
        return data


class UsuarioPublicoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuarios
        fields = [
            'id', 'nombre', 'email', 'fecha_nacimiento', 'sexo',
            'peso', 'altura', 'anios_diagnostico',
            'hba1c_inicial', 'usa_insulina', 'tiene_hipertension',
            'tiene_dislipidemia', 'es_fumador', 'nivel_actividad_base',
            'fecha_registro',
        ]
        read_only_fields = ['id', 'fecha_registro']  # ← Solo estos dos

    def get_imc(self, obj):
        with connection.cursor() as cursor:
            cursor.execute("SELECT imc FROM usuarios WHERE id = %s", [obj.id])
            row = cursor.fetchone()
        return float(row[0]) if row and row[0] else None


class GlucosaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Glucosa
        fields = '__all__'