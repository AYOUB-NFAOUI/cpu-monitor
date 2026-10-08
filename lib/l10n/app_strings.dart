import '../models/app_settings.dart';
import 'app_strings_extra.dart';

/// Une langue proposée dans Settings > Switch language.
class AppLanguage {
  final String code; // 'system', 'en', 'fr', 'zh', 'zh-TW'...
  final String label; // nom affiché (dans sa propre langue)
  const AppLanguage(this.code, this.label);
}

/// Dans l'ordre de la grille de la maquette (3 colonnes).
/// Le libellé de "system" est remplacé par S.system (traduit).
const List<AppLanguage> appLanguages = [
  AppLanguage('system', 'System'),
  AppLanguage('en', 'English'),
  AppLanguage('zh', '简体中文'),
  AppLanguage('zh-TW', '繁體中文'),
  AppLanguage('id', 'Indonesia'),
  AppLanguage('ms', 'Melayu'),
  AppLanguage('ru', 'Русский'),
  AppLanguage('th', 'ภาษาไทย'),
  AppLanguage('es', 'Español'),
  AppLanguage('ja', '日本語'),
  AppLanguage('pt', 'Português'),
  AppLanguage('fr', 'Français'),
  AppLanguage('vi', 'Tiếng Việt'),
  AppLanguage('de', 'Deutsch'),
  AppLanguage('ko', '한국어'),
];

/// Ordre des textes dans chaque liste :
///  0 cpu            1 floating       2 system         3 app_title
///  4 settings       5 refresh        6 theme_color    7 theme_color_desc
///  8 dark_setting   9 dark_desc     10 language      11 language_desc
/// 12 light         13 dark          14 system_theme  15 cancel
/// 16 confirm       17 group_cpu     18 group_battery 19 group_system
///
/// Si une langue ou un texte manque, l'anglais est utilisé.
const Map<String, List<String>> _tr = {
  'en': [
    "Cpu", "Floating", "System", "CPU MONITOR",
    "SETTINGS", "Data refresh rate", "Theme color", "Switch the theme color",
    "Dark theme setting", "Switch to dark theme", "Switch language", "Choose your preferred language",
    "Light theme", "Dark theme", "System's theme", "Cancel",
    "Confirm", "Cpu Monitor", "Battery Monitor", "System Monitor",
  ],
  'fr': [
    "CPU", "Flottant", "Système", "MONITEUR CPU",
    "PARAMÈTRES", "Fréquence d'actualisation", "Couleur du thème", "Changer la couleur du thème",
    "Réglage du thème sombre", "Passer au thème sombre", "Changer de langue", "Choisissez votre langue préférée",
    "Thème clair", "Thème sombre", "Thème du système", "Annuler",
    "Confirmer", "Moniteur CPU", "Moniteur de batterie", "Moniteur système",
  ],
  'es': [
    "CPU", "Flotante", "Sistema", "MONITOR CPU",
    "AJUSTES", "Frecuencia de actualización", "Color del tema", "Cambiar el color del tema",
    "Ajuste del tema oscuro", "Cambiar al tema oscuro", "Cambiar idioma", "Elige tu idioma preferido",
    "Tema claro", "Tema oscuro", "Tema del sistema", "Cancelar",
    "Confirmar", "Monitor de CPU", "Monitor de batería", "Monitor del sistema",
  ],
  'pt': [
    "CPU", "Flutuante", "Sistema", "MONITOR DE CPU",
    "CONFIGURAÇÕES", "Taxa de atualização", "Cor do tema", "Alterar a cor do tema",
    "Configuração do tema escuro", "Mudar para o tema escuro", "Mudar idioma", "Escolha seu idioma preferido",
    "Tema claro", "Tema escuro", "Tema do sistema", "Cancelar",
    "Confirmar", "Monitor de CPU", "Monitor de bateria", "Monitor do sistema",
  ],
  'de': [
    "CPU", "Schwebend", "System", "CPU-MONITOR",
    "EINSTELLUNGEN", "Aktualisierungsrate", "Designfarbe", "Designfarbe ändern",
    "Dunkles Design", "Zum dunklen Design wechseln", "Sprache wechseln", "Bevorzugte Sprache wählen",
    "Helles Design", "Dunkles Design", "System-Design", "Abbrechen",
    "Bestätigen", "CPU-Monitor", "Akku-Monitor", "System-Monitor",
  ],
  'ru': [
    "ЦП", "Плавающее", "Система", "МОНИТОР ЦП",
    "НАСТРОЙКИ", "Частота обновления", "Цвет темы", "Сменить цвет темы",
    "Настройка тёмной темы", "Переключить на тёмную тему", "Сменить язык", "Выберите предпочитаемый язык",
    "Светлая тема", "Тёмная тема", "Системная тема", "Отмена",
    "Подтвердить", "Монитор ЦП", "Монитор батареи", "Монитор системы",
  ],
  'id': [
    "CPU", "Melayang", "Sistem", "MONITOR CPU",
    "PENGATURAN", "Kecepatan segar data", "Warna tema", "Ganti warna tema",
    "Pengaturan tema gelap", "Beralih ke tema gelap", "Ganti bahasa", "Pilih bahasa pilihan Anda",
    "Tema terang", "Tema gelap", "Tema sistem", "Batal",
    "Konfirmasi", "Monitor CPU", "Monitor Baterai", "Monitor Sistem",
  ],
  'ms': [
    "CPU", "Terapung", "Sistem", "PEMANTAU CPU",
    "TETAPAN", "Kadar muat semula data", "Warna tema", "Tukar warna tema",
    "Tetapan tema gelap", "Tukar ke tema gelap", "Tukar bahasa", "Pilih bahasa pilihan anda",
    "Tema cerah", "Tema gelap", "Tema sistem", "Batal",
    "Sahkan", "Pemantau CPU", "Pemantau Bateri", "Pemantau Sistem",
  ],
  'vi': [
    "CPU", "Nổi", "Hệ thống", "THEO DÕI CPU",
    "CÀI ĐẶT", "Tần suất làm mới dữ liệu", "Màu chủ đề", "Đổi màu chủ đề",
    "Cài đặt chủ đề tối", "Chuyển sang chủ đề tối", "Đổi ngôn ngữ", "Chọn ngôn ngữ ưa thích",
    "Chủ đề sáng", "Chủ đề tối", "Chủ đề hệ thống", "Hủy",
    "Xác nhận", "Giám sát CPU", "Giám sát pin", "Giám sát hệ thống",
  ],
  'th': [
    "CPU", "ลอย", "ระบบ", "ตัวตรวจสอบ CPU",
    "การตั้งค่า", "อัตราการรีเฟรชข้อมูล", "สีธีม", "เปลี่ยนสีธีม",
    "การตั้งค่าธีมมืด", "สลับเป็นธีมมืด", "เปลี่ยนภาษา", "เลือกภาษาที่ต้องการ",
    "ธีมสว่าง", "ธีมมืด", "ธีมระบบ", "ยกเลิก",
    "ยืนยัน", "ตรวจสอบ CPU", "ตรวจสอบแบตเตอรี่", "ตรวจสอบระบบ",
  ],
  'ja': [
    "CPU", "フローティング", "システム", "CPUモニター",
    "設定", "データ更新頻度", "テーマカラー", "テーマカラーを変更",
    "ダークテーマ設定", "ダークテーマに切り替え", "言語を切り替え", "使用する言語を選択",
    "ライトテーマ", "ダークテーマ", "システムのテーマ", "キャンセル",
    "確認", "CPUモニター", "バッテリーモニター", "システムモニター",
  ],
  'ko': [
    "CPU", "플로팅", "시스템", "CPU 모니터",
    "설정", "데이터 새로고침 주기", "테마 색상", "테마 색상 변경",
    "다크 테마 설정", "다크 테마로 전환", "언어 변경", "선호하는 언어를 선택하세요",
    "라이트 테마", "다크 테마", "시스템 테마", "취소",
    "확인", "CPU 모니터", "배터리 모니터", "시스템 모니터",
  ],
  'zh': [
    "CPU", "悬浮窗", "系统", "CPU 监控",
    "设置", "数据刷新频率", "主题颜色", "切换主题颜色",
    "深色主题设置", "切换到深色主题", "切换语言", "选择您偏好的语言",
    "浅色主题", "深色主题", "跟随系统", "取消",
    "确认", "CPU 监控", "电池监控", "系统监控",
  ],
  'zh-TW': [
    "CPU", "懸浮窗", "系統", "CPU 監控",
    "設定", "資料更新頻率", "主題顏色", "切換主題顏色",
    "深色主題設定", "切換到深色主題", "切換語言", "選擇您偏好的語言",
    "淺色主題", "深色主題", "跟隨系統", "取消",
    "確認", "CPU 監控", "電池監控", "系統監控",
  ],
};

