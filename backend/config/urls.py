from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    
    path("api/", include("analitica_ia.urls")),
    #modulo gi
    path('api/estado-sueno/', include('estado_sueno.urls')),
    path('api/alertas/', include('alertas.urls')),
    path('api/alimentacion/', include('alimentacion.urls')),
    path('api/', include('actividad_fisica.urls')),
    #chat
    path('api/ai/', include('app.urls')),  # <- esto faltaría
    path('med-trat/', include('med_trat.urls')),

]