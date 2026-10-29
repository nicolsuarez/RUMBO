class RumboUser {
  const RumboUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.username,
    required this.birthDate,
    required this.role,
    required this.interests,
  });
  final String id, name, email, phone, username, role;
  final DateTime birthDate;
  final List<String> interests;
  int get age {
    final today = DateTime.now();
    return today.year -
        birthDate.year -
        ((today.month < birthDate.month ||
                (today.month == birthDate.month && today.day < birthDate.day))
            ? 1
            : 0);
  }

  bool get isOrganizer => role == 'organizador';
}
