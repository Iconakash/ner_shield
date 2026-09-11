import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/field_report.dart';
import '../../repositories/field_reports_repository.dart';
import '../../shared/widgets/status_chip.dart';
import 'report_wizard_controller.dart';

/// Five-step field incident capture wizard (master prompt 26, 27).
///
/// Every transition goes through [ReportWizardController]; the draft is
/// validated against the NER coordinate bounds and submitted through the
/// repository, which queues offline drafts for later `/sync/push` - never
/// claiming server success when only the local save succeeded.
class ReportWizardScreen extends ConsumerStatefulWidget {
  const ReportWizardScreen({super.key});

  @override
  ConsumerState<ReportWizardScreen> createState() => _ReportWizardScreenState();
}

class _ReportWizardScreenState extends ConsumerState<ReportWizardScreen> {
  final _locationFormKey = GlobalKey<FormState>();

  late final TextEditingController _lonCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _segmentCtrl;
  late final TextEditingController _roadCtrl;
  late final TextEditingController _descCtrl;
  late final List<TextEditingController> _allControllers;

  @override
  void initState() {
    super.initState();
    _lonCtrl = TextEditingController();
    _latCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _districtCtrl = TextEditingController();
    _segmentCtrl = TextEditingController();
    _roadCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _allControllers = [
      _lonCtrl,
      _latCtrl,
      _nameCtrl,
      _stateCtrl,
      _districtCtrl,
      _segmentCtrl,
      _roadCtrl,
      _descCtrl,
    ];
    // The wizard provider is root-scoped; every open starts a clean draft.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(reportWizardProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportWizardProvider);
    final controller = ref.read(reportWizardProvider.notifier);
    final theme = Theme.of(context);
    final stepIndex = state.step.index;
    final total = ReportWizardStep.values.length;
    final hasResult = state.lastResult != null;

    return PopScope(
      canPop: hasResult || !_hasUnsavedWork(state),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final abandon = await _confirmAbandon(context);
        if (abandon && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Report incident - ${state.step.label}')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Semantics(
                label: 'Step ${stepIndex + 1} of $total: ${state.step.label}',
                child: LinearProgressIndicator(value: (stepIndex + 1) / total),
              ),
              const SizedBox(height: 6),
              Text(
                'Step ${stepIndex + 1} of $total',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 12),
              if (state.lastError != null && !hasResult)
                _InlineError(message: state.lastError!, onDismiss: null),
              _buildStep(state, controller),
              if (state.submitting)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: LinearProgressIndicator(),
                ),
              if (hasResult) ...[
                const SizedBox(height: 16),
                _ResultBanner(state: state),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: hasResult
                ? _SubmittedActions(
                    onDone: () => Navigator.of(context).maybePop(),
                  )
                : _buildFooter(state, controller),
          ),
        ),
      ),
    );
  }

  bool _hasUnsavedWork(ReportWizardState state) {
    final d = state.draft;
    return d.incidentType != null ||
        d.severity != null ||
        d.lon != null ||
        d.lat != null ||
        (d.description?.isNotEmpty ?? false);
  }

  Future<bool> _confirmAbandon(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard this report?'),
        content: const Text(
          'The draft has not been submitted. Going back now will discard '
          'what you have entered so far.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildStep(
    ReportWizardState state,
    ReportWizardController controller,
  ) {
    switch (state.step) {
      case ReportWizardStep.incidentType:
        return _TypeStep(
          selected: state.draft.incidentType,
          onSelect: controller.setIncidentType,
        );
      case ReportWizardStep.severity:
        return _SeverityStep(
          selected: state.draft.severity,
          onSelect: controller.setSeverity,
        );
      case ReportWizardStep.location:
        return _buildLocationStep(controller);
      case ReportWizardStep.description:
        return _buildDescriptionStep(controller);
      case ReportWizardStep.review:
        return _ReviewStep(state: state);
    }
  }

  Widget _buildLocationStep(ReportWizardController controller) {
    final theme = Theme.of(context);
    return Form(
      key: _locationFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Where did you observe it?', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Enter the coordinates captured on site. The NER region spans '
            'longitude 80 to 98 and latitude 21 to 29.5.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _lonCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Longitude',
                    hintText: 'e.g. 91.7362',
                  ),
                  validator: (v) => _validateCoord(v, isLongitude: true),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _latCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Latitude',
                    hintText: 'e.g. 26.1445',
                  ),
                  validator: (v) => _validateCoord(v, isLongitude: false),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Location name (optional)',
              hintText: 'e.g. NH-15 near Bongaigaon',
            ),
            onChanged: (_) => _pushLocation(controller),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'State code (optional)',
                  ),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _districtCtrl,
                  decoration: const InputDecoration(
                    labelText: 'District (optional)',
                  ),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _segmentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Segment ID (optional)',
                  ),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _roadCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Road code (optional)',
                  ),
                  onChanged: (_) => _pushLocation(controller),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _validateCoord(String? value, {required bool isLongitude}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Required';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Enter a number';
    final inRange = isLongitude
        ? (parsed >= 80 && parsed <= 98)
        : (parsed >= 21 && parsed <= 29.5);
    if (!inRange) {
      return isLongitude ? 'Must be 80-98' : 'Must be 21-29.5';
    }
    return null;
  }

  void _pushLocation(ReportWizardController controller) {
    final lon = double.tryParse(_lonCtrl.text.trim());
    final lat = double.tryParse(_latCtrl.text.trim());
    if (lon == null || lat == null) return;
    if (!FieldReport.withinBounds(lon: lon, lat: lat)) return;
    controller.setLocation(
      lon: lon,
      lat: lat,
      locationName: _nameCtrl.text.trim(),
      stateCode: _stateCtrl.text.trim(),
      districtCode: _districtCtrl.text.trim(),
      segmentId: _segmentCtrl.text.trim(),
      roadCode: _roadCtrl.text.trim(),
    );
  }

  Widget _buildDescriptionStep(ReportWizardController controller) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Describe what you observed', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        TextFormField(
          controller: _descCtrl,
          minLines: 4,
          maxLines: 8,
          maxLength: 2000,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            hintText: 'What happened, estimated scale, nearby hazards.',
            alignLabelWithHint: true,
          ),
          onChanged: controller.setDescription,
        ),
      ],
    );
  }

  Widget _buildFooter(
    ReportWizardState state,
    ReportWizardController controller,
  ) {
    final isReview = state.step == ReportWizardStep.review;
    final enabled = controller.canAdvance && !state.submitting;
    return Row(
      children: [
        if (state.step.index > 0)
          OutlinedButton.icon(
            onPressed: state.submitting ? null : controller.previous,
            icon: const Icon(Icons.chevron_left),
            label: const Text('Back'),
          )
        else
          TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
        const Spacer(),
        FilledButton.icon(
          onPressed: enabled
              ? (isReview ? controller.submit : controller.next)
              : null,
          icon: Icon(isReview ? Icons.send_outlined : Icons.chevron_right),
          label: Text(isReview ? 'Submit report' : 'Next'),
        ),
      ],
    );
  }
}

