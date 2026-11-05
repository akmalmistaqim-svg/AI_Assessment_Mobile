/// Model representasi data pengumuman / informasi akademik.
class Announcement {
  final String id;
  final String title;
  final String date;
  final String category;
  final String summary;
  final String content;
  final String? classId;
  final String? assignmentId;

  const Announcement({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.summary,
    required this.content,
    this.classId,
    this.assignmentId,
  });
}
