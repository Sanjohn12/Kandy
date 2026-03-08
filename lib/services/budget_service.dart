import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/models/expense_model.dart';

class BudgetService {
  static const String _expensesKey = 'expenses';
  static const String _budgetLimitKey = 'budget_limit';

  // Get all expenses
  Future<List<Expense>> getExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final String? expensesJson = prefs.getString(_expensesKey);

    if (expensesJson == null) return [];

    final List<dynamic> expensesList = jsonDecode(expensesJson);
    return expensesList.map((e) => Expense.fromMap(e)).toList();
  }

  // Add expense
  Future<void> addExpense(Expense expense) async {
    final expenses = await getExpenses();
    expenses.add(expense);
    await _saveExpenses(expenses);
  }

  // Delete expense
  Future<void> deleteExpense(String id) async {
    final expenses = await getExpenses();
    expenses.removeWhere((e) => e.id == id);
    await _saveExpenses(expenses);
  }

  // Save expenses
  Future<void> _saveExpenses(List<Expense> expenses) async {
    final prefs = await SharedPreferences.getInstance();
    final expensesList = expenses.map((e) => e.toMap()).toList();
    await prefs.setString(_expensesKey, jsonEncode(expensesList));
  }

  // Get total spending
  Future<double> getTotalSpending() async {
    final expenses = await getExpenses();
    double total = 0.0;
    for (var expense in expenses) {
      total += expense.amount;
    }
    return total;
  }

  // Get spending by category
  Future<Map<String, double>> getSpendingByCategory() async {
    final expenses = await getExpenses();
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  // Set budget limit
  Future<void> setBudgetLimit(double limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_budgetLimitKey, limit);
  }

  // Get budget limit
  Future<double?> getBudgetLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_budgetLimitKey);
  }

  // Check if over budget
  Future<bool> isOverBudget() async {
    final limit = await getBudgetLimit();
    if (limit == null) return false;

    final total = await getTotalSpending();
    return total > limit;
  }

  // Get budget percentage used
  Future<double> getBudgetPercentage() async {
    final limit = await getBudgetLimit();
    if (limit == null || limit == 0) return 0;

    final total = await getTotalSpending();
    return (total / limit) * 100;
  }
}
