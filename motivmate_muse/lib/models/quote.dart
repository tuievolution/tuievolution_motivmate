class Quote {
  final String textTr;
  final String authorTr;
  final String textEn;
  final String authorEn;
  final String imageAsset; // filename only or full asset path

  const Quote({
    required this.textTr,
    required this.authorTr,
    required this.textEn,
    required this.authorEn,
    required this.imageAsset,
  });

  String text(String lang) => lang == 'en' ? textEn : textTr;
  String author(String lang) => lang == 'en' ? authorEn : authorTr;

  String get imagePath => imageAsset.contains('/') ? imageAsset : 'assets/images/$imageAsset';
}

