import 'package:flutter/material.dart';
import 'package:my_app/models/expense_model.dart';
import 'package:my_app/services/budget_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ===== TRIP MODEL =====
class Trip {
  final String id;
  String name;
  double budgetLimit;
  List<Expense> expenses;

  Trip({
    required this.id,
    required this.name,
    required this.budgetLimit,
    List<Expense>? expenses,
  }) : expenses = expenses ?? [];

  double get totalSpent => expenses.fold(0, (sum, e) => sum + e.amount);
}

// ===== BUDGET TRACKER SCREEN =====
class BudgetTrackerScreen extends StatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen>
    with SingleTickerProviderStateMixin {
  final BudgetService _budgetService = BudgetService();

  // Multi-trip state
  List<Trip> _trips = [];
  String? _selectedTripId;
  bool _isLoading = true;

  // UI state
  String _activeFilter = 'All';
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeTrips();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    );
  }

  // Initialize with dummy trips
  Future<void> _initializeTrips() async {
    setState(() => _isLoading = true);

    // Load from service if available
    List<Expense> expenses = await _budgetService.getExpenses();
    double budgetLimit = await _budgetService.getBudgetLimit() ?? 50000;

    // Create dummy trips if none exist
    _trips = [
      Trip(
        id: '1',
        name: 'Kandy Tour',
        budgetLimit: budgetLimit,
        expenses: expenses,
      ),
      Trip(
        id: '2',
        name: 'Colombo Shopping',
        budgetLimit: 30000,
        expenses: [
          Expense(
            id: 'e1',
            category: ExpenseCategory.shopping,
            amount: 5000,
            currency: 'LKR',
            date: DateTime.now(),
            description: 'Clothes at shopping mall',
          ),
          Expense(
            id: 'e2',
            category: ExpenseCategory.food,
            amount: 1500,
            currency: 'LKR',
            date: DateTime.now(),
            description: 'Lunch',
          ),
        ],
      ),
      Trip(
        id: '3',
        name: 'Galle Fort Visit',
        budgetLimit: 15000,
        expenses: [
          Expense(
            id: 'e3',
            category: ExpenseCategory.accommodation,
            amount: 8000,
            currency: 'LKR',
            date: DateTime.now(),
            description: 'Hotel stay',
          ),
        ],
      ),
    ];

    _selectedTripId = _trips.isNotEmpty ? _trips[0].id : null;
    setState(() => _isLoading = false);
    _progressController.forward(from: 0);
  }

  Trip? get _currentTrip => _trips.firstWhere(
        (t) => t.id == _selectedTripId,
        orElse: () =>
            _trips.isEmpty ? Trip(id: '', name: '', budgetLimit: 0) : _trips[0],
      );

  // Reset trip expenses
  void _resetTrip() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Trip'),
        content: const Text(
          'Are you sure you want to reset all expenses for this trip?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_currentTrip != null) {
                setState(() => _currentTrip!.expenses.clear());
                Navigator.pop(ctx);
                Fluttertoast.showToast(msg: 'Trip reset');
                _progressController.forward(from: 0);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  // Create new trip
  void _openCreateTripSheet() {
    final nameCtrl = TextEditingController();
    final budgetCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create New Trip',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Trip Name',
                hintText: 'e.g., Kandy Tour',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(
                labelText: 'Budget Limit (LKR)',
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                final budget = double.tryParse(budgetCtrl.text) ?? 0;

                if (name.isNotEmpty && budget > 0) {
                  final newTrip = Trip(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    budgetLimit: budget,
                  );
                  setState(() {
                    _trips.add(newTrip);
                    _selectedTripId = newTrip.id;
                  });
                  Navigator.pop(ctx);
                  Fluttertoast.showToast(msg: 'Trip created: $name');
                  _progressController.forward(from: 0);
                } else {
                  Fluttertoast.showToast(msg: 'Please fill all fields');
                }
              },
              child: const Text('Create Trip'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Edit trip
  void _openEditTripSheet(Trip trip) {
    final nameCtrl = TextEditingController(text: trip.name);
    final budgetCtrl = TextEditingController(
      text: trip.budgetLimit.toStringAsFixed(0),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text('Edit Trip', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Trip Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: budgetCtrl,
              decoration: const InputDecoration(
                labelText: 'Budget Limit (LKR)',
                prefixText: 'Rs. ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final name = nameCtrl.text.trim();
                      final budget =
                          double.tryParse(budgetCtrl.text) ?? trip.budgetLimit;

                      if (name.isNotEmpty && budget > 0) {
                        setState(() {
                          trip.name = name;
                          trip.budgetLimit = budget;
                        });
                        Navigator.pop(ctx);
                        Fluttertoast.showToast(msg: 'Trip updated');
                        _progressController.forward(from: 0);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // Add expense to current trip
  void _openAddExpenseSheet({String? category}) {
    if (_currentTrip == null) return;

    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = category ?? ExpenseCategory.food;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Add Expense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (LKR)',
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: ExpenseCategory.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => selectedCategory = v ?? selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note / Description',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    final expense = Expense(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      category: selectedCategory,
                      amount: double.parse(amountCtrl.text),
                      currency: 'LKR',
                      date: DateTime.now(),
                      description: descCtrl.text,
                    );
                    setState(() => _currentTrip!.expenses.add(expense));
                    Navigator.pop(ctx);
                    Fluttertoast.showToast(msg: 'Expense added');
                    _progressController.forward(from: 0);
                  }
                },
                child: const Text('Save Expense'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // Edit expense
  void _openEditExpenseSheet(Expense expense) {
    if (_currentTrip == null) return;

    final formKey = GlobalKey<FormState>();
    final amountCtrl = TextEditingController(text: expense.amount.toString());
    final descCtrl = TextEditingController(text: expense.description);
    String selectedCategory = expense.category;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Edit Expense',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount (LKR)',
                  prefixText: 'Rs. ',
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter amount' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                items: ExpenseCategory.all
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => selectedCategory = v ?? selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Note / Description',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final updatedExpense = Expense(
                            id: expense.id,
                            category: selectedCategory,
                            amount: double.parse(amountCtrl.text),
                            currency: expense.currency,
                            date: expense.date,
                            description: descCtrl.text,
                          );
                          setState(() {
                            final index = _currentTrip!.expenses.indexOf(
                              expense,
                            );
                            if (index >= 0) {
                              _currentTrip!.expenses[index] = updatedExpense;
                            }
                          });
                          Navigator.pop(ctx);
                          Fluttertoast.showToast(msg: 'Expense updated');
                          _progressController.forward(from: 0);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _currentTrip!.expenses.remove(expense));
                      Navigator.pop(ctx);
                      Fluttertoast.showToast(msg: 'Expense deleted');
                      _progressController.forward(from: 0);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading || _currentTrip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final trip = _currentTrip!;
    final percentUsed = trip.budgetLimit > 0
        ? (trip.totalSpent / trip.budgetLimit).clamp(0.0, 2.0)
        : 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color.fromARGB(0, 32, 148, 202),
        centerTitle: true,
        title: Text('👜TravelWallet', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.iconTheme.color),
            onPressed: _resetTrip,
            tooltip: 'Reset Trip',
          ),
          IconButton(
            icon: Icon(Icons.settings, color: theme.iconTheme.color),
            onPressed: () => _openEditTripSheet(trip),
            tooltip: 'Edit Trip',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Selector Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedTripId,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _trips
                            .map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text('Current Trip: ${t.name}'),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          if (id != null) {
                            setState(() => _selectedTripId = id);
                            _progressController.forward(from: 0);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _openCreateTripSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),

            // Trip Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total Spent',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Rs. ${trip.totalSpent.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Budget Limit',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                'Rs. ${trip.budgetLimit.toStringAsFixed(0)}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (trip.totalSpent > trip.budgetLimit)
                                Text(
                                  'Over by Rs. ${(trip.totalSpent - trip.budgetLimit).toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              else
                                Text(
                                  'Remaining: Rs. ${(trip.budgetLimit - trip.totalSpent).toStringAsFixed(0)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Animated Progress Bar
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (ctx, _) {
                          final animatedPercent =
                              (_progressAnimation.value) * percentUsed;
                          Color progressColor = Colors.green;
                          if (percentUsed >= 1.0) {
                            progressColor = Colors.red;
                          } else if (percentUsed >= 0.7) {
                            progressColor = Colors.orange;
                          }

                          return Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: animatedPercent.clamp(0.0, 1.0),
                                  minHeight: 12,
                                  backgroundColor: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.06),
                                  valueColor: AlwaysStoppedAnimation(
                                    progressColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${(percentUsed * 100).clamp(0, 200).toStringAsFixed(1)}% used',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    percentUsed > 1.0
                                        ? 'Budget Exceeded!'
                                        : '${((1 - percentUsed) * 100).toStringAsFixed(0)}% remaining',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip('Today'),
                  const SizedBox(width: 8),
                  _buildFilterChip('This Trip'),
                  const SizedBox(width: 8),
                  _buildFilterChip('All'),
                ],
              ),
            ),

            // Quick-add category buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _quickCategoryButton('🍔', 'Food'),
                    const SizedBox(width: 8),
                    _quickCategoryButton('🚕', 'Transport'),
                    const SizedBox(width: 8),
                    _quickCategoryButton('🛍', 'Shopping'),
                    const SizedBox(width: 8),
                    _quickCategoryButton('🏨', 'Accommodation'),
                    const SizedBox(width: 8),
                    _quickCategoryButton('🎟', 'Activities'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Expense List
            Expanded(
              child: trip.expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No expenses yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first expense',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                      itemCount: trip.expenses.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, idx) {
                        final expense = trip.expenses[idx];
                        return _expenseCard(expense, theme);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton(
          onPressed: () => _openAddExpenseSheet(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _activeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _activeFilter = label),
    );
  }

  Widget _quickCategoryButton(String emoji, String label) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        elevation: 0,
      ),
      onPressed: () => _openAddExpenseSheet(category: label),
      icon: Text(emoji, style: const TextStyle(fontSize: 16)),
      label: Text(label),
    );
  }

  Widget _expenseCard(Expense expense, ThemeData theme) {
    return GestureDetector(
      onTap: () => _openEditExpenseSheet(expense),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: CircleAvatar(
            radius: 26,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            child: Text(
              ExpenseCategory.getIcon(expense.category),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(expense.description, style: theme.textTheme.titleMedium),
          subtitle: Text(
            '${expense.category} • ${_formatDate(expense.date)}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          trailing: Text(
            'Rs. ${expense.amount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
