# token_model.py
import secrets
from django.db import models

class TokenUsuario(models.Model):
    usuario_id = models.PositiveBigIntegerField(unique=True)
    key = models.CharField(max_length=64, unique=True)
    creado = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'token_usuario'

    @property
    def usuario(self):
        from .models import Usuarios
        return Usuarios.objects.get(id=self.usuario_id)

    @classmethod
    def crear(cls, usuario):
        """Crea un nuevo token para el usuario"""
        # Eliminar token anterior si existe
        cls.objects.filter(usuario_id=usuario.id).delete()
        # Crear nuevo token
        nuevo_token = cls(
            usuario_id=usuario.id,
            key=secrets.token_hex(32)
        )
        nuevo_token.save()
        return nuevo_token