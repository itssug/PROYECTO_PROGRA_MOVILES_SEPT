from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

from .serializers import PrediccionSerializer
from .services.predictor import PredictorGlucosa
from .services.train_model import entrenar_modelo_usuario
from .services.pattern_discovery import generar_patrones_usuario

class TrainModelView(APIView):
    def post(self, request, usuario_id):
        resultado = entrenar_modelo_usuario(usuario_id)
        if not resultado:
            return Response(
                {"error": "No hay suficientes datos para entrenar el modelo."},
                status=status.HTTP_400_BAD_REQUEST
            )
        return Response(
            {"status": "success", "metricas": resultado},
            status=status.HTTP_200_OK
        )

class GeneratePatternsView(APIView):
    def post(self, request, usuario_id):
        resultado = generar_patrones_usuario(usuario_id)
        if "error" in resultado:
            return Response(resultado, status=status.HTTP_400_BAD_REQUEST)
        return Response(resultado, status=status.HTTP_200_OK)


class PrediccionGlucosaView(APIView):
    def post(self, request, usuario_id):
        serializer = PrediccionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            predictor = PredictorGlucosa(usuario_id)
        except FileNotFoundError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        glucosa = predictor.predecir(
            serializer.validated_data["glucosa_antes"],
            serializer.validated_data["carbohidratos"],
            serializer.validated_data["carga_glucemica"],
            serializer.validated_data["horas_sueno"],
            serializer.validated_data["estres"],
            serializer.validated_data["ejercicio"]
        )

        if glucosa < 140:
            riesgo = "BAJO"
        elif glucosa < 180:
            riesgo = "MEDIO"
        else:
            riesgo = "ALTO"

        return Response(
            {
                "glucosa_predicha": glucosa,
                "riesgo": riesgo
            },
            status=status.HTTP_200_OK
        )