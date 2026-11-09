import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/components/app_field.dart';
import '../../../../shared/theme/rumbo_colors.dart';
import '../../domain/entities/plan_entity.dart';
import '../../domain/entities/plan_input.dart';
import '../bloc/plans_bloc.dart';

/// Formulario de Plans: conserva el flujo de tres pasos del prototipo.
/// No crea un Plan de prueba ni escribe directamente a Supabase.
/// El BLoC delega a los casos de uso y repositorio.
class CreatePlanScreen extends StatefulWidget {
  const CreatePlanScreen({super.key, this.initial, this.onSaved});

  /// Si se envía un plan existente, el formulario permite editarlo.
  final PlanEntity? initial;
  final VoidCallback? onSaved;

  @override
  State<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends State<CreatePlanScreen> {
  int step = 0;
  late final TextEditingController title;
  late final TextEditingController place;
  late final TextEditingController description;
  late final TextEditingController minParticipants;
  late final TextEditingController maxParticipants;
  late final TextEditingController budget;
  late final TextEditingController distance;

  DateTime? startsAt;
  int? activityTypeId;
  PlanMode mode = PlanMode.public;
  PlanDifficulty? difficulty;
  bool free = true;
  bool _submitted = false;

  bool get _isPublished => widget.initial?.status == PlanStatus.published;
  bool get _isReadOnly =>
      widget.initial?.status == PlanStatus.cancelled ||
      widget.initial?.status == PlanStatus.finished;
  bool get _canSaveDraft =>
      widget.initial == null || widget.initial?.status == PlanStatus.draft;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    title = TextEditingController(text: initial?.title ?? '');
    place = TextEditingController(text: initial?.place ?? '');
    description = TextEditingController(text: initial?.description ?? '');
    minParticipants = TextEditingController(
      text: initial?.minParticipants?.toString() ?? '',
    );
    maxParticipants = TextEditingController(
      text: initial?.maxParticipants?.toString() ?? '',
    );
    final initialBudget = initial?.budgetPerPerson;
    budget = TextEditingController(
      text: initialBudget == null || initialBudget == 0
          ? ''
          : initialBudget.toStringAsFixed(0),
    );
    distance = TextEditingController(
      text: initial?.distanceKm?.toString() ?? '',
    );
    startsAt = initial?.startsAt?.toLocal();
    activityTypeId = initial?.activityTypeId;
    mode = initial?.mode ?? PlanMode.public;
    difficulty = initial?.difficulty;
    free = initial?.budgetPerPerson == null || initial?.budgetPerPerson == 0;
  }

  @override
  void dispose() {
    for (final controller in [
      title,
      place,
      description,
      minParticipants,
      maxParticipants,
      budget,
      distance,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _chooseStartDate() async {
    if (_isReadOnly) return;
    final now = DateTime.now();
    final chosenDate = await showDatePicker(
      context: context,
      initialDate: startsAt != null && startsAt!.isAfter(now)
          ? startsAt!
          : now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (chosenDate == null || !mounted) return;
    final chosenTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        startsAt ?? DateTime(now.year, now.month, now.day, 7),
      ),
    );
    if (chosenTime == null || !mounted) return;
    setState(() {
      startsAt = DateTime(
        chosenDate.year,
        chosenDate.month,
        chosenDate.day,
        chosenTime.hour,
        chosenTime.minute,
      );
    });
  }

  int? _optionalInt(TextEditingController controller, String label) {
    final value = controller.text.trim();
    if (value.isEmpty) return null;
    final parsed = int.tryParse(value);
    if (parsed == null)
      throw FormatException('$label debe ser un número entero.');
    return parsed;
  }

  double? _optionalDouble(TextEditingController controller, String label) {
    final value = controller.text.trim().replaceAll(',', '.');
    if (value.isEmpty) return null;
    final parsed = double.tryParse(value);
    if (parsed == null || !parsed.isFinite) {
      throw FormatException('$label debe ser un número válido.');
    }
    return parsed;
  }

  PlanInput _buildInput() => PlanInput(
    title: title.text,
    description: description.text,
    place: place.text,
    startsAt: startsAt,
    activityTypeId: activityTypeId,
    mode: mode,
    minParticipants: _optionalInt(minParticipants, 'Cupos mínimos'),
    maxParticipants: _optionalInt(maxParticipants, 'Cupos máximos'),
    budgetPerPerson: free ? 0 : _optionalDouble(budget, 'Presupuesto'),
    distanceKm: _optionalDouble(distance, 'Distancia'),
    difficulty: difficulty,
    imagePath: widget.initial?.imagePath,
  );

  void _submit({required bool publish}) {
    if (_isReadOnly) return;
    try {
      final input = _buildInput();
      input.validate(publish: publish);
      _submitted = true;
      context.read<PlansBloc>().add(
        PlansSaveRequested(
          id: widget.initial?.id,
          input: input,
          publish: publish,
        ),
      );
    } on FormatException catch (e) {
      _showMessage(e.message);
    } on ArgumentError catch (e) {
      _showMessage(e.message?.toString() ?? 'Revisa los datos del plan.');
    }
  }

  void _handleStateChange(BuildContext context, PlansState state) {
    if (!_submitted) return;
    _submitted = false;
    if (state.error != null) {
      _showMessage(state.error!);
      return;
    }
    if (state.message == null) return;
    _showMessage(state.message!);
    if (widget.initial == null) {
      // IndexedStack conserva la pestaña Crear, incluso después de navegar.
      // Se limpia solo tras guardar correctamente en Supabase.
      title.clear();
      place.clear();
      description.clear();
      minParticipants.clear();
      maxParticipants.clear();
      budget.clear();
      distance.clear();
      setState(() {
        step = 0;
        startsAt = null;
        activityTypeId = null;
        mode = PlanMode.public;
        difficulty = null;
        free = true;
      });
    }
    if (widget.onSaved != null) {
      widget.onSaved!();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PlansBloc, PlansState>(
      listenWhen: (before, after) =>
          _submitted && before.saving && !after.saving,
      listener: _handleStateChange,
      child: BlocBuilder<PlansBloc, PlansState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
          children: [
            Text(
              widget.initial == null ? 'Crear un plan' : 'Editar plan',
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (step + 1) / 3,
              minHeight: 5,
              borderRadius: BorderRadius.circular(10),
              color: RumboColors.guayacan,
            ),
            const SizedBox(height: 20),
            if (_isReadOnly)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Este plan ya no se puede editar.'),
                ),
              ),
            if (step == 0) _essentials(),
            if (step == 1) _details(state),
            if (step == 2) _review(state),
            const SizedBox(height: 18),
            if (state.saving) const LinearProgressIndicator(),
            if (state.error != null && !state.saving)
              Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            if (step < 2)
              FilledButton(
                onPressed: state.saving ? null : () => setState(() => step++),
                child: const Text('Continuar'),
              ),
            if (step == 2)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: RumboColors.guayacan,
                  foregroundColor: RumboColors.tinta,
                ),
                onPressed: (state.saving || _isReadOnly)
                    ? null
                    : () => _submit(publish: true),
                child: Text(_isPublished ? 'Guardar cambios' : 'Publicar plan'),
              ),
            if (_canSaveDraft) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: state.saving ? null : () => _submit(publish: false),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar borrador'),
              ),
            ],
            if (step > 0) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: state.saving ? null : () => setState(() => step--),
                child: const Text('Atrás'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _essentials() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Lo esencial',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 14),
      AppField(
        controller: title,
        label: 'Nombre del plan',
        hint: 'Caminata al Cerro de la Bandera',
      ),
      AppField(
        controller: description,
        label: 'Descripción',
        hint: 'Cuenta cómo será la actividad…',
        maxLines: 4,
      ),
      AppField(controller: place, label: 'Lugar', hint: 'Pance, Cali'),
      OutlinedButton.icon(
        onPressed: _isReadOnly ? null : _chooseStartDate,
        icon: const Icon(Icons.calendar_today_outlined),
        label: Text(
          startsAt == null
              ? 'Seleccionar fecha y hora'
              : _formatDate(startsAt!),
        ),
      ),
      const SizedBox(height: 9),
      const Text(
        'Para guardar un borrador solo necesitas nombre, descripción y lugar.',
        style: TextStyle(fontSize: 12, color: RumboColors.musgo),
      ),
    ],
  );

  Widget _details(PlansState state) {
    final selectedActivity = state.activities.any((a) => a.id == activityTypeId)
        ? activityTypeId
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detalles de la actividad',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          value: selectedActivity,
          decoration: const InputDecoration(
            labelText: 'Tipo de actividad',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Selecciona una actividad'),
          items: state.activities
              .map(
                (activity) => DropdownMenuItem(
                  value: activity.id,
                  child: Text(activity.name),
                ),
              )
              .toList(),
          onChanged: _isReadOnly
              ? null
              : (value) => setState(() => activityTypeId = value),
        ),
        if (state.activities.isEmpty) ...[
          const SizedBox(height: 6),
          const Text(
            'No se cargó el catálogo de actividades.',
            style: TextStyle(color: RumboColors.musgo, fontSize: 12),
          ),
          TextButton(
            onPressed: () =>
                context.read<PlansBloc>().add(const PlansRefreshRequested()),
            child: const Text('Reintentar'),
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Dificultad (opcional)',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _difficultyChip(null, 'Sin especificar'),
            _difficultyChip(PlanDifficulty.easy, 'Suave'),
            _difficultyChip(PlanDifficulty.medium, 'Media'),
            _difficultyChip(PlanDifficulty.hard, 'Exigente'),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Modalidad del plan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Público'),
              selected: mode == PlanMode.public,
              onSelected: (_isReadOnly || _isPublished)
                  ? null
                  : (_) => setState(() => mode = PlanMode.public),
            ),
            ChoiceChip(
              label: const Text('Privado · con aprobación'),
              selected: mode == PlanMode.private,
              onSelected: (_isReadOnly || _isPublished)
                  ? null
                  : (_) => setState(() => mode = PlanMode.private),
            ),
          ],
        ),
        if (difficulty == PlanDifficulty.hard && mode == PlanMode.public) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este plan es exigente. Recomendamos activar la aprobación '
                          'de participantes por seguridad.',
                        ),
                      ),
                    ],
                  ),
                  if (!_isReadOnly && !_isPublished)
                    TextButton(
                      onPressed: () => setState(() => mode = PlanMode.private),
                      child: const Text('Activar aprobación'),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cupos del plan',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _numberField(minParticipants, 'Mínimos')),
                    const SizedBox(width: 12),
                    Expanded(child: _numberField(maxParticipants, 'Máximos')),
                  ],
                ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Sin gastos previstos (gratis)'),
          subtitle: const Text('Presupuesto estimado por participante'),
          value: free,
          onChanged: _isReadOnly
              ? null
              : (value) => setState(() => free = value),
        ),
        if (!free)
          _numberField(budget, 'Presupuesto por persona (COP)', decimal: true),
        const SizedBox(height: 8),
        _numberField(
          distance,
          'Distancia aproximada (km) · opcional',
          decimal: true,
        ),
      ],
    );
  }

  Widget _difficultyChip(PlanDifficulty? value, String label) => ChoiceChip(
    label: Text(label),
    selected: difficulty == value,
    onSelected: _isReadOnly ? null : (_) => setState(() => difficulty = value),
  );

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool decimal = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      enabled: !_isReadOnly,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  Widget _review(PlansState state) {
    final activity = state.activities.where((a) => a.id == activityTypeId);
    final activityName = activity.isEmpty
        ? 'Actividad por definir'
        : activity.first.name;
    final budgetText = free
        ? 'Gratis'
        : budget.text.trim().isEmpty
        ? 'Pendiente'
        : '\$${budget.text.trim()} COP por persona';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Revisar y publicar',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 130,
                padding: const EdgeInsets.all(18),
                alignment: Alignment.bottomLeft,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [RumboColors.monte, RumboColors.monte2],
                  ),
                ),
                child: Text(
                  title.text.trim().isEmpty ? 'Sin título' : title.text.trim(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.text.trim().isEmpty
                          ? 'Lugar pendiente'
                          : place.text.trim(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      startsAt == null
                          ? 'Fecha pendiente'
                          : _formatDate(startsAt!),
                      style: const TextStyle(color: RumboColors.musgo),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        Chip(label: Text(activityName)),
                        Chip(
                          label: Text(
                            mode == PlanMode.public ? 'Público' : 'Privado',
                          ),
                        ),
                        Chip(
                          label: Text(
                            maxParticipants.text.trim().isEmpty
                                ? 'Cupos por definir'
                                : '${maxParticipants.text.trim()} cupos',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      budgetText,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (description.text.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(description.text.trim()),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'El plan solo será visible en Explorar después de publicarse.',
          style: TextStyle(color: RumboColors.musgo, fontSize: 12),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} · '
        '${two(date.hour)}:${two(date.minute)}';
  }
}
