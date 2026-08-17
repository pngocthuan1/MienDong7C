class RecipientMember {
  final String id;
  final String name;
  final String initials;
  final String departmentName;

  const RecipientMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.departmentName,
  });
}

class RecipientGroup {
  final String id;
  final String name;
  final String initials;
  final int totalCount;
  final List<RecipientMember> members;

  const RecipientGroup({
    required this.id,
    required this.name,
    required this.initials,
    required this.totalCount,
    required this.members,
  });
}
