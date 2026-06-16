class Medicine {
  String name;
  String genericName;
  String dosageForm;
  String strength;
  String manufacturer;

  String? uses;
  String? sideEffects;

  Medicine({
    required this.name,
    required this.genericName,
    required this.dosageForm,
    required this.strength,
    required this.manufacturer,
    this.uses,
    this.sideEffects,
  });
}
