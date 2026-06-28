
/// This class handles all money-related calculations for rides.
/// Fares are now based on fuel consumption, petrol price (380), and profit margins.
class FareCalculator {
  
  // -- CONSTANTS (The "Rules" of pricing) --
  static const double petrolPrice = 380.0;    // Price per Liter (Current: Rs 380)
  
  // Fuel Consumption (KM per Liter)
  static const double bikeKmPerL = 45.0;      // 45 KM per Liter for bikes
  static const double carKmPerL = 12.0;       // 12 KM per Liter for standard cars
  static const double heavyKmPerL = 8.0;       // 8 KM per Liter for recovery/heavy vehicles
  
  // Profit Margins (Percentage of fuel cost)
  static const double driverProfitPercent = 0.15; // 15% Profit for the driver
  static const double appProfitPercent = 0.05;    // 5% Profit for the app
  static const double totalMarkup = 1.0 + driverProfitPercent + appProfitPercent; // 1.20 Total multiplier (120% of cost)

  /// Calculates 3 fare options: Minimum (Economy), Recommended (Comfort), and Priority.
  /// [distanceInKm] is the direct path between points.
  /// [serviceType] determines the fuel efficiency used.
  static Map<String, int> calculateFareOptions({
    required double distanceInKm,
    required String serviceType,
  }) {
    // 1. Determine Fuel Efficiency (KM/L) based on service type
    double kmPerL = carKmPerL;
    switch (serviceType.toLowerCase()) {
      case 'bike':
        kmPerL = bikeKmPerL;
        break;
      case 'recovery':
      case 'mechanic':
        kmPerL = heavyKmPerL;
        break;
      default:
        kmPerL = carKmPerL;
    }
    
    // 2. Base Fuel Cost = (Distance / KMperL) * Petrol Price
    double fuelCost = (distanceInKm / kmPerL) * petrolPrice;
    
    // Safety minimum for very short distances
    if (fuelCost < 50) fuelCost = 50;

    // 3. Minimum Fare = Cost + 20% Markup (15% Driver + 5% App)
    int minFare = (fuelCost * totalMarkup).round();
    
    // 4. Generate 3 Suggestions
    return {
      'Budget': minFare,                         // The bare minimum (Cost + Profit)
      'Standard': (minFare * 1.25).round(),      // A more comfortable price (+25%)
      'Priority': (minFare * 1.5).round(),       // High priority / Peak price (+50%)
    };
  }
  
  /// DEPRECATED: Use calculateFareOptions instead. 
  /// Maintained for temporary compatibility.
  static int calculateFare({
    required double distanceInKm,
    required String serviceType,
  }) {
    final options = calculateFareOptions(distanceInKm: distanceInKm, serviceType: serviceType);
    return options['Budget']!;
  }

  /// Estimates travel time for display purposes.
  static String estimateTime(double distanceInKm) {
    // Assumes 30km/h average city speed
    double minutes = (distanceInKm / 30) * 60;
    
    if (minutes < 1) return "1 min";
    return "${minutes.round()} mins";
  }
}
