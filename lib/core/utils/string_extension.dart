extension StringExtension on String {
  String toCamelCase() {
    if (isEmpty) return this;

    final words = split(RegExp(r'[\s_-]+'));
    final camelCase = words.asMap().entries.map((entry) {
      final index = entry.key;
      final word = entry.value;

      if (word.isEmpty) return '';
      if (index == 0) {
        return word[0].toLowerCase() + word.substring(1).toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();

    return camelCase;
  }

  String toPascalCase() {
    if (isEmpty) return this;

    final words = split(RegExp(r'[\s_-]+'));
    final pascalCase = words.map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join();

    return pascalCase;
  }

  String toSentenceCase() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
