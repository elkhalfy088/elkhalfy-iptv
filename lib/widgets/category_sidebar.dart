import 'package:flutter/material.dart';
import '../models/content_models.dart';
import '../theme.dart';

class CategorySidebar extends StatefulWidget {
  final List<Category> categories;
  final String selectedId;
  final bool isLoading;
  final ValueChanged<String> onSelect;

  const CategorySidebar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.isLoading,
    required this.onSelect,
  });

  @override
  State<CategorySidebar> createState() => _CategorySidebarState();
}

class _CategorySidebarState extends State<CategorySidebar> {
  String _search = '';
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<Category> get _filtered {
    if (_search.isEmpty) return widget.categories;
    final q = _search.toLowerCase();
    return widget.categories
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: AppTheme.bgSidebar,
      child: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _ctrl,
                style:
                    const TextStyle(color: Colors.white, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'بحث في الفئات...',
                  hintStyle: const TextStyle(
                      color: AppTheme.textSecondary, fontSize: 12),
                  prefixIcon: const Icon(Icons.search,
                      color: AppTheme.textSecondary, size: 16),
                  suffixIcon: _search.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppTheme.textSecondary, size: 16),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _search = '');
                          },
                          padding: EdgeInsets.zero,
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  filled: true,
                  fillColor: AppTheme.bgColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryColor, width: 1),
                  ),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
          ),
          const Divider(color: AppTheme.dividerColor, height: 1),
          // Loading
          if (widget.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(
                    color: AppTheme.primaryColor, strokeWidth: 2),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  // "All" item
                  _CategoryItem(
                    label: 'الكل',
                    count: widget.categories.length,
                    selected: widget.selectedId == 'all',
                    onTap: () => widget.onSelect('all'),
                    isAll: true,
                  ),
                  ..._filtered.map((cat) => _CategoryItem(
                        label: cat.name,
                        count: cat.count,
                        selected: widget.selectedId == cat.id,
                        onTap: () => widget.onSelect(cat.id),
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final bool isAll;

  const _CategoryItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.isAll = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor.withOpacity(0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            if (isAll)
              const Icon(Icons.grid_view_rounded,
                  size: 14, color: AppTheme.primaryColor)
            else
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.primaryColor : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
