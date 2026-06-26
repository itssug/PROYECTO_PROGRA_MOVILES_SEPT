from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from core.models import Medicamentos, RegistroMedicamentos, Usuarios
from .serializers import (
    MedicamentoSerializer,
    MedicamentoListSerializer,
    RegistroMedicamentoSerializer,
    RegistroMedicamentoListSerializer,
)


# ── Helper temporal hasta implementar JWT ────────────────────────────────────
# Cuando agregues auth, reemplaza esto por: request.user
# y usa un get_queryset que filtre por request.user directamente.

def _get_usuario(request):
    """
    Temporal: lee user_id del header o del body.
    Con JWT esto desaparece y se usa request.user.id directo.
    """
    user_id = (
        request.headers.get('X-User-Id')       # header preferido
        or request.data.get('user_id')          # fallback en body
        or request.query_params.get('user_id')  # fallback en query param
    )
    print("USER_ID:", user_id)
    if not user_id:
        return None, Response(
            {"error": "Se requiere user_id (auth pendiente)"},
            status=status.HTTP_400_BAD_REQUEST,
        )
    try:
        usuario = Usuarios.objects.get(id=user_id)
        return usuario, None
    except Usuarios.DoesNotExist:
        return None, Response(
            {"error": f"Usuario {user_id} no encontrado"},
            status=status.HTTP_404_NOT_FOUND,
        )


# ── Medicamentos ViewSet ──────────────────────────────────────────────────────

class MedicamentosViewSet(viewsets.ViewSet):
    """
    Endpoints:
        GET    /med-trat/medicamentos/          → lista del usuario
        POST   /med-trat/medicamentos/          → crear medicamento
        GET    /med-trat/medicamentos/{id}/     → detalle
        PUT    /med-trat/medicamentos/{id}/     → editar completo
        PATCH  /med-trat/medicamentos/{id}/     → editar parcial
        DELETE /med-trat/medicamentos/{id}/     → eliminar
        GET    /med-trat/medicamentos/activos/  → solo los activos
    """
    permission_classes = [AllowAny]  # TODO: cambiar a IsAuthenticated con JWT

    def list(self, request):
        usuario, err = _get_usuario(request)
        if err:
            return err

        medicamentos = Medicamentos.objects.filter(usuario=usuario).order_by('hora_toma')
        serializer   = MedicamentoListSerializer(medicamentos, many=True)
        return Response(serializer.data)

    def create(self, request):
        usuario, err = _get_usuario(request)
        if err:
            return err

        serializer = MedicamentoSerializer(data=request.data)
        if serializer.is_valid():
            # Inyectamos el usuario — el cliente no lo manda
            serializer.save(usuario=usuario)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def retrieve(self, request, pk=None):
        usuario, err = _get_usuario(request)
        if err:
            return err

        try:
            med = Medicamentos.objects.get(id=pk, usuario=usuario)
        except Medicamentos.DoesNotExist:
            return Response(
                {"error": "Medicamento no encontrado"},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(MedicamentoSerializer(med).data)

    def update(self, request, pk=None):
        return self._update(request, pk, partial=False)

    def partial_update(self, request, pk=None):
        return self._update(request, pk, partial=True)

    def _update(self, request, pk, partial):
        usuario, err = _get_usuario(request)
        if err:
            return err

        try:
            med = Medicamentos.objects.get(id=pk, usuario=usuario)
        except Medicamentos.DoesNotExist:
            return Response(
                {"error": "Medicamento no encontrado"},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = MedicamentoSerializer(med, data=request.data, partial=partial)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def destroy(self, request, pk=None):
        usuario, err = _get_usuario(request)
        if err:
            return err

        try:
            med = Medicamentos.objects.get(id=pk, usuario=usuario)
        except Medicamentos.DoesNotExist:
            return Response(
                {"error": "Medicamento no encontrado"},
                status=status.HTTP_404_NOT_FOUND,
            )

        med.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

    # ── Acción extra: solo activos ────────────────────────────────────────────

    @action(detail=False, methods=['get'], url_path='activos')
    def activos(self, request):
        usuario, err = _get_usuario(request)
        if err:
            return err

        meds = (
            Medicamentos.objects
            .filter(usuario=usuario, activo=1)
            .order_by('hora_toma')
        )
        return Response(MedicamentoListSerializer(meds, many=True).data)


# ── RegistroMedicamentos ViewSet ──────────────────────────────────────────────

class RegistroMedicamentosViewSet(viewsets.ViewSet):
    """
    Endpoints:
        GET   /med-trat/registros/              → historial completo
        POST  /med-trat/registros/              → confirmar toma
        GET   /med-trat/registros/{id}/         → detalle de un registro
        PATCH /med-trat/registros/{id}/         → corregir un registro
        GET   /med-trat/registros/hoy/          → registros de hoy
        GET   /med-trat/registros/adherencia/   → % de adherencia (últimos 7 días)
    """
    permission_classes = [AllowAny]  # TODO: cambiar a IsAuthenticated con JWT

    def list(self, request):
        usuario, err = _get_usuario(request)
        if err:
            return err

        registros  = (
            RegistroMedicamentos.objects
            .filter(usuario=usuario)
            .order_by('-fecha', '-hora')
        )
        serializer = RegistroMedicamentoListSerializer(registros, many=True)
        return Response(serializer.data)

    def create(self, request):
        usuario, err = _get_usuario(request)
        if err:
            return err

        serializer = RegistroMedicamentoSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(usuario=usuario)
            return Response(serializer.data, status=status.HTTP_201_CREATED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    def retrieve(self, request, pk=None):
        usuario, err = _get_usuario(request)
        if err:
            return err

        try:
            reg = RegistroMedicamentos.objects.get(id=pk, usuario=usuario)
        except RegistroMedicamentos.DoesNotExist:
            return Response(
                {"error": "Registro no encontrado"},
                status=status.HTTP_404_NOT_FOUND,
            )

        return Response(RegistroMedicamentoSerializer(reg).data)

    def partial_update(self, request, pk=None):
        usuario, err = _get_usuario(request)
        if err:
            return err

        try:
            reg = RegistroMedicamentos.objects.get(id=pk, usuario=usuario)
        except RegistroMedicamentos.DoesNotExist:
            return Response(
                {"error": "Registro no encontrado"},
                status=status.HTTP_404_NOT_FOUND,
            )

        serializer = RegistroMedicamentoSerializer(reg, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    # ── Acción extra: registros de hoy ────────────────────────────────────────

    @action(detail=False, methods=['get'], url_path='hoy')
    def hoy(self, request):
        from datetime import date
        usuario, err = _get_usuario(request)
        if err:
            return err

        registros = (
            RegistroMedicamentos.objects
            .filter(usuario=usuario, fecha=date.today())
            .order_by('hora')
        )
        return Response(RegistroMedicamentoListSerializer(registros, many=True).data)

    # ── Acción extra: adherencia últimos 7 días ───────────────────────────────

    @action(detail=False, methods=['get'], url_path='adherencia')
    def adherencia(self, request):
        from datetime import date, timedelta
        usuario, err = _get_usuario(request)
        if err:
            return err

        hace_7 = date.today() - timedelta(days=7)
        registros = RegistroMedicamentos.objects.filter(
            usuario=usuario,
            fecha__gte=hace_7,
        )

        total   = registros.count()
        tomados = registros.filter(fue_tomado=1).count()

        return Response({
            "total":      total,
            "tomados":    tomados,
            "omitidos":   total - tomados,
            "porcentaje": round((tomados / total * 100), 1) if total > 0 else 0,
        })