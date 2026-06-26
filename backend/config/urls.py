from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    path('api/', include('actividad_fisica.urls')),  # ← Nueva app agregada
    
    path('api/', include('analitica_ia.urls')),
    
    # Módulo de seguimiento médico/salud
    path('api/estado-sueno/', include('estado_sueno.urls')),
    path('api/alimentacion/', include('alimentacion.urls')),
    
    # Chat con Inteligencia Artificial
    path('api/ai/', include('app.urls')),
]