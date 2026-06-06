from django.core.management.base import BaseCommand
from analitica_ia.services.train_model import entrenar_modelo_global

class Command(BaseCommand):
    help = 'Entrena el modelo de Machine Learning global con todos los datos de AnalisisGlucosa'

    def handle(self, *args, **kwargs):
        self.stdout.write(self.style.NOTICE('Iniciando entrenamiento del modelo global...'))
        
        resultado = entrenar_modelo_global()
        
        if resultado:
            self.stdout.write(
                self.style.SUCCESS(
                    f'Entrenamiento exitoso.\n'
                    f'- Registros usados: {resultado["registros_usados"]}\n'
                    f'- MAE (Error Medio Absoluto): {resultado["mae"]:.4f}'
                )
            )
        else:
            self.stdout.write(
                self.style.ERROR('Error: Insufficient global dataset (se requieren al menos 100 registros).')
            )
