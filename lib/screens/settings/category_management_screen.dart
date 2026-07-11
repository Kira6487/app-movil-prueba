import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/app_icon_mapper.dart';
import '../../utils/date_utils.dart';
import '../../widgets/buttons/app_primary_button.dart';
import '../../widgets/buttons/app_secondary_button.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/app_scaffold.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/inputs/color_palette_field.dart';
import '../../widgets/inputs/icon_palette_field.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final _service = CategoryService();
  int _reloadKey = 0;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: CategoryScope.editableValues.length,
      child: AppScaffold(
        title: 'Categorías',
        children: [
          const AppCard(
            child: TabBar(
              tabs: [
                Tab(text: 'Gastos'),
                Tab(text: 'Ingresos'),
                Tab(text: 'Ahorros'),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.72,
            child: TabBarView(
              children: [
                for (final type in CategoryScope.editableValues)
                  _CategoryTypeView(
                    key: ValueKey('$type-$_reloadKey'),
                    type: type,
                    service: _service,
                    onChanged: _reload,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _reload() => setState(() => _reloadKey += 1);
}

class _CategoryTypeView extends StatefulWidget {
  const _CategoryTypeView({
    super.key,
    required this.type,
    required this.service,
    required this.onChanged,
  });

  final String type;
  final CategoryService service;
  final VoidCallback onChanged;

  @override
  State<_CategoryTypeView> createState() => _CategoryTypeViewState();
}

class _CategoryTypeViewState extends State<_CategoryTypeView> {
  late Future<List<CategoryModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CategoryModel>> _load() {
    return widget.service.getCategoriesByType(widget.type, activeOnly: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CategoryModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const EmptyState(
            title: 'No se pudo cargar categorías',
            message: 'Revisa la base local e intenta nuevamente.',
            icon: Icons.error_outline,
          );
        }
        final categories = snapshot.data ?? const [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 14),
            AppPrimaryButton(
              label: 'Nueva categoría',
              icon: Icons.add,
              onPressed: () => _openEditor(context),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: categories.isEmpty
                  ? const EmptyState(
                      title: 'Sin categorías',
                      message: 'Crea la primera para este grupo.',
                      icon: Icons.category_outlined,
                    )
                  : AppCard(
                      child: ReorderableListView.builder(
                        itemCount: categories.length,
                        onReorderItem: (oldIndex, newIndex) =>
                            _reorder(categories, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryTile(
                            key: ValueKey(category.id),
                            category: category,
                            onEdit: () => _openEditor(context, category),
                            onDelete: () => _delete(category),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    CategoryModel? initial,
  ]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => _CategoryEditorDialog(
        type: widget.type,
        initial: initial,
        service: widget.service,
      ),
    );
    if (saved == true) {
      _refresh();
      widget.onChanged();
    }
  }

  Future<void> _delete(CategoryModel category) async {
    final usage = await widget.service.usageCount(category.id!);
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usage > 0 ? 'Desactivar categoría' : 'Eliminar categoría'),
        content: Text(
          usage > 0
              ? 'Esta categoría ya tiene movimientos o reglas relacionadas. Se desactivará para nuevos formularios y seguirá visible en historiales.'
              : 'Esta categoría no tiene uso registrado y puede eliminarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(usage > 0 ? 'Desactivar' : 'Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.service.deleteOrDeactivateCategory(category.id!);
    _refresh();
    widget.onChanged();
  }

  Future<void> _reorder(
    List<CategoryModel> categories,
    int oldIndex,
    int newIndex,
  ) async {
    final ordered = [...categories];
    final item = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, item);
    await widget.service.reorderCategories(
      widget.type,
      ordered.map((category) => category.id!).toList(),
    );
    _refresh();
  }

  void _refresh() => setState(() => _future = _load());
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = colorFromHex(category.colorHex);
    return ListTile(
      key: key,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.14),
        child: Icon(iconDataForId(category.iconKey), color: color),
      ),
      title: Text(category.name, style: AppTextStyles.cardTitle),
      subtitle: Text(
        category.isActive ? 'Activa' : 'Inactiva',
        style: AppTextStyles.muted,
      ),
      trailing: Wrap(
        spacing: 4,
        children: [
          IconButton(
            tooltip: 'Editar',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: category.isActive ? 'Eliminar o desactivar' : 'Eliminar',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: AppColors.red),
          ),
          const Icon(Icons.drag_handle),
        ],
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    required this.type,
    required this.service,
    this.initial,
  });

  final String type;
  final CategoryService service;
  final CategoryModel? initial;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late String _icon;
  late String _color;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.name ?? '');
    _icon = initial?.iconKey ?? 'wallet';
    _color = initial?.colorHex ?? '#005FD1';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.initial == null ? 'Nueva categoría' : 'Editar categoría'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 14),
            IconPaletteField(
              label: 'Ícono',
              value: _icon,
              color: colorFromHex(_color),
              onChanged: (value) => setState(() => _icon = value),
            ),
            const SizedBox(height: 14),
            ColorPaletteField(
              label: 'Color',
              value: _color,
              onChanged: (value) => setState(() => _color = value),
            ),
          ],
        ),
      ),
      actions: [
        AppSecondaryButton(
          label: 'Cancelar',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        ),
        AppPrimaryButton(
          label: _saving ? 'Guardando...' : 'Guardar',
          icon: Icons.save_outlined,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final initial = widget.initial;
    final category = CategoryModel(
      id: initial?.id,
      name: name,
      type: widget.type,
      iconKey: _icon,
      colorHex: _color,
      sortOrder: initial?.sortOrder ?? 0,
      isActive: initial?.isActive ?? true,
      createdAt: initial?.createdAt ?? AppDateUtils.nowIso(),
    );
    if (initial == null) {
      await widget.service.insertCategory(category);
    } else {
      await widget.service.updateCategory(category);
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
