import 'package:flutter/material.dart';

/// Uygulama renk paleti — Material Design Blue teması
/// Kaynak palette:
///   #0288D1 → Dark Primary
///   #03A9F4 → Primary
///   #B3E5FC → Light Primary
///   #FFFFFF → Text / Icons
///   #212121 → Primary Text
///   #757575 → Secondary Text
///   #BDBDBD → Divider
class ProjectColor {
  // ─── Temel renkler ───────────────────────────────────────────────────
  static const Color primary      = Color(0xFF03A9F4); // Parlak mavi
  static const Color primaryDark  = Color(0xFF0288D1); // Koyu mavi
  static const Color primaryLight = Color(0xFFB3E5FC); // Açık mavi
  static const Color accent       = Color(0xFF03A9F4); // Vurgu rengi

  // ─── Metin renkleri ──────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF212121); // Neredeyse siyah
  static const Color textSecondary = Color(0xFF757575); // Orta gri
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Beyaz (buton üzeri)
  static const Color divider       = Color(0xFFBDBDBD); // Bölücü çizgi

  // ─── Scaffold / Arka plan ────────────────────────────────────────────
  /// Açık mavi ton: primaryLight'ın %40 opasitesi
  static Color backgroundColor = const Color(0xFFF0F9FF);

  // ─── AppBar ──────────────────────────────────────────────────────────
  static Color appbarColor    = primaryDark;       // #0288D1
  static Color appbarTextColor = textOnPrimary;    // #FFFFFF

  // ─── Bottom Navigation Bar ───────────────────────────────────────────
  static Color bottomBar              = Colors.white;
  static Color bottomBarActivaColor   = primary;        // #03A9F4
  static Color bottomBarInActiveColor = const Color(0xFFBDBDBD); // divider gri

  // ─── Zikirmatik ──────────────────────────────────────────────────────
  static Color zikrTextColor = primaryDark;        // koyu mavi sayaç

  // ─── Hadis ───────────────────────────────────────────────────────────
  static Color hadithTextColor = textOnPrimary;    // beyaz — arka plan resmi üzerinde

  // ─── Namaz Vakitleri ─────────────────────────────────────────────────
  static Color prayTextColor           = primaryDark;       // etiket rengi
  static Color prayTimeTextColor       = primary;           // saat rengi
  static Color prayLocationTextColor   = primaryDark;       // konum metni
  static Color prayLocationSetButtonColor = primary;        // buton
  static Color prayLocationSetTextColor   = textOnPrimary;  // buton yazısı
}
