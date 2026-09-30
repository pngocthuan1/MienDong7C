import 'dart:async';
import 'package:flutter/material.dart';
import 'package:benhvien7c/core/utils/StringUtils.dart';

class PickerItem<T> {
  final String title;
  final String? subtitle;
  final String? searchKey;
  /// Pre-computed normalized search key (Vietnamese diacritics removed, lowercased).
  /// Set once at ListMaster load time via [preComputeSearchKeys] and reused
  /// across all modal opens — avoids expensive per-open normalization.
  String? _cachedNormalizedKey;
  final T value;

  PickerItem({
    required this.title,
    this.subtitle,
    this.searchKey,
    required this.value,
  });

  /// Get the normalized search key (computed lazily once, then cached).
  String get normalizedKey {
    return _cachedNormalizedKey ??= removeVietnameseDiacritics(
      '$title ${subtitle ?? ''} ${searchKey ?? ''}',
    ).toLowerCase();
  }

  /// Pre-compute and cache the normalized search key.
  /// Call this once per item at load time (e.g., when ListMaster data arrives).
  void preComputeSearchKey() {
    _cachedNormalizedKey ??= removeVietnameseDiacritics(
      '$title ${subtitle ?? ''} ${searchKey ?? ''}',
    ).toLowerCase();
  }

  /// Batch pre-compute search keys for a list of items.
  /// Call once when data is loaded from server to avoid per-modal-open computation.
  static void preComputeSearchKeys<T>(List<PickerItem<T>> items) {
    for (final item in items) {
      item.preComputeSearchKey();
    }
  }
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
  Timer? _debounceTimer;

  /// ValueNotifier cho danh sách đã lọc — chỉ rebuild ListView, không rebuild
  /// toàn bộ modal (header, search bar, etc.)
  late final ValueNotifier<List<PickerItem<T>>> _filteredNotifier;

  @override
  void initState() {
    super.initState();
    _filteredNotifier = ValueNotifier<List<PickerItem<T>>>(widget.items);
  }

  @override
  void didUpdateWidget(covariant SearchablePickerModal<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _filteredNotifier.value = widget.items;
    }
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 280), () {
      if (mounted) {
        _filterItems(val);
      }
    });
  }

  void _filterItems(String query) {
    final clean = query.trim();
    if (clean.isEmpty) {
      _filteredNotifier.value = widget.items;
      return;
    }
    final queryNormalized = removeVietnameseDiacritics(clean).toLowerCase();
    _filteredNotifier.value = widget.items
        .where((item) => item.normalizedKey.contains(queryNormalized))
        .toList();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _filteredNotifier.dispose();
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
            RepaintBoundary(
              child: Padding(
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
                            _filteredNotifier.value = widget.items;
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
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: ValueListenableBuilder<List<PickerItem<T>>>(
                valueListenable: _filteredNotifier,
                builder: (context, filteredItems, _) {
                  if (filteredItems.isEmpty) {
                    return const Center(
                      child: Text(
                        'Không tìm thấy kết quả phù hợp',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      ),
                    );
                  }
                  return ListView.builder(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    // Thêm padding dưới bằng viewInsets.bottom để item cuối không bị bàn phím che
                    // Padding này nằm BÊN TRONG ListView, KHÔNG đẩy modal lên → không giật
                    padding: EdgeInsets.only(top: 4, bottom: bottomInset),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
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
