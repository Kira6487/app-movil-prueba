class RelatedItemOption {
  const RelatedItemOption({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
  });

  final String type;
  final int id;
  final String name;
  final String subtitle;

  String get key => '$type:$id';
}