/// Step 1 — incident type picker (backend enum: LANDSLIDE | FLOOD |
/// ROAD_DAMAGE | TRAFFIC_BLOCKAGE | BRIDGE_PROBLEM | OTHER).
class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  static const _icons = <String, IconData>{
    'LANDSLIDE': Icons.landslide_outlined,
    'FLOOD': Icons.water_damage_outlined,
    'ROAD_DAMAGE': Icons.construction_outlined,
    'TRAFFIC_BLOCKAGE': Icons.traffic_outlined,
    'BRIDGE_PROBLEM': Icons.engineering_outlined,
    'OTHER': Icons.report_problem_outlined,
  };

  static const _labels = <String, String>{
    'LANDSLIDE': 'Landslide',
    'FLOOD': 'Flood / waterlogging',
    'ROAD_DAMAGE': 'Road damage',
    'TRAFFIC_BLOCKAGE': 'Traffic blockage',
    'BRIDGE_PROBLEM': 'Bridge problem',
    'OTHER': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What did you observe?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        ...kIncidentTypes.map((type) {
          final isSel = selected == type;
          final scheme = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              button: true,
              selected: isSel,
              child: Card(
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSel ? scheme.primary : scheme.outlineVariant,
                    width: isSel ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  leading: Icon(_icons[type]),
                  title: Text(_labels[type] ?? type),
                  trailing: isSel
                      ? Icon(Icons.check_circle, color: scheme.primary)
                      : null,
                  onTap: () => onSelect(type),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

/// Step 2 — severity picker (LOW | MEDIUM | HIGH | CRITICAL). Severity is
/// never communicated by color alone: label + icon accompany every option.
class _SeverityStep extends StatelessWidget {
  const _SeverityStep({required this.selected, required this.onSelect});

  final String? selected;
  final ValueChanged<String> onSelect;

  static const _colors = <String, Color>{
    'LOW': Color(0xFF2E6B34),
    'MEDIUM': Color(0xFF9A6A00),
    'HIGH': Color(0xFFB45309),
    'CRITICAL': Color(0xFFBA1A1A),
  };

  static const _icons = <String, IconData>{
    'LOW': Icons.info_outline,
    'MEDIUM': Icons.warning_amber_outlined,
    'HIGH': Icons.warning_outlined,
    'CRITICAL': Icons.dangerous_outlined,
  };

  static const _labels = <String, String>{
    'LOW': 'Low',
    'MEDIUM': 'Medium',
    'HIGH': 'High',
    'CRITICAL': 'Critical',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How severe is it?',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          'Critical incidents page the emergency workflow immediately.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kSeverities.map((s) {
            final isSel = selected == s;
            return ChoiceChip(
              selected: isSel,
              label: Text(_labels[s] ?? s),
              avatar: Icon(_icons[s], size: 18, color: _colors[s]),
              onSelected: (_) => onSelect(s),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Step 5 — review everything before submit; no field is editable here.
class _ReviewStep extends StatelessWidget {
  const _ReviewStep({required this.state});

  final ReportWizardState state;

  @override
  Widget build(BuildContext context) {
    final d = state.draft;
    final theme = Theme.of(context);
    String? text(String? v) =>
        (v == null || v.isEmpty) ? null : v.replaceAll('_', ' ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review before submitting', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Reports go to the verification queue for your region.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _reviewRow(context, 'Incident type', text(d.incidentType)),
        _reviewRow(
          context,
          'Severity',
          null,
          valueWidget: d.severity == null
              ? null
              : SeverityVisuals.chip(d.severity!),
        ),
        if (d.lon != null && d.lat != null)
          _reviewRow(
            context,
            'Coordinates',
            '${d.lat!.toStringAsFixed(5)}, ${d.lon!.toStringAsFixed(5)}',
          ),
        _reviewRow(context, 'Location name', d.locationName),
        _reviewRow(context, 'State', d.stateCode),
        _reviewRow(context, 'District', d.districtCode),
        _reviewRow(context, 'Segment', d.segmentId),
        _reviewRow(context, 'Road', d.roadCode),
        _reviewRow(context, 'Description', d.description),
      ],
    );
  }

  Widget _reviewRow(
    BuildContext context,
    String label,
    String? value, {
    Widget? valueWidget,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child:
                valueWidget ??
                Text(
                  value ?? 'Not provided',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Post-submit outcome. Never claims server success for a local-only save:
/// SubmitLive -> server receipt; SubmitQueued -> explicit "will sync".
class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.state});

  final ReportWizardState state;

  @override
  Widget build(BuildContext context) {
    final result = state.lastResult;
    if (result == null) return const SizedBox.shrink();
    final (icon, color, title, detail) = switch (result) {
      SubmitLive(:final report) => (
        Icons.verified_outlined,
        const Color(0xFF1E7A3C),
        'Report received by the server',
        'Reference ${report.code ?? report.id}'
            '${report.status == null ? '' : ' - status ${report.status}'}',
      ),
      SubmitQueued(:final entry) => (
        Icons.cloud_upload_outlined,
        const Color(0xFF9A6A00),
        'Saved on this device',
        'It will sync automatically when connectivity allows'
            '${entry.lastError == null ? '' : ' (last attempt: ${entry.lastError})'}.',
      ),
    };
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(detail, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}

class _SubmittedActions extends StatelessWidget {
  const _SubmittedActions({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onDone,
        icon: const Icon(Icons.list_alt),
        label: const Text('View my reports'),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: scheme.errorContainer,
      child: ListTile(
        dense: true,
        leading: Icon(Icons.error_outline, color: scheme.error),
        title: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: scheme.onErrorContainer),
        ),
        trailing: onDismiss == null
            ? null
            : IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
      ),
    );
  }
}
