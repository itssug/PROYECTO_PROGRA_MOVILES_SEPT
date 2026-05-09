// ============================================================
// ARCHIVO: lib/screens/usuarios/perfil.dart
// ============================================================
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/perfil_service.dart';
import '../app_colors.dart';

class PerfilScreen extends StatefulWidget {
  final VoidCallback? onPerfilActualizado;

  const PerfilScreen({super.key, this.onPerfilActualizado});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _editando = false;
  bool _cargando = false;
  late Map<String, dynamic> _datosEditables;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    _datosEditables = Map.from(AuthService.usuario ?? {});
  }

  Future<void> _guardarCambios() async {
    setState(() => _cargando = true);
    try {
      // Obtener solo los campos que cambiaron
      final cambios = <String, dynamic>{};
      for (var key in _datosEditables.keys) {
        if (_datosEditables[key] != AuthService.usuario?[key]) {
          cambios[key] = _datosEditables[key];
        }
      }

      if (cambios.isNotEmpty) {
        await PerfilService.updatePerfil(cambios);
        widget.onPerfilActualizado?.call();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      
      setState(() {
        _editando = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = AuthService.usuario ?? {};

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con avatar
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.orange,
                      child: Text(
                        usuario['nombre']?.isNotEmpty == true
                            ? usuario['nombre'][0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      usuario['nombre'] ?? 'Usuario',
                      style: const TextStyle(
                        color: AppColors.textPrim,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      usuario['email'] ?? '',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_editando)
                      ElevatedButton.icon(
                        onPressed: () {
                          _cargarDatos();
                          setState(() => _editando = true);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Editar perfil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Información del perfil
              const Text(
                'Información Personal',
                style: TextStyle(
                  color: AppColors.textPrim,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              _ProfileInfoRow(
                label: 'ID',
                value: '${usuario['id'] ?? 'N/A'}',
              ),
              _ProfileInfoRow(
                label: 'Nombre',
                value: usuario['nombre'] ?? 'No registrado',
                editable: _editando,
                onEditText: (valor) {
                  setState(() {
                    _datosEditables['nombre'] = valor;
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'Email',
                value: usuario['email'] ?? 'No registrado',
                editable: _editando,
                onEditText: (valor) {
                  setState(() {
                    _datosEditables['email'] = valor;
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'Sexo',
                value: _getSexoTexto(usuario['sexo']),
                editable: _editando,
                onEdit: (valor) {
                  setState(() {
                    _datosEditables['sexo'] = valor;
                  });
                },
                options: const ['masculino', 'femenino', 'otro'],
                optionLabels: const ['Masculino', 'Femenino', 'Otro'],
              ),
              _ProfileInfoRow(
                label: 'Peso',
                value: usuario['peso'] != null ? '${usuario['peso']} kg' : 'No registrado',
                editable: _editando,
                onEditNumber: (valor) {
                  setState(() {
                    _datosEditables['peso'] = double.tryParse(valor);
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'Altura',
                value: usuario['altura'] != null ? '${usuario['altura']} cm' : 'No registrado',
                editable: _editando,
                onEditNumber: (valor) {
                  setState(() {
                    _datosEditables['altura'] = double.tryParse(valor);
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'HbA1c',
                value: usuario['hba1c_inicial'] != null
                    ? '${usuario['hba1c_inicial']}%'
                    : 'No registrado',
                editable: _editando,
                onEditNumber: (valor) {
                  setState(() {
                    _datosEditables['hba1c_inicial'] = double.tryParse(valor);
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'Años diagnóstico',
                value: usuario['anios_diagnostico'] != null
                    ? '${usuario['anios_diagnostico']} años'
                    : 'No registrado',
                editable: _editando,
                onEditNumber: (valor) {
                  setState(() {
                    _datosEditables['anios_diagnostico'] = int.tryParse(valor);
                  });
                },
              ),
              _ProfileInfoRow(
                label: 'Nivel actividad',
                value: _getActividadTexto(usuario['nivel_actividad_base']),
                editable: _editando,
                onEdit: (valor) {
                  setState(() {
                    _datosEditables['nivel_actividad_base'] = valor;
                  });
                },
                options: const ['sedentario', 'moderado', 'activo'],
                optionLabels: const ['Sedentario', 'Moderado', 'Activo'],
              ),

              const SizedBox(height: 24),

              if (_editando) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _editando = false;
                            _cargarDatos();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cargando ? null : _guardarCambios,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _cargando
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Guardar cambios'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _getSexoTexto(String? sexo) {
    switch (sexo) {
      case 'masculino':
        return 'Masculino';
      case 'femenino':
        return 'Femenino';
      case 'otro':
        return 'Otro';
      default:
        return 'No especificado';
    }
  }

  String _getActividadTexto(String? nivel) {
    switch (nivel) {
      case 'sedentario':
        return 'Sedentario';
      case 'moderado':
        return 'Moderado';
      case 'activo':
        return 'Activo';
      default:
        return 'No especificado';
    }
  }
}

// ============================================================
// WIDGET PERFIL
// ============================================================

class _ProfileInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool editable;
  final Function(String)? onEdit;
  final Function(String)? onEditText;
  final Function(String)? onEditNumber;
  final List<String>? options;
  final List<String>? optionLabels;

  const _ProfileInfoRow({
    required this.label,
    required this.value,
    this.editable = false,
    this.onEdit,
    this.onEditText,
    this.onEditNumber,
    this.options,
    this.optionLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: editable
                ? _buildEditWidget()
                : Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrim,
                      fontSize: 14,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditWidget() {
    // Dropdown para opciones
    if (options != null && onEdit != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _getCurrentValue(),
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: AppColors.textPrim),
            items: options!.map((option) {
              final index = options!.indexOf(option);
              return DropdownMenuItem(
                value: option,
                child: Text(optionLabels?[index] ?? option),
              );
            }).toList(),
            onChanged: (valor) {
              if (valor != null) onEdit!(valor);
            },
          ),
        ),
      );
    }

    // TextField para texto normal
    if (onEditText != null) {
      return TextFormField(
        initialValue: value != 'No registrado' ? value : '',
        style: const TextStyle(color: AppColors.textPrim),
        decoration: _inputDecoration,
        onChanged: onEditText,
      );
    }

    // TextField para números
    return TextFormField(
      initialValue: value.replaceAll(' kg', '').replaceAll(' cm', '').replaceAll('%', '').replaceAll(' años', ''),
      style: const TextStyle(color: AppColors.textPrim),
      decoration: _inputDecoration,
      keyboardType: TextInputType.number,
      onChanged: onEditNumber,
    );
  }

  InputDecoration get _inputDecoration => InputDecoration(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.orange),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  String _getCurrentValue() {
    if (onEdit != null && options != null) {
      if (label == 'Sexo') {
        if (value == 'Masculino') return 'masculino';
        if (value == 'Femenino') return 'femenino';
        if (value == 'Otro') return 'otro';
      }
      if (label == 'Nivel actividad') {
        if (value == 'Sedentario') return 'sedentario';
        if (value == 'Moderado') return 'moderado';
        if (value == 'Activo') return 'activo';
      }
    }
    return options?.first ?? '';
  }
}