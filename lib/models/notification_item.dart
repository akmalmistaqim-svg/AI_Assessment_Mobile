/// Model representasi data notifikasi simulasi lokal.
class NotificationItem {
  final String id;
  final String title;
  final String date;
  final String category;
  final String summary;
  final String content;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.date,
    required this.category,
    required this.summary,
    required this.content,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? date,
    String? category,
    String? summary,
    String? content,
    bool? isRead,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
    );
  }
}
