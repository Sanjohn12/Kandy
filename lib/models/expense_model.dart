class Expense {
  final String id;
  final String category;
  final double amount;
  final String currency;
  final DateTime date;
  final String description;

  Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
  });

  // Convert to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'currency': currency,
      'date': date.toIso8601String(),
      'description': description,
    };
  }

  // Create from Map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      currency: map['currency'],
      date: DateTime.parse(map['date']),
      description: map['description'],
    );
  }
}

// Expense Categories
class ExpenseCategory {
  static const String food = 'Food';
  static const String transport = 'Transport';
  static const String accommodation = 'Accommodation';
  static const String activities = 'Activities';
  static const String shopping = 'Shopping';
  static const String other = 'Other';

  static List<String> get all => [
    food,
    transport,
    accommodation,
    activities,
    shopping,
    other,
  ];

  static String getIcon(String category) {
    switch (category) {
      case food:
        return '🍽️';
      case transport:
        return '🚗';
      case accommodation:
        return '🏨';
      case activities:
        return '🎯';
      case shopping:
        return '🛍️';
      default:
        return '💰';
    }
  }
}
