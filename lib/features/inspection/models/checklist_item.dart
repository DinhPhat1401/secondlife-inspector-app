class ChecklistItem {
  final String id;
  final String itemTitle;
  final String criteriaDescription;
  final bool mandatory;
  final int orderIndex;
  bool? passed; // true = PASS, false = FAIL, null = not evaluated yet
  String inspectorNote;
  String? photoProofUrl;

  ChecklistItem({
    required this.id,
    required this.itemTitle,
    required this.criteriaDescription,
    this.mandatory = true,
    this.orderIndex = 0,
    this.passed,
    this.inspectorNote = '',
    this.photoProofUrl,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id']?.toString() ?? '',
      itemTitle: json['itemTitle'] ?? json['title'] ?? '',
      criteriaDescription: json['criteriaDescription'] ?? json['description'] ?? '',
      mandatory: json['mandatory'] ?? true,
      orderIndex: json['orderIndex'] is int ? json['orderIndex'] : 0,
      passed: json['passed'],
      inspectorNote: json['inspectorNote'] ?? '',
      photoProofUrl: json['photoProofUrl'],
    );
  }

  Map<String, dynamic> toResultJson() {
    return {
      'itemId': id,
      'itemTitle': itemTitle,
      'passed': passed ?? false,
      'inspectorNote': inspectorNote,
      if (photoProofUrl != null) 'photoProofUrl': photoProofUrl,
    };
  }

  ChecklistItem copyWith({
    bool? passed,
    String? inspectorNote,
    String? photoProofUrl,
  }) {
    return ChecklistItem(
      id: id,
      itemTitle: itemTitle,
      criteriaDescription: criteriaDescription,
      mandatory: mandatory,
      orderIndex: orderIndex,
      passed: passed ?? this.passed,
      inspectorNote: inspectorNote ?? this.inspectorNote,
      photoProofUrl: photoProofUrl ?? this.photoProofUrl,
    );
  }
}
