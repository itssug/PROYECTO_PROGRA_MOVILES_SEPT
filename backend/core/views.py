import hashlib
import secrets
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

from .models import Usuarios, Objetivos
from .serializers import RegistroSerializer, LoginSerializer, UsuarioPublicoSerializer
from .token_model import TokenUsuario


class RegistroView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegistroSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        usuario = serializer.save()

        Objetivos.objects.create(
            usuario=usuario,
            glucosa_ayunas_min=80, glucosa_ayunas_max=130,
            glucosa_post_min=80,   glucosa_post_max=180,
            fecha_inicio=timezone.now().date(),
            activo=1,
        )

        token = TokenUsuario.crear(usuario)
        return Response({
            "token": token.key,
            "usuario": UsuarioPublicoSerializer(usuario).data,
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        usuario = serializer.validated_data['usuario']
        token = TokenUsuario.crear(usuario)
        return Response({
            "token": token.key,
            "usuario": UsuarioPublicoSerializer(usuario).data,
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        key = request.headers.get('Authorization', '').replace('Token ', '')
        TokenUsuario.objects.filter(key=key).delete()
        return Response({"mensaje": "Sesión cerrada."})


class PerfilView(APIView):
    permission_classes = [AllowAny]

    def _get_usuario(self, request):
        key = request.headers.get('Authorization', '').replace('Token ', '')
        try:
            t = TokenUsuario.objects.get(key=key)
            return Usuarios.objects.get(id=t.usuario_id)
        except (TokenUsuario.DoesNotExist, Usuarios.DoesNotExist):
            return None

    def get(self, request):
        usuario = self._get_usuario(request)
        if not usuario:
            return Response({"error": "Token inválido."}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(UsuarioPublicoSerializer(usuario).data)

    def put(self, request):
        usuario = self._get_usuario(request)
        if not usuario:
            return Response({"error": "Token inválido."}, status=status.HTTP_401_UNAUTHORIZED)
        serializer = UsuarioPublicoSerializer(usuario, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        serializer.save()
        return Response(serializer.data)