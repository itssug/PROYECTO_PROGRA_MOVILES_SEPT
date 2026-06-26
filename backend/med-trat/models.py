# Los modelos viven en core/models.py
# Esta app los importa directamente desde ahí — no se redefinen.

from core.models import Medicamentos, RegistroMedicamentos

__all__ = ['Medicamentos', 'RegistroMedicamentos']