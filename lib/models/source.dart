/// An external reference backing a lesson's claims.
class Source {
  const Source({
    required this.title,
    required this.url,
    required this.description,
  });

  final String title;
  final String url;
  final String description;
}
