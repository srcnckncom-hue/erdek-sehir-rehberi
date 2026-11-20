class Contact {
  const Contact({required this.name, required this.phone, this.note});

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        name: json['name'] as String,
        phone: json['phone'] as String,
        note: json['note'] as String?,
      );

  final String name;

  /// tel: bağlantısında kullanılan numara (ör. 112 veya +902660000000).
  final String phone;
  final String? note;
}

class ContactCategory {
  const ContactCategory({
    required this.id,
    required this.title,
    required this.contacts,
  });

  factory ContactCategory.fromJson(Map<String, dynamic> json) =>
      ContactCategory(
        id: json['id'] as String,
        title: json['title'] as String,
        contacts: (json['contacts'] as List<dynamic>)
            .map((e) => Contact.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final String id;
  final String title;
  final List<Contact> contacts;
}

class ContactsData {
  const ContactsData({required this.categories});

  factory ContactsData.fromJson(Map<String, dynamic> json) => ContactsData(
        categories: (json['categories'] as List<dynamic>)
            .map((e) => ContactCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final List<ContactCategory> categories;
}
