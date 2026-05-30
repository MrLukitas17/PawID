class Pet {
  final String id;
  String name;
  String species;   // Perro, Gato, etc.
  String breed;     // Raza
  String birthDate; // dd/MM/yyyy
  String ownerName;
  String ownerPhone;
  String ownerEmail;
  String? photoPath; // Ruta local de la foto

  Pet({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.birthDate,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    this.photoPath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'breed': breed,
    'birthDate': birthDate,
    'ownerName': ownerName,
    'ownerPhone': ownerPhone,
    'ownerEmail': ownerEmail,
    'photoPath': photoPath,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'],
    name: json['name'],
    species: json['species'],
    breed: json['breed'],
    birthDate: json['birthDate'],
    ownerName: json['ownerName'],
    ownerPhone: json['ownerPhone'],
    ownerEmail: json['ownerEmail'],
    photoPath: json['photoPath'],
  );

  // Calcula la edad a partir de la fecha de nacimiento
  String get age {
    try {
      final parts = birthDate.split('/');
      if (parts.length != 3) return 'N/A';
      final birth = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      return '$years año${years == 1 ? '' : 's'}';
    } catch (_) {
      return 'N/A';
    }
  }
}