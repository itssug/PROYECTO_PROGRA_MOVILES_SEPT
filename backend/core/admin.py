from django.contrib import admin
from .models import ActividadFisica, Usuarios


@admin.register(ActividadFisica)
class ActividadFisicaAdmin(admin.ModelAdmin):
    list_display = [
        'id', 'usuario', 'tipo', 'intensidad', 'duracion',
        'calorias_quemadas', 'fecha', 'hora_inicio',
    ]
    list_filter = ['tipo', 'intensidad', 'fecha']
    search_fields = ['tipo', 'notas']
    ordering = ['-fecha', '-hora_inicio']


@admin.register(Usuarios)
class UsuariosAdmin(admin.ModelAdmin):
    list_display = ['id', 'nombre', 'email', 'fecha_registro']
    search_fields = ['nombre', 'email']