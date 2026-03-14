import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared iOS-style glassmorphism popup helper
// ─────────────────────────────────────────────────────────────────────────────

/// Shows a floating Cupertino-style menu anchored to the [anchorContext] widget.
Future<void> showIosStyleMenu({
  required BuildContext anchorContext,
  required List<String> options,
  required String current,
  required ValueChanged<String> onSelected,
}) async {
  final RenderBox button =
      anchorContext.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(anchorContext).context.findRenderObject() as RenderBox;
  final RelativeRect position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(Offset.zero, ancestor: overlay),
      button.localToGlobal(button.size.bottomRight(Offset.zero),
          ancestor: overlay),
    ),
    Offset.zero & overlay.size,
  );

  await showMenu<String>(
    context: anchorContext,
    position: position,
    elevation: 0,
    color: Colors.transparent,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    items: [
      PopupMenuItem<String>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: _IosMenuCard(
          options: options,
          current: current,
          onSelected: (val) {
            Navigator.pop(anchorContext, val);
            onSelected(val);
          },
        ),
      ),
    ],
  );
}

/// The frosted-glass card rendered inside every popup.
class _IosMenuCard extends StatelessWidget {
  final List<String> options;
  final String current;
  final ValueChanged<String> onSelected;

  const _IosMenuCard({
    required this.options,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 200,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.asMap().entries.map((entry) {
              final isLast = entry.key == options.length - 1;
              final opt = entry.value;
              final isSelected = opt == current;
              return Column(
                children: [
                  InkWell(
                    onTap: () => onSelected(opt),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            opt,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? const Color(0xFF4F4D78)
                                  : Colors.black87,
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_rounded,
                                size: 16, color: Color(0xFF4F4D78)),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.shade300,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unified dropdown field widget — two visual modes
// ─────────────────────────────────────────────────────────────────────────────

/// [showLabel] = true  → compact row layout for keyword cards
/// [showLabel] = false → full-width pill layout for the dialog
class IosDropdownField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onSelected;
  final bool showLabel;

  const IosDropdownField({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.showLabel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => GestureDetector(
        onTap: () => showIosStyleMenu(
          anchorContext: ctx,
          options: options,
          current: value,
          onSelected: onSelected,
        ),
        child: showLabel ? _cardRow() : _dialogPill(),
      ),
    );
  }

  // Compact row — used inside keyword cards
  Widget _cardRow() {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.grey.shade600)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87)),
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 13, color: Colors.black54),
            ],
          ),
        ),
      ],
    );
  }

  // Full-width pill — used inside the Add/Edit dialog
  Widget _dialogPill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade500)),
          const Spacer(),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF38385A))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: Colors.black45),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────────────────────────────────────

class KeywordsScreen extends StatefulWidget {
  const KeywordsScreen({Key? key}) : super(key: key);

  @override
  State<KeywordsScreen> createState() => _KeywordsScreenState();
}

class _KeywordsScreenState extends State<KeywordsScreen> {
  final List<Map<String, dynamic>> keywords = [
    {'word': 'ايلاف', 'lang': 'Arabic', 'vib': 'Long', 'isActive': true},
    {'word': 'Flight a28', 'lang': 'English', 'vib': 'Long', 'isActive': true},
    {'word': 'ماما', 'lang': 'Arabic', 'vib': 'Long', 'isActive': true},
    {'word': 'السلام عليكم', 'lang': 'Arabic', 'vib': 'Long', 'isActive': true},
  ];

  List<Map<String, dynamic>> filteredKeywords = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredKeywords = List.from(keywords);
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredKeywords = List.from(keywords);
      } else {
        filteredKeywords = keywords
            .where((kw) => kw['word']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ── Add / Edit dialog ─────────────────────────────────────────────────────
  void _showAddOrEditDialog({Map<String, dynamic>? keywordToEdit}) {
    final wordController = TextEditingController(
        text: keywordToEdit != null ? keywordToEdit['word'] : '');
    String selectedLang =
        keywordToEdit != null ? keywordToEdit['lang'] : 'Arabic';
    String selectedVib =
        keywordToEdit != null ? keywordToEdit['vib'] : 'Long';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Text(
                keywordToEdit == null ? 'Add New Keyword' : 'Edit Keyword',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF191834),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Word text field
                  TextField(
                    controller: wordController,
                    decoration: InputDecoration(
                      hintText: 'Enter word...',
                      hintStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                  const SizedBox(height: 12),

                  // Language — iOS dropdown (dialog pill mode)
                  IosDropdownField(
                    icon: Icons.g_translate,
                    label: 'Language',
                    value: selectedLang,
                    options: const ['Arabic', 'English'],
                    showLabel: false,
                    onSelected: (val) =>
                        setDialogState(() => selectedLang = val),
                  ),
                  const SizedBox(height: 12),

                  // Vibration — iOS dropdown (dialog pill mode)
                  IosDropdownField(
                    icon: Icons.vibration,
                    label: 'Vibration',
                    value: selectedVib,
                    options: const ['Short', 'Medium', 'Long'],
                    showLabel: false,
                    onSelected: (val) =>
                        setDialogState(() => selectedVib = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel',
                      style: GoogleFonts.poppins(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F4D78),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    if (wordController.text.trim().isEmpty) return;
                    setState(() {
                      if (keywordToEdit == null) {
                        keywords.add({
                          'word': wordController.text.trim(),
                          'lang': selectedLang,
                          'vib': selectedVib,
                          'isActive': true,
                        });
                      } else {
                        keywordToEdit['word'] = wordController.text.trim();
                        keywordToEdit['lang'] = selectedLang;
                        keywordToEdit['vib'] = selectedVib;
                      }
                      filterSearchResults(_searchController.text);
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Save',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF191834),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Keywords',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Custom Keywords',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF38385A),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Get alerted when you hear specific words',
              style: GoogleFonts.poppins(
                  fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: filterSearchResults,
                decoration: InputDecoration(
                  hintText: 'search',
                  hintStyle:
                      GoogleFonts.poppins(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  suffixIcon:
                      Icon(Icons.search, color: Colors.grey.shade600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Add keyword button
            Container(
              width: 180,
              height: 45,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E5EF),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: () => _showAddOrEditDialog(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add,
                          color: Color(0xFF38385A), size: 20),
                      const SizedBox(width: 5),
                      Text(
                        'Add Keyword',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF38385A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: filteredKeywords.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final kw = filteredKeywords[index];
                  return _buildKeywordCard(kw);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Keyword card ──────────────────────────────────────────────────────────
  Widget _buildKeywordCard(Map<String, dynamic> kw) {
    const Color activeGreen = Color(0xFF253418);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Word chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                    color: Colors.white,
                    offset: Offset(-2, -2),
                    blurRadius: 4),
                BoxShadow(
                    color: Colors.black12,
                    offset: Offset(2, 2),
                    blurRadius: 4),
              ],
            ),
            child: Center(
              child: Text(
                kw['word'],
                style: GoogleFonts.cairo(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF38385A),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Language dropdown — card row mode
          IosDropdownField(
            icon: Icons.g_translate,
            label: 'Language',
            value: kw['lang'],
            options: const ['Arabic', 'English'],
            showLabel: true,
            onSelected: (val) => setState(() => kw['lang'] = val),
          ),

          const Divider(height: 15, thickness: 0.5),

          // Vibration dropdown — card row mode
          IosDropdownField(
            icon: Icons.vibration,
            label: 'Vibration',
            value: kw['vib'],
            options: const ['Short', 'Medium', 'Long'],
            showLabel: true,
            onSelected: (val) => setState(() => kw['vib'] = val),
          ),

          const Spacer(),

          // Bottom row: checkbox + edit + delete
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Rounded checkbox active toggle
              GestureDetector(
                onTap: () =>
                    setState(() => kw['isActive'] = !kw['isActive']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: kw['isActive']
                        ? activeGreen.withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kw['isActive']
                          ? activeGreen.withOpacity(0.4)
                          : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: kw['isActive']
                              ? activeGreen.withOpacity(0.85)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: kw['isActive']
                                ? activeGreen
                                : Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        child: kw['isActive']
                            ? const Icon(Icons.check,
                                size: 11, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Active',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: kw['isActive']
                              ? activeGreen
                              : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Edit + Delete
              Row(
                children: [
                  InkWell(
                    onTap: () => _showAddOrEditDialog(keywordToEdit: kw),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.edit,
                          size: 14, color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        keywords.remove(kw);
                        filteredKeywords.remove(kw);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.delete_outline,
                          size: 14, color: Colors.red.shade400),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}