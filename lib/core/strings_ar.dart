import '../features/game/domain/validation_reason.dart';
import '../features/roles/domain/team.dart';
import 'constants.dart';

abstract final class AppStrings {
  static const String appTitle = 'مافيا';
  static const String playersTitle = 'اللاعبون';
  static const String setupTitle = 'إعداد الجولة';
  static const String playerName = 'اسم اللاعب';
  static const String addPlayer = 'إضافة لاعب';
  static const String editPlayer = 'تعديل الاسم';
  static const String deletePlayer = 'حذف اللاعب';
  static const String saveName = 'حفظ الاسم';
  static const String cancel = 'إلغاء';
  static const String next = 'التالي';
  static const String emptyPlayers = 'ضيف أسماء اللاعبين عشان تبدأ';
  static const String mafiaCount = 'عدد المافيا';
  static const String optionalRoles = 'الأدوار الاختيارية';
  static const String increaseMafia = 'زيادة عدد المافيا';
  static const String decreaseMafia = 'تقليل عدد المافيا';
  static const String mafiaLimits = 'المافيا أقل من نصف عدد اللاعبين';
  static const String dealRoles = 'وزّع الأدوار';
  static const String handoffLabel = 'سلّم الموبايل لـ';
  static const String handoffInstruction =
      'لما تستلم الموبايل، اكشف دورك لوحدك';
  static const String revealRole = 'اكشف الدور';
  static const String hideAndNext = 'إخفاء والتالي';
  static const String timerTitle = 'وقت النقاش';
  static const String minutes = 'الدقائق';
  static const String seconds = 'الثواني';
  static const String increaseMinutes = 'زيادة الدقائق';
  static const String decreaseMinutes = 'تقليل الدقائق';
  static const String increaseSeconds = 'زيادة الثواني';
  static const String decreaseSeconds = 'تقليل الثواني';
  static const String startTimer = 'ابدأ';
  static const String pauseTimer = 'إيقاف مؤقت';
  static const String resumeTimer = 'استكمال';
  static const String restartTimer = 'ابدأ من جديد';
  static const String resetTimer = 'إعادة ضبط';
  static const String timerFinished = 'انتهى الوقت';
  static const String hostRoles = 'عرض الأدوار';
  static const String hostLongPressHint = 'اضغط مطولًا';
  static const String hostAutoClose = 'يغلق عرض الأدوار تلقائيًا';

  static String timerDigits(int seconds) =>
      '${(seconds ~/ Duration.secondsPerMinute).toString().padLeft(2, '0')}:'
      '${seconds.remainder(Duration.secondsPerMinute).toString().padLeft(2, '0')}';

  static String teamLabel(Team team) => switch (team) {
    Team.mafia => 'المافيا',
    Team.civilian => 'المدنيون',
    Team.neutral => 'محايد',
  };

  static String playerCount(int count) =>
      'عدد اللاعبين: ${_inlineNumber(count)}';
  static String number(int value) => '$value';
  static String _inlineNumber(int value) => '\u2066$value\u2069';

  static String? nameError(ValidationReason? reason) => switch (reason) {
    null => null,
    ValidationReason.emptyPlayerName => 'اكتب اسم اللاعب',
    ValidationReason.duplicatePlayerName => 'الاسم مكرر',
    ValidationReason.tooManyPlayers =>
      'الحد الأقصى ${_inlineNumber(GameLimits.maxPlayers)} لاعبًا',
    _ => validationMessage(reason),
  };

  static String validationMessage(
    ValidationReason reason, {
    int minMafia = 1,
    int maxMafia = 1,
    int excessRoles = 1,
  }) => switch (reason) {
    ValidationReason.tooFewPlayers =>
      'أضف لاعبين حتى يصل العدد إلى ${_inlineNumber(GameLimits.minPlayers)} على الأقل',
    ValidationReason.tooManyPlayers =>
      'احذف لاعبين حتى يصبح العدد ${_inlineNumber(GameLimits.maxPlayers)} أو أقل',
    ValidationReason.emptyPlayerName => 'اكتب اسم كل لاعب',
    ValidationReason.duplicatePlayerName => 'غيّر الأسماء المكررة',
    ValidationReason.invalidRoleSelection =>
      'اختر من الأدوار الاختيارية المتاحة',
    ValidationReason.mafiaCountTooLow =>
      'زِد عدد المافيا إلى ${_inlineNumber(minMafia)} على الأقل',
    ValidationReason.mafiaNotMinority =>
      'قلّل عدد المافيا إلى ${_inlineNumber(maxMafia)} أو أقل',
    ValidationReason.tooManySpecialRoles =>
      'عطّل ${_inlineNumber(excessRoles)} من الأدوار الاختيارية أو أضف لاعبين',
  };
}
