from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/', include('core.urls')),
    
    path("api/", include("analitica_ia.urls")),
    #modulo gi
    path('api/estado-sueno/', include('estado_sueno.urls')),
    path('api/alimentacion/', include('alimentacion.urls')),
    #chat
    path('api/ai/', include('app.urls')),  # <- esto faltaría

]