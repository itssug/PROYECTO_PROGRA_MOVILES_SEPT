import secrets
from django.db import models


class TokenUsuario(models.Model):
    usuario_id = models.PositiveBigIntegerField(unique=True)  # coincide con BIGINT UNSIGNED de usuarios.id
    key        = models.CharField(max_length=64, unique=True)
    creado     = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'token_usuario'

    @property
    def usuario(self):
        from .models import Usuarios
        return Usuarios.objects.get(id=self.usuario_id)

    @classmethod
    def crear(cls, usuario):
        cls.objects.filter(usuario_id=usuario.id).delete()
        return cls.objects.create(usuario_id=usuario.id, key=secrets.token_hex(32))