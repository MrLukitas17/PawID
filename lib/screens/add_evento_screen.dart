import 'package:flutter/material.dart';
import '../models/evento.dart';
import '../models/pet.dart';
import '../services/calendario_service.dart';
import '../services/pet_storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/paw_text_field.dart';

class AddEventoScreen extends StatefulWidget {
  final String userId;
  final Evento? evento;
  final DateTime? fechaInicial;

  const AddEventoScreen({
    super.key,
    required this.userId,
    this.evento,
    this.fechaInicial,
  });

  @override
  State<AddEventoScreen> createState() => _AddEventoScreenState();
}

class _AddEventoScreenState extends State<AddEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _fechaController = TextEditingController();
  final _horaController = TextEditingController();

  String _tipo = 'control';
  String? _mascotaId;
  String _mascotaNombre = '';
  List<Pet> _mascotas = [];
  bool _isSaving = false;

  bool get _isEditing => widget.evento != null;

  final List<Map<String, String>> _tipos = [
    {'value': 'control', 'label': 'Control Veterinario', 'icon': '🏥'},
    {'value': 'vacuna', 'label': 'Vacuna', 'icon': '💉'},
    {'value': 'medicamento', 'label': 'Medicamento', 'icon': '💊'},
  ];

  @override
  void initState() {
    super.initState();
    _loadMascotas();
    if (_isEditing) {
      final e = widget.evento!;
      _tituloController.text = e.titulo;
      _descripcionController.text = e.descripcion;
      _fechaController.text = _formatFechaDisplay(e.fecha);
      _horaController.text = e.hora;
      _tipo = e.tipo;
      _mascotaId = e.mascotaId;
      _mascotaNombre = e.mascotaNombre;
    } else if (widget.fechaInicial != null) {
      final f = widget.fechaInicial!;
      _fechaController.text =
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year}';
    }
  }

  String _formatFechaDisplay(String fechaYMD) {
    try {
      final parts = fechaYMD.split('-');
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (_) {
      return fechaYMD;
    }
  }

  String _parseFechaToYMD(String fechaDMY) {
    try {
      final parts = fechaDMY.split('/');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    } catch (_) {
      return fechaDMY;
    }
  }

  Future<void> _loadMascotas() async {
    final mascotas = await PetStorageService.loadPets(userId: widget.userId);
    setState(() => _mascotas = mascotas);
    if (mascotas.isNotEmpty && _mascotaId == null) {
      _mascotaId = mascotas.first.id;
      _mascotaNombre = mascotas.first.name;
    }
  }

  Future<void> _pickFecha() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 3)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: AppColors.white,
            surface: AppColors.background,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _fechaController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _pickHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _horaController.text =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mascotaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una mascota'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final evento = Evento(
        id: _isEditing
            ? widget.evento!.id
            : DateTime.now().millisecondsSinceEpoch.toString(),
        usuarioId: widget.userId,
        mascotaId: _mascotaId!,
        mascotaNombre: _mascotaNombre,
        tipo: _tipo,
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fecha: _parseFechaToYMD(_fechaController.text.trim()),
        hora: _horaController.text.trim(),
        completado: _isEditing ? widget.evento!.completado : false,
      );

      if (_isEditing) {
        await CalendarioService.updateEvento(evento);
      } else {
        await CalendarioService.addEvento(evento);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Evento guardado'),
            backgroundColor: Color(0xFF00A3A3),
            duration: Duration(seconds: 1),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    _fechaController.dispose();
    _horaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Editar Evento' : 'Nuevo Evento',
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: Stack(
        children: [
          // Imagen de fondo fija
          Positioned.fill(
            child: Image.asset(
              'assets/images/editor_evento.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) =>
                  Container(color: const Color(0xFFE0F7FA)),
            ),
          ),

          // Contenido responsivo y dinámico
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 24,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.96),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tipo de evento
                              _sectionTitle('Tipo de Evento'),
                              const SizedBox(height: 12),
                              Row(
                                children: _tipos.map((t) {
                                  final selected = _tipo == t['value'];
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _tipo = t['value']!),
                                      child: Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? AppColors.primary
                                              : AppColors.primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.primary.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(t['icon']!, style: const TextStyle(fontSize: 18)),
                                            const SizedBox(height: 4),
                                            Text(
                                              t['label']!.split(' ').first,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: selected ? AppColors.white : AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                              const SizedBox(height: 20),
                              _sectionTitle('Mascota'),
                              const SizedBox(height: 4),

                              // Selector de mascota
                              _mascotas.isEmpty
                                  ? const Text('No tienes mascotas registradas',
                                  style: TextStyle(color: AppColors.textMedium))
                                  : DropdownButtonFormField<String>(
                                value: _mascotaId,
                                decoration: const InputDecoration(
                                  labelText: 'Mascota *',
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: AppColors.inputUnderline, width: 1.5)),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                      BorderSide(color: AppColors.primary, width: 2)),
                                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                                ),
                                dropdownColor: AppColors.background,
                                style: const TextStyle(
                                    color: AppColors.textDark, fontSize: 14),
                                items: _mascotas
                                    .map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                ))
                                    .toList(),
                                onChanged: (v) {
                                  setState(() {
                                    _mascotaId = v;
                                    _mascotaNombre = _mascotas
                                        .firstWhere((p) => p.id == v)
                                        .name;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),
                              _sectionTitle('Detalles'),
                              const SizedBox(height: 8),

                              PawTextField(
                                label: 'Título *',
                                hint: 'Ej: Vacuna antirrábica',
                                controller: _tituloController,
                                validator: (v) =>
                                v == null || v.isEmpty ? 'Campo requerido' : null,
                              ),
                              const SizedBox(height: 12),

                              PawTextField(
                                label: 'Descripción (opcional)',
                                hint: 'Notas adicionales...',
                                controller: _descripcionController,
                              ),
                              const SizedBox(height: 12),

                              // Fecha
                              GestureDetector(
                                onTap: _pickFecha,
                                child: AbsorbPointer(
                                  child: PawTextField(
                                    label: 'Fecha *',
                                    hint: 'Toca para seleccionar',
                                    controller: _fechaController,
                                    validator: (v) =>
                                    v == null || v.isEmpty ? 'Campo requerido' : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Hora
                              GestureDetector(
                                onTap: _pickHora,
                                child: AbsorbPointer(
                                  child: PawTextField(
                                    label: 'Hora (opcional)',
                                    hint: 'Toca para seleccionar',
                                    controller: _horaController,
                                  ),
                                ),
                              ),

                              // Fuerza al botón a quedarse abajo adaptándose al espacio de la pantalla
                              const Spacer(),
                              const SizedBox(height: 24),

                              _isSaving
                                  ? const Center(
                                  child: CircularProgressIndicator(color: AppColors.primary))
                                  : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(
                                    _isEditing ? 'Guardar Cambios' : 'Agregar Evento',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary));
}