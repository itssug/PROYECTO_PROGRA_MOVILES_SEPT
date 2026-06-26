import 'package:flutter/material.dart';
import 'add_estado_emocional_screen.dart';
import 'add_registro_sueno_screen.dart';
import '../services/estado_sueno_service.dart';
import '../models/estado_emocional_model.dart';
import '../models/registro_sueno_model.dart';

class EstadoSuenoScreen extends StatefulWidget {
  final int usuarioId;
  const EstadoSuenoScreen({super.key, required this.usuarioId});

  @override
  State<EstadoSuenoScreen> createState() => _EstadoSuenoScreenState();
}

class _EstadoSuenoScreenState extends State<EstadoSuenoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<EstadoEmocional> _estados = [];
  List<RegistroSueno> _suenos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);
    final estados = await EstadoSuenoService.getEstados(widget.usuarioId);
    final suenos = await EstadoSuenoService.getSuenos(widget.usuarioId);
    setState(() {
      _estados = estados;
      _suenos = suenos;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Estado y Sueño',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFF6B35),
          labelColor: const Color(0xFFFF6B35),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Emocional'),
            Tab(text: 'Sueño'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFFFF6B35)),
            onPressed: () => _mostrarDialogoAgregar(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListaEstados(),
                _buildListaSueno(),
              ],
            ),
    );
  }

  Widget _buildListaEstados() {
    if (_estados.isEmpty) {
      return const Center(child: Text('Sin registros',
          style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _estados.length,
      itemBuilder: (ctx, i) => _EstadoCard(estado: _estados[i]),
    );
  }

  Widget _buildListaSueno() {
    if (_suenos.isEmpty) {
      return const Center(child: Text('Sin registros',
          style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _suenos.length,
      itemBuilder: (ctx, i) => _SuenoCard(sueno: _suenos[i]),
    );
  }

  void _mostrarDialogoAgregar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.mood, color: Color(0xFFFF6B35)),
            title: const Text('Registro emocional',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddEstadoEmocionalScreen(
                    usuarioId: widget.usuarioId,
                    onSaved: _cargarDatos),
              ));
            },
          ),
          ListTile(
            leading: const Icon(Icons.bedtime, color: Color(0xFFFF6B35)),
            title: const Text('Registro de sueño',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddRegistroSuenoScreen(
                    usuarioId: widget.usuarioId,
                    onSaved: _cargarDatos),
              ));
            },
          ),
        ]),
      ),
    );
  }
}

class _EstadoCard extends StatelessWidget {
  final EstadoEmocional estado;
  const _EstadoCard({required this.estado});

  Color get _colorEstres {
    if (estado.nivelEstres <= 3) return const Color(0xFF5DCAA5);
    if (estado.nivelEstres <= 6) return const Color(0xFFEF9F27);
    return const Color(0xFFE24B4A);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _colorEstres.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text('${estado.nivelEstres}',
              style: TextStyle(color: _colorEstres,
                  fontWeight: FontWeight.bold, fontSize: 16))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(estado.estado.toUpperCase(),
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 13)),
          if (estado.evento != null)
            Text(estado.evento!,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(estado.fecha,
              style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
        ])),
      ]),
    );
  }
}

class _SuenoCard extends StatelessWidget {
  final RegistroSueno sueno;
  const _SuenoCard({required this.sueno});

  Color get _colorCalidad {
    switch (sueno.calidad.toLowerCase()) {
      case 'excelente': return const Color(0xFF5DCAA5);
      case 'buena': return const Color(0xFF1D9E75);
      case 'regular': return const Color(0xFFEF9F27);
      default: return const Color(0xFFE24B4A);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.bedtime, color: _colorCalidad, size: 28),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${sueno.horasDormidas?.toStringAsFixed(1) ?? "?"} horas',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w600, fontSize: 13)),
          Text('${sueno.horaAcostarse ?? "?"} → ${sueno.horaDespertar ?? "?"}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          Text(sueno.fecha,
              style: const TextStyle(color: Color(0xFF444444), fontSize: 10)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _colorCalidad.withOpacity(0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(sueno.calidad,
              style: TextStyle(color: _colorCalidad, fontSize: 10,
                  fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}