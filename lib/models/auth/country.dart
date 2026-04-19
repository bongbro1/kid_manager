class Country {
  final String name;
  final String dialCode;
  final String code;

  Country({
    required this.name,
    required this.dialCode,
    required this.code,
  });

  String get flag => countryCodeToEmoji(code);
}
String countryCodeToEmoji(String code) {
  return code
      .toUpperCase()
      .codeUnits
      .map((c) => String.fromCharCode(c + 127397))
      .join();
}