class AgeCalculator {
  static int calculateAge(String? birthDateString, dynamic fallbackAge) {
    if (birthDateString != null && birthDateString.isNotEmpty) {
      try {
        DateTime birthDate = DateTime.parse(birthDateString);
        DateTime today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        return age;
      } catch (e) {
        // Fall back if parsing fails
      }
    }
    return int.tryParse(fallbackAge?.toString() ?? '0') ?? 0;
  }
}