/// Accès aux textes traduits : `S.settings`, `S.cancel`, ...
/// Les valeurs sont relues à chaque `build`, donc un changement de langue
/// s'applique dès que l'interface est reconstruite (fait par main.dart).
class S {
  S._();

  static String _at(int i) {
    final lang = AppSettings.instance.effectiveLanguage;
    final list = _tr[lang] ?? _tr['en']!;
    return i < list.length ? list[i] : _tr['en']![i];
  }

  static String get cpu => _at(0);
  static String get floating => _at(1);
  static String get system => _at(2);
  static String get appTitle => _at(3);
  static String get settings => _at(4);
  static String get refresh => _at(5);
  static String get themeColor => _at(6);
  static String get themeColorDesc => _at(7);
  static String get darkSetting => _at(8);
  static String get darkDesc => _at(9);
  static String get language => _at(10);
  static String get languageDesc => _at(11);
  static String get light => _at(12);
  static String get dark => _at(13);
  static String get systemTheme => _at(14);
  static String get cancel => _at(15);
  static String get confirm => _at(16);
  static String get groupCpu => _at(17);
  static String get groupBattery => _at(18);
  static String get groupSystem => _at(19);

  /// Traduit N'IMPORTE quel texte de l'application (clé = texte anglais).
  /// Un texte inconnu est renvoyé tel quel (noms d'appareil, valeurs...).
  static String tr(String text) {
    switch (text) {
      case 'Cpu Monitor':
        return groupCpu;
      case 'Battery Monitor':
        return groupBattery;
      case 'System Monitor':
        return groupSystem;
      case 'Data refresh rate':
        return refresh;
      case 'Cancel':
        return cancel;
      case 'Confirm':
        return confirm;
    }
    final lang = AppSettings.instance.effectiveLanguage;
    if (lang == 'en') return text;
    final i = extraLanguageOrder.indexOf(lang);
    if (i < 0) return text;
    final list = extraTranslations[text];
    if (list == null || i >= list.length) return text;
    return list[i];
  }

  /// Traduit les titres de groupes de l'onglet Floating.
  static String group(String englishTitle) {
    switch (englishTitle) {
      case 'Cpu Monitor':
        return groupCpu;
      case 'Battery Monitor':
        return groupBattery;
      case 'System Monitor':
        return groupSystem;
      default:
        return englishTitle;
    }
  }
}
