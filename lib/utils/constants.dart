class AppConstants {
  // Widget Sync Keys
  static const String keyScheduleData = 'schedule_data';
  static const String keyEvents = 'events';
  static const String keyShowProfessorNames = 'showProfessorNames';
  
  // Event Model Keys
  static const String keyId = 'id';
  static const String keyTitle = 'title';
  static const String keyStartTime = 'startTime';
  static const String keyEndTime = 'endTime';
  static const String keyProfessor = 'professor';
  static const String keyType = 'type';
  static const String keyCompleted = 'completed';
  static const String keyDate = 'date';
  static const String keySection = 'section';
  static const String keyIsImported = 'isImported';
  static const String keyNotes = 'notes';

  // Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefShowProfessor = 'show_professor_names';
  static const String prefMorningCutoff = 'morning_cutoff_hour';

  // Default Values
  static const int defaultMorningCutoff = 8;
  static const String androidWidgetName = 'ClassWidgetProvider';
  
  // Navigation Constants
  static const int centerIndex = 1000;
}
