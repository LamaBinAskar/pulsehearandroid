import 'package:flutter/material.dart';

class AppColors {
  // الألوان الجديدة من الصورة (من الفاتح إلى الغامق)
  static const Color lightBlue = Color(0xFFEFF0F7);    // أفتح درجة (للخلفيات)
  static const Color softBlue = Color(0xFFCACFE5);     // درجة هادئة (للعناصر الثانوية)
  static const Color mutedBlue = Color(0xFF9DA8D0);    // أزرق مطفي
  static const Color primaryBlue = Color(0xFF7081BA);  // اللون الأساسي (للأزرار أو العناوين)
  static const Color deepBlue = Color(0xFF4F5E8E);     // أزرق عميق
  static const Color darkSlate = Color(0xFF333D5E);    // رمادي مزرق داكن
  static const Color obsidian = Color(0xFF191F33);     // أغمق درجة (للنصوص الأساسية)

  // ألوان الحالة (يفضل الاحتفاظ بها للتنبيهات)
  static const Color accent = Color.fromRGBO(255, 0, 0, 1);       // لون التنبيه (احمر)
  static const Color connected = Color(0xFF4CAF50);    // لون حالة "متصل" (أخضر)
}