class Video {
  final String id;
  final String titulo;
  final String url;
  final String thumbnail;

  Video({
    required this.id,
    required this.titulo,
    required this.url,
    required this.thumbnail,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? '',
      titulo: json['titulo'] ?? '',
      url: json['url'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'titulo': titulo,
      'url': url,
      'thumbnail': thumbnail,
    };
  }
}
