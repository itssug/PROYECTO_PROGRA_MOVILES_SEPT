from core.models import Alertas, Usuarios
from django.utils import timezone
from datetime import timedelta

class AlertasService:
    @staticmethod
    def crear_alerta(usuario_id, tipo, prioridad, titulo, mensaje, horas_delay=0):
        try:
            usuario = Usuarios.objects.get(id=usuario_id)
            fecha_alerta = timezone.now()
            if horas_delay > 0:
                fecha_alerta += timedelta(hours=horas_delay)

            Alerta = Alertas.objects.create(
                usuario=usuario,
                tipo=tipo,
                prioridad=prioridad,
                titulo=titulo,
                mensaje=mensaje,
                leido=0,
                fecha=fecha_alerta
            )
            return Alerta
        except Usuarios.DoesNotExist:
            print(f"Usuario con id {usuario_id} no existe.")
            return None

    @staticmethod
    def alerta_riesgo_ia(usuario_id, glucosa_predicha):
        titulo = "Predicción de Riesgo Alto"
        mensaje = f"Tu comida actual podría disparar tu glucosa a {glucosa_predicha} mg/dL. Considera reducir la porción o caminar 15 mins después de comer."
        return AlertasService.crear_alerta(usuario_id, "PREDICCION_IA", "ALTA", titulo, mensaje)

    @staticmethod
    def recordatorio_postprandial(usuario_id):
        titulo = "Control Postprandial"
        mensaje = "Han pasado aproximadamente 2 horas desde tu comida. Es un buen momento para medir tu glucosa y validar la predicción de la IA."
        return AlertasService.crear_alerta(usuario_id, "RECORDATORIO", "MEDIA", titulo, mensaje, horas_delay=2)

    @staticmethod
    def alerta_medicamento(usuario_id):
        titulo = "Adherencia a Medicamentos"
        mensaje = "No hemos detectado el registro de tus medicamentos para esta comida. Recuerda que tomarlos a tiempo es vital para tu control metabólico."
        return AlertasService.crear_alerta(usuario_id, "MEDICAMENTO", "ALTA", titulo, mensaje)
