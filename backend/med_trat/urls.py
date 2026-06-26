from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MedicamentosViewSet, RegistroMedicamentosViewSet

router = DefaultRouter()
router.register(r'medicamentos', MedicamentosViewSet, basename='medicamentos')
router.register(r'registros',    RegistroMedicamentosViewSet, basename='registros')

urlpatterns = [
    path('', include(router.urls)),
]

# ── Endpoints generados ───────────────────────────────────────────────────────
#
# Medicamentos:
#   GET    /med-trat/medicamentos/           → lista
#   POST   /med-trat/medicamentos/           → crear
#   GET    /med-trat/medicamentos/{id}/      → detalle
#   PUT    /med-trat/medicamentos/{id}/      → editar
#   PATCH  /med-trat/medicamentos/{id}/      → editar parcial
#   DELETE /med-trat/medicamentos/{id}/      → eliminar
#   GET    /med-trat/medicamentos/activos/   → solo activos
#
# Registros:
#   GET    /med-trat/registros/              → historial
#   POST   /med-trat/registros/             → confirmar toma
#   GET    /med-trat/registros/{id}/        → detalle
#   PATCH  /med-trat/registros/{id}/        → corregir
#   GET    /med-trat/registros/hoy/         → tomas de hoy
#   GET    /med-trat/registros/adherencia/  → % adherencia 7 días