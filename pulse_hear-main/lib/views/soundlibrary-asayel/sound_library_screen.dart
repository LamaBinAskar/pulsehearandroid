import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({Key? key}) : super(key: key);

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> {
  String selectedCategory = 'All';
  
  // بيانات الكروت منظمة لتسهيل الفلترة
  final List<Map<String, dynamic>> allSounds = [
    {'title': 'Fire Alarm', 'sub': 'إنذار حريق', 'img': 'assets/images/firealarm.png', 'cat': 'Safety', 'index': 0},
    {'title': 'Car Horn', 'sub': 'بوق السيارة', 'img': 'assets/images/horn 1.png', 'cat': 'Safety', 'index': 5},
    {'title': 'My Name', 'sub': 'اسمي', 'img': 'assets/images/girl 1.png', 'cat': 'Communication', 'index': 1},
    {'title': 'Baby Cry', 'sub': 'بكاء طفل', 'img': 'assets/images/baby-cry 1.png', 'cat': 'Home', 'index': 2},
    {'title': 'Adhan', 'sub': 'الأذان', 'img': 'assets/images/mousq.png', 'cat': 'Communication', 'index': 3},
    {'title': 'Doorbell', 'sub': 'جرس الباب', 'img': 'assets/images/doorbell 1.png', 'cat': 'Home', 'index': 4},
  ];

  List<bool> isSoundEnabled = [true, true, true, true, true, false];
  List<double> soundIntensities = [0.4, 0.9, 0.5, 0.8, 0.4, 0.1];

  @override
  Widget build(BuildContext context) {
    // منطق الفلترة: إذا كان التصنيف 'All' اعرض الكل، وإلا اعرض المطابق فقط
    final filteredSounds = selectedCategory == 'All' 
        ? allSounds 
        : allSounds.where((s) => s['cat'] == selectedCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F9),
      body: Column(
        children: [
          // 1. Header Section - ثابت
          Container(
            width: double.infinity,
            height: 150,
            decoration: const BoxDecoration(
              color: Color(0xFF1D1B3F),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(45),
                bottomRight: Radius.circular(45),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Sound Library',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // 2. Search & Filters - ثابت
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F4D6A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                    child: const TextField(
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: 'search',
                        hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 18),
                        border: InputBorder.none,
                        suffixIcon: Icon(Icons.search, color: Color(0xFF1D1B3F), size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  decoration: BoxDecoration(color: const Color(0xFFB2B3BD), borderRadius: BorderRadius.circular(20)),
                  child: SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All'),
                        _buildFilterChip('Safety'), // تم تصحيح الإملاء من Safty
                        _buildFilterChip('Home'),
                        _buildFilterChip('Emergency'),
                        _buildFilterChip('Communication'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Scrollable Grid - الجزء المتحرك
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSounds.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final sound = filteredSounds[index];
                  return _buildSoundCard(
                    sound['index'], 
                    sound['title'], 
                    sound['sub'], 
                    sound['img']
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => selectedCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1D1B3F) : const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF1D1B3F),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundCard(int index, String title, String subTitle, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE8ECF4),
                child: Image.asset(imagePath, height: 30, fit: BoxFit.contain),
              ),
              Transform.scale(
                scale: 0.7,
                child: Switch(
                  value: isSoundEnabled[index],
                  onChanged: (val) => setState(() => isSoundEnabled[index] = val),
                  activeColor: const Color(0xFF43416D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(subTitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 8), 
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: const Color(0xFFE8EAF2), borderRadius: BorderRadius.circular(8)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: 'Vibration Pattern',
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1D1B3F)),
                items: ['Vibration Pattern'].map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 10)))).toList(),
                onChanged: (_) {},
              ),
            ),
          ),
          
          const Spacer(), 
          const Text('Intensity', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
          
          const SizedBox(height: 4), 
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               _buildIntensityLabel(index, 'Low', 0.0),
               _buildIntensityLabel(index, 'Medium', 0.5),
               _buildIntensityLabel(index, 'High', 1.0),
            ],
          ),
          
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4, 
              activeTrackColor: const Color(0xFF1D1B3F),
              inactiveTrackColor: const Color(0xFFD1D5E8),
              thumbColor: const Color(0xFF1D1B3F),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7), 
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14), 
              overlayColor: const Color(0xFF1D1B3F).withOpacity(0.1),
            ),
            child: Slider(
              value: soundIntensities[index], 
              onChanged: (double newValue) {
                setState(() {
                  soundIntensities[index] = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityLabel(int index, String text, double value) {
    return GestureDetector(
      onTap: () {
        setState(() {
          soundIntensities[index] = value;
        });
      },
      child: Text(
        text,
        style: const TextStyle(fontSize: 8, color: Colors.black54),
      ),
    );
  }
}