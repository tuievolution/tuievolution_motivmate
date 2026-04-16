class Quote {
  final String text;
  final String author;
  final String imageAsset; // filename only, e.g. "placeholder.png"

  const Quote({
    required this.text,
    required this.author,
    required this.imageAsset,
  });

  String get imagePath => 'assets/images/$imageAsset';
}

