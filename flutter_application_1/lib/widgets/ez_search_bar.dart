import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/global_search_service.dart';
import 'ez_header.dart';

/// ช่องค้นหาทรงแคปซูลแบบเดียวกับหน้าแรก (ใช้ซ้ำได้ทุกหน้า)
class EzSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  const EzSearchField({
    super.key,
    required this.onChanged,
    this.controller,
    this.hintText = 'ค้นหาทุกอย่างในแอป (คอก, อุปกรณ์, วัคซีน, วันที่)',
  });

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: ez.inputFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ez.border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search, size: 20, color: ez.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textAlignVertical: TextAlignVertical.center,
              style: GoogleFonts.kanit(color: ez.textPrimary),
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.kanit(
                  color: ez.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

/// รายการผลค้นหาแบบดรอปดาวน์ - ค้นจากข้อมูลทั้งแอป กดแล้วไปหน้านั้นเลย
class EzSearchResults extends StatefulWidget {
  final String query;
  final VoidCallback? onOpened;

  const EzSearchResults({super.key, required this.query, this.onOpened});

  @override
  State<EzSearchResults> createState() => _EzSearchResultsState();
}

class _EzSearchResultsState extends State<EzSearchResults> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await GlobalSearchService.instance.ensureLoaded();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final ez = ezColors(context);
    final matches = GlobalSearchService.instance.search(widget.query);

    Widget child;
    if (matches.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Text(
          _loading ? 'กำลังค้นหา...' : 'ไม่พบข้อมูลที่ตรงกับคำค้นหา',
          style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 13),
        ),
      );
    } else {
      child = ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: matches.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: ez.border),
        itemBuilder: (context, index) {
          final e = matches[index];
          return ListTile(
            dense: true,
            leading: Text(e.emoji, style: const TextStyle(fontSize: 20)),
            title: Text(
              e.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kanit(
                fontWeight: FontWeight.w600,
                color: ez.textPrimary,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${e.category} • ${e.subtitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kanit(color: ez.textSecondary, fontSize: 12),
            ),
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onOpened?.call();
              e.open(context);
            },
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        decoration: BoxDecoration(
          color: ez.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ez.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// ช่องค้นหา + ผลลัพธ์ครบชุดในตัวเดียว ใส่ไว้ใต้หัวหน้าจอของทุกหน้า (ดู [EzHeader])
class EzSearchBar extends StatefulWidget {
  const EzSearchBar({super.key});

  @override
  State<EzSearchBar> createState() => _EzSearchBarState();
}

class _EzSearchBarState extends State<EzSearchBar> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    setState(() => _query = '');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Column(
        children: [
          EzSearchField(
            controller: _controller,
            onChanged: (v) => setState(() => _query = v),
          ),
          if (_query.trim().isNotEmpty)
            EzSearchResults(
              query: _query,
              onOpened: _clear,
            ),
        ],
      ),
    );
  }
}
