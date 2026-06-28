class DriverRequest {
  String id;
  String name;
  String cnic;
  String eta;
  double rating;
  int totalRides;
  String carModel;
  String licensePlate;
  String distance;
  int fare;
  String imagePath;
  bool isNew;

  DriverRequest({
    required this.id,
    required this.name,
    required this.cnic,
    required this.eta,
    required this.rating,
    required this.totalRides,
    required this.carModel,
    required this.licensePlate,
    required this.distance,
    required this.fare,
    required this.imagePath,
    required this.isNew,
  });
}
