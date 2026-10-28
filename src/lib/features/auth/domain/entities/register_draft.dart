class RegisterDraft {
 const RegisterDraft({required this.email, required this.password,
 required this.name, required this.phone, required this.username,
 required this.birthDate, required this.interests});
 final String email, password, name, phone, username;
 final DateTime birthDate;
 final List<String> interests;
}
