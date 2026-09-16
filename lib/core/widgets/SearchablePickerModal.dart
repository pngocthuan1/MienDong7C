import 'dart:async';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/utils/StringUtils.dart';

class PickerItem<T> {
  final String title;
  final String? subtitle;
  final String? searchKey;
  final T value;

  const PickerItem({
    required this.title,
    this.subtitle,
    this.searchKey,
    required this.value,
  });
}

class _SearchableItem<T> {
  final PickerItem<T> item;
  final String normalizedSearchKey;

  _SearchableItem(this.item)
      : normalizedSearchKey = item.searchKey != null && item.searchKey!.isNotEmpty
            ? item.searchKey!.toLowerCase()
            : removeVietnameseDiacritics(
                '${item.title} ${item.subtitle ?? ''}',
              ).toLowerCase();
}

class SearchablePickerModal<T> extends StatefulWidget {
  const SearchablePickerModal({
    required this.title,
    required this.items,
    this.hintText = 'Nhập từ khóa tìm kiếm...',
    this.selectedItem,
    super.key,
  });

  final String title;
  final List<PickerItem<T>> items;
  final String hintText;
  final T? selectedItem;

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<PickerItem<T>> items,
    String hintText = 'Nhập từ khóa tìm kiếm...',
    T? selectedItem,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SearchablePickerModal<T>(
        title: title,
        items: items,
        hintText: hintText,
        selectedItem: selectedItem,
      ),
    );
  }

  @override
  State<SearchablePickerModal<T>> createState() => _SearchablePickerModalState<T>();
}

class _SearchablePickerModalState<T> extends State<SearchablePickerModal<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<_SearchableItem<T>> _preparedItems = [];
  List<PickerItem<T>> _filteredItems = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _prepareItems();
  }

  @override
  void didUpdateWidget(covariant SearchablePickerModal<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _preparedItems.clear();
      _filteredItems = widget.items;
      _prepareItems();
    }
  }

  void _prepareItems() {
    if (_preparedItems.length == widget.items.length) return;
    _preparedItems = widget.items.map((item) => _SearchableItem(item)).toList();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 60), () {
      if (mounted) {
        setState(() {
          _filterItems(val);
        });
      }
    });
  }

  void _filterItems(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      _filteredItems = widget.items;
      return;
    }
    if (_preparedItems.length != widget.items.length) {
      _prepareItems();
    }
    final queryNormalized = removeVietnameseDiacritics(clean).toLowerCase();
    _filteredItems = _preparedItems
        .where((prep) => prep.normalizedSearchKey.contains(queryNormalized))
        .map((prep) => prep.item)
        .toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    // Cố định chiều cao modal 80% màn hình — KHÔNG dùng Padding(bottom: bottomInset) ngoài
    // wrapper vì sẽ khiến toàn bộ modal bị đẩy lên/xuống mỗi frame bàn phím trượt → giật lag.
    // Thay vào đó, dùng padding bên trong ListView để chỉ vùng list tự thêm chỗ trống dưới đáy.
    final modalHeight = screenHeight * 0.80;

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: modalHeight,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, value, child) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _debounceTimer?.cancel();
                          setState(() {
                            _filterItems('');
                          });
                        },
                      );
                    },
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        'Không tìm thấy kết quả phù hợp',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      // Thêm padding dưới bằng viewInsets.bottom để item cuối không bị bàn phím che
                      // Padding này nằm BÊN TRONG ListView, KHÔNG đẩy modal lên → không giật
                      padding: EdgeInsets.only(top: 4, bottom: bottomInset),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = widget.selectedItem == item.value;

                        // Sử dụng InkWell + Container thay vì ListTile để loại bỏ hoàn toàn
                        // exception "ListTile background color or ink splashes may be invisible"
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop(item.value);
                            },
                            child: Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                            color: isSelected ? const Color(0xFF0D6EFD) : const Color(0xFF1E293B),
                                          ),
                                        ),
                                        if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            item.subtitle!,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF0D6EFD), size: 22),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
