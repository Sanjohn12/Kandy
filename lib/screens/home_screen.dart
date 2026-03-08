import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_map/flutter_map.dart'; // Ensure flutter_map: ^7.0.0 in pubspec.yaml
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme_provider.dart';
import 'package:my_app/screens/budget_screen.dart';
import 'package:my_app/providers/favorites_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'login_screen.dart'; // Ensure this file exists for logout functionality
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui'; // Required for ImageFilter
import '../models/place_model.dart';
import '../services/place_service.dart';
import '../widgets/skeleton_loader.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';
import '../services/routing_service.dart';
// --- Data & Constants ---

const Color customBlue = Color.fromARGB(255, 6, 180, 233);
const Color customRed = Color.fromARGB(255, 255, 118, 100);

// --- Main Home Screen Wrapper ---

// --- Main Home Screen Wrapper ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of screens for bottom navigation
  late final List<Widget> _screens = [
    const _HomeContent(),
    const MapScreen(),
    AIGuideScreen(onViewMap: () => _onItemTapped(1)),
    const SavedPlacesScreen(),
    const BudgetTrackerScreen(),
    CommunityScreen(currentUserId: _getUserId()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Stack for Glassmorphic Nav Bar to overlay
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Visibility(
              visible: MediaQuery.of(context).viewInsets.bottom == 0,
              child: _ModernBottomNavBar(
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ),
          ),
        ],
      ),
      endDrawer: const _AppDrawer(),
      extendBody: true, // Crucial for Glassmorphism
    );
  }
}

class _AppDrawer extends StatefulWidget {
  const _AppDrawer();

  @override
  State<_AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<_AppDrawer> {
  String _language = 'English'; // Mock state

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    String? name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    String? email = user?.email;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    return 'Traveler';
  }

  String _getUserEmail() {
    return FirebaseAuth.instance.currentUser?.email ?? 'No Email';
  }

  String _getUserInitial() {
    final name = _getUserName();
    return name.isNotEmpty ? name[0].toUpperCase() : '👤';
  }

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Fluttertoast.showToast(msg: "Logged out successfully!");
    if (context.mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: _getUserName(),
    );
    final BuildContext stateContext = context;
    showDialog(
      context: stateContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Enter new name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await FirebaseAuth.instance.currentUser?.updateDisplayName(
                  nameController.text,
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (mounted) setState(() {}); // Refresh drawer
                Fluttertoast.showToast(msg: "Name updated!");
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    _getUserInitial(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                accountName: Text(
                  _getUserName(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(_getUserEmail()),
              ),
              // --- Gamification Section: My Badges ---
              FutureBuilder<AppUser?>(
                future: UserService()
                    .getUserById(FirebaseAuth.instance.currentUser?.uid ?? ''),
                builder: (context, snapshot) {
                  final badges = snapshot.data?.earnedBadges ?? [];
                  if (badges.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          "My Badges (${badges.length})",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.grey),
                        ),
                      ),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: badges.length,
                          itemBuilder: (context, index) {
                            final badge = badges[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Tooltip(
                                message:
                                    "${badge['name']}: ${badge['description']}",
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color:
                                            Colors.amber.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.amber
                                                .withValues(alpha: 0.3)),
                                      ),
                                      child: Text(badge['icon'] ?? '🏅',
                                          style: const TextStyle(fontSize: 20)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      badge['name']?.split(' ').first ?? '',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Name'),
                onTap: _showEditNameDialog,
              ),
              SwitchListTile(
                secondary: Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                  Fluttertoast.showToast(
                    msg: value ? "Dark mode enabled" : "Light mode enabled",
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                subtitle: Text(_language),
                onTap: () {
                  // Mock language switch
                  setState(() {
                    _language = _language == 'English' ? 'Sinhala' : 'English';
                  });
                  Fluttertoast.showToast(
                    msg: "Language switched to $_language",
                  );
                },
              ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => _logout(context),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// --- 1. Home Tab Content ---

class _HomeContent extends StatefulWidget {
  const _HomeContent();

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  String _selectedCategory = 'All'; // Track selected category
  String _searchQuery = ''; // Track search input
  final PlaceService _placeService = PlaceService();
  final SearchController _searchController = SearchController();
  late Stream<List<Place>> _placesStream;

  @override
  void initState() {
    super.initState();
    _placesStream = _placeService.getPlaces();
    _searchController.addListener(_handleSearchControllerChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchControllerChange);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchControllerChange() {
    // Sync the search query for filtering the grid
    if (_searchQuery != _searchController.text.toLowerCase()) {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Place>>(
      stream: _placesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const HomeScreenSkeleton();
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final allPlaces = snapshot.data ?? [];
        final filteredPlaces = _filterPlaces(allPlaces);

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Premium Collapsing Header
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              actions: const [SizedBox.shrink()],
              flexibleSpace: const FlexibleSpaceBar(
                background: _ModernHeader(),
                stretchModes: [
                  StretchMode.blurBackground,
                  StretchMode.zoomBackground
                ],
              ),
            ),

            // Search Bar (Sticky-like feel via SliverToBoxAdapter)
            SliverToBoxAdapter(
              child: _ModernSearchBar(
                controller: _searchController,
                allPlaces: allPlaces,
              ),
            ),

            // Sticky Categories
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverCategoryDelegate(
                child: _ModernCategoryList(
                  onCategorySelected: _onCategorySelected,
                  selectedCategory: _selectedCategory,
                ),
              ),
            ),

            // Main Content Grid
            SliverPadding(
              padding: const EdgeInsets.only(top: 10, bottom: 100),
              sliver: filteredPlaces.isEmpty && _searchQuery.isNotEmpty
                  ? SliverToBoxAdapter(
                      child: const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: Text(
                            "No places found matching your search.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    )
                  : filteredPlaces.isEmpty
                      ? SliverToBoxAdapter(
                          child: const Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                "No places available in this category.",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : _ModernSectionSliver(
                          title: _selectedCategory == 'All'
                              ? 'Popular Places'
                              : '$_selectedCategory Locations',
                          places: filteredPlaces,
                          icon: _getCategoryIcon(_selectedCategory),
                        ),
            ),
          ],
        );
      },
    );
  }

  List<Place> _filterPlaces(List<Place> places) {
    if (_searchQuery.isEmpty) return places;
    return places.where((place) {
      final name = place.name.toLowerCase();
      final desc = place.description.toLowerCase();
      final locName = place.location.toLowerCase();
      return name.contains(_searchQuery) ||
          desc.contains(_searchQuery) ||
          locName.contains(_searchQuery);
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Temples':
        return Icons.temple_buddhist;
      case 'Nature':
        return Icons.forest;
      case 'City':
        return Icons.location_city;
      case 'Food':
        return Icons.restaurant;
      case 'History':
        return Icons.gavel;
      default:
        return Icons.explore;
    }
  }
}

// Fixed Header Delegate for Sticky Categories
class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  double get minExtent => 70.0;
  @override
  double get maxExtent => 70.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor
          .withOpacity(shrinkOffset > 0 ? 0.9 : 1.0),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverCategoryDelegate oldDelegate) => false;
}

// Placeholder for HomeScreenSkeleton if not defined elsewhere
class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ModernHeader(),
          const SizedBox(height: 20),
          _ModernSearchBar(
            controller: SearchController(),
            allPlaces: const [],
          ),
          const SizedBox(height: 25),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children:
                  List.generate(5, (index) => SkeletonLoader.categoryItem()),
            ),
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const SkeletonLoader(width: 200, height: 30),
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children:
                  List.generate(3, (index) => SkeletonLoader.locationCard()),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 2. Place Details Screen ---

class PlaceDetailsScreen extends StatefulWidget {
  final Place place;

  const PlaceDetailsScreen({super.key, required this.place});

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  double? _elevation;
  bool _loadingElevation = true;
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    _fetchElevation();
  }

  Future<void> _fetchElevation() async {
    try {
      final elev = await _weatherService.fetchElevation(
          widget.place.coordinates.latitude,
          widget.place.coordinates.longitude);
      if (mounted) {
        setState(() {
          _elevation = elev;
          _loadingElevation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingElevation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = widget.place;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Full Image
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.45,
            child: Hero(
              tag: 'place_img_${place.id}',
              child: _buildPlaceImage(
                place.image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Back Button
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: theme.cardColor.withOpacity(0.7),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            top: MediaQuery.of(context).size.height * 0.4,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          Text(
                            place.rating.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: customBlue,
                        size: 18,
                      ),
                      Text(
                        place.location,
                        style: const TextStyle(
                          color: customBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_elevation != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: customBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: customBlue.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.terrain,
                                color: customBlue,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${_elevation!.toStringAsFixed(0)}m",
                                style: const TextStyle(
                                  color: customBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "ASL",
                                style: TextStyle(
                                  color: customBlue.withOpacity(0.7),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_loadingElevation) ...[
                        const SizedBox(width: 16),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: customBlue,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "About",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.description,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.8),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _CheckInButton(place: place),
                          if (place.history.isNotEmpty) ...[
                            const SizedBox(height: 30),
                            Row(
                              children: [
                                const Icon(Icons.history_edu,
                                    color: Colors.brown, size: 24),
                                const SizedBox(width: 8),
                                Text(
                                  "Cultural History",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.titleMedium?.color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: Colors.orange.withOpacity(0.1)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (place.historyImage != null) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _buildPlaceImage(
                                        place.historyImage!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: 180,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Archival Reference",
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.grey),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Text(
                                    place.history,
                                    style: TextStyle(
                                      fontFamily: 'Georgia',
                                      fontSize: 15,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.9),
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // View Route Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapScreen(targetPlace: place),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.map),
                      label: const Text(
                        "View Route",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 3. Map Screen (Uses flutter_map) ---

class MapScreen extends StatefulWidget {
  final Place? targetPlace;

  const MapScreen({super.key, this.targetPlace});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Use 'late' so we can initialize it properly
  late final MapController _mapController;
  final SearchController _searchController = SearchController();

  LatLng _center = const LatLng(7.2906, 80.6337); // Kandy Default
  double _zoom = 13.0;
  bool _isMapReady = false;

  // --- New state fields for Locate Me & Directions ---
  LatLng? _userLocation; // Current GPS position of the user
  LatLng? _searchedLocation; // LatLng of the searched/target POI
  bool _isLocating = false; // Loading indicator for Locate Me

  // --- Real-world Routing variables ---
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  double _routeDurationMinutes = 0.0;
  double? _routeCostCar;
  double? _routeCostBike;
  double? _routeCostTuk;
  double? _routeCo2SavedKg; // New field for CO2 tracking
  TravelMode _travelMode = TravelMode.driving;
  bool _isSosActive = false; // SOS mode state
  Place? _nearestHospital;
  Place? _nearestPolice;
  Place? _nearestPharmacy;
  bool _isFetchingRoute = false;
  final RoutingService _routingService = RoutingService();
  final PlaceService _placeService = PlaceService();
  final WeatherService _weatherService = WeatherService(); // Initialize service
  List<Place> _allPlaces = [];
  StreamSubscription<Position>? _positionStreamSubscription;

  // Weather state
  double? _temperature;
  int? _weatherCode;
  String _weatherLocationName = 'Kandy';
  LatLng _weatherLatLng = const LatLng(7.2906, 80.6337);
  bool _isWeatherLoading = false;
  double? _elevation;

  Future<void> _updateWeather(LatLng location, String name) async {
    if (_isWeatherLoading) return;
    setState(() {
      _isWeatherLoading = true;
      _weatherLatLng = location;
      _weatherLocationName = name;
    });
    try {
      // Fetch both in parallel, but handle them individually so one failing doesn't stop the other
      final weatherFuture =
          _weatherService.fetchWeather(location.latitude, location.longitude);
      final elevationFuture =
          _weatherService.fetchElevation(location.latitude, location.longitude);

      // Handle weather
      weatherFuture.then((data) {
        if (mounted) {
          setState(() {
            _temperature = data.temperature;
            _weatherCode = data.weatherCode;
          });
        }
      }).catchError((e) {
        debugPrint('Weather update error: $e');
        return null;
      });

      // Handle elevation
      elevationFuture.then((elev) {
        if (mounted) {
          setState(() {
            _elevation = elev;
          });
        }
      }).catchError((e) {
        debugPrint('Elevation update error: $e');
        return null;
      });

      // Finalize loading state when BOTH are done (or failed)
      await Future.wait([
        weatherFuture.catchError((_) => WeatherData(
            temperature: 0, weatherCode: 0)), // Dummy data to satisfy wait
        elevationFuture.catchError((_) => null),
      ]);

      if (mounted) {
        setState(() {
          _isWeatherLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Overall Weather/Elevation update error: $e');
      if (mounted) {
        setState(() => _isWeatherLoading = false);
      }
    }
  }

  Future<void> _fetchRoute() async {
    if (_userLocation == null || _searchedLocation == null) return;

    setState(() {
      _isFetchingRoute = true;
      _routePoints = []; // Clear old route while fetching
    });

    try {
      final routeData = await _routingService.fetchRoute(
        _userLocation!,
        _searchedLocation!,
        _travelMode,
      );

      if (routeData != null && mounted) {
        setState(() {
          _routePoints = routeData.points;
          _routeDistanceKm = routeData.distanceKm;
          _routeDurationMinutes = routeData.durationMinutes;
          _routeCostCar = routeData.costCar;
          _routeCostBike = routeData.costBike;
          _routeCostTuk = routeData.costTuk;
          _routeCo2SavedKg = routeData.co2SavedKg;
          _isFetchingRoute = false;
        });
      } else {
        if (mounted) {
          setState(() => _isFetchingRoute = false);
          Fluttertoast.showToast(
            msg: "⚠️ Could not fetch real route. Showing straight line.",
            backgroundColor: Colors.orange,
            textColor: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
      if (mounted) {
        setState(() => _isFetchingRoute = false);
        String msg = "Connection error while fetching route.";
        if (kIsWeb) {
          msg = "CORS restricted. Please click the proxy link provided.";
        }
        Fluttertoast.showToast(msg: msg);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // If a target is passed from another screen, update the center immediately
    if (widget.targetPlace != null) {
      _center = widget.targetPlace!.coordinates;
      _searchedLocation = widget.targetPlace!.coordinates;
      _weatherLocationName = widget.targetPlace!.name;
      _zoom = 15.0;
    }
    _loadPlaces();
    _updateWeather(_center, 'Kandy'); // Initial weather fetch
  }

  Future<void> _loadPlaces() async {
    _placeService.getPlaces().listen((places) {
      if (mounted) {
        setState(() {
          _allPlaces = places;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- Locate Me: Gets GPS and centres map on user ---
  Future<void> _locateMe() async {
    setState(() => _isLocating = true);

    try {
      // 1. Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Fluttertoast.showToast(
            msg: 'Location services are disabled. Please enable GPS.');
        setState(() => _isLocating = false);
        return;
      }

      // 2. Check / request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Fluttertoast.showToast(msg: 'Location permission denied.');
          setState(() => _isLocating = false);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        Fluttertoast.showToast(
            msg:
                'Location permission permanently denied. Enable it in Settings.');
        setState(() => _isLocating = false);
        return;
      }

      // 3. Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final myLatLng = LatLng(position.latitude, position.longitude);

      if (_isMapReady) {
        _mapController.move(myLatLng, 15.0);
      }

      setState(() {
        _userLocation = myLatLng;
        _center = myLatLng;
        _weatherLocationName = 'Your Location';
        _zoom = 15.0;
        _isLocating = false;
      });

      // Start continuous tracking if not already started
      _startTracking();

      // Fetch weather and elevation for user location
      _updateWeather(myLatLng, 'Your Location');

      if (_searchedLocation != null) {
        _fetchRoute();
      }

      Fluttertoast.showToast(msg: '📍 Real-time tracking enabled!');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Could not get location: $e');
      setState(() => _isLocating = false);
    }
  }

  void _startTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        final newLatLng = LatLng(position.latitude, position.longitude);
        setState(() {
          _userLocation = newLatLng;
        });

        // Optionally update route if moving and route is visible
        if (_searchedLocation != null && _routePoints.isNotEmpty) {
          _fetchRoute();
        }
      }
    });
  }

  // --- Search: find POI AND set direction target ---
  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    final lowerQuery = query.toLowerCase();

    final results = _allPlaces.where((place) {
      final name = place.name.toLowerCase();
      return name.contains(lowerQuery);
    }).toList();

    if (results.isNotEmpty && _isMapReady) {
      final match = results.first;
      final LatLng coords = match.coordinates;

      _mapController.move(coords, 15.0);

      setState(() {
        _center = coords;
        _zoom = 15.0;
        _weatherLocationName = match.name;
        _searchedLocation = coords; // set direction target
      });

      _updateWeather(
          coords, match.name); // Update weather for searched location

      if (_userLocation != null) {
        _fetchRoute();
      }

      // Show direction hint if user location is known
      if (_userLocation != null) {
        Fluttertoast.showToast(msg: '🗺️ Showing route to ${match.name}');
      } else {
        Fluttertoast.showToast(
            msg:
                '📍 Flying to ${match.name}. Tap "Locate Me" to see your route.');
      }
      FocusManager.instance.primaryFocus?.unfocus();
    } else if (!_isMapReady) {
      Fluttertoast.showToast(msg: 'Map is still loading, please wait...');
    } else {
      Fluttertoast.showToast(msg: 'Location not found.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build polyline points if both user location and destination are known
    final List<List<LatLng>> polylines = [];
    if (_routePoints.isNotEmpty) {
      polylines.add(_routePoints);
    } else if (_userLocation != null && _searchedLocation != null) {
      if (!_isFetchingRoute) {
        polylines.add([_userLocation!, _searchedLocation!]);
      }
    }

    // Build all markers
    final List<Place> displayPlaces = _isSosActive
        ? _allPlaces
            .where((p) => ['hospital', 'police', 'pharmacy']
                .any((cat) => p.category.toLowerCase().contains(cat)))
            .toList()
        : _allPlaces;

    final List<Marker> markers = [
      // POI markers from Firestore
      ...displayPlaces.map((place) {
        final isTarget = _searchedLocation != null &&
            place.coordinates.latitude == _searchedLocation!.latitude &&
            place.coordinates.longitude == _searchedLocation!.longitude;
        return Marker(
          point: place.coordinates,
          width: 80,
          height: 80,
          child: _buildMarkerIcon(place, isTarget),
        );
      }),
    ];

    // User location marker (teal dot)
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 60,
          height: 60,
          child: Container(
            decoration: BoxDecoration(
              color: customBlue.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: customBlue, width: 2),
            ),
            child: const Icon(Icons.person_pin_circle,
                color: customBlue, size: 36),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // --- THE MAP ---
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: _zoom,
              onMapReady: () {
                setState(() => _isMapReady = true);
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.kandy_travel_app',
              ),
              // --- DIRECTION POLYLINE ---
              if (polylines.isNotEmpty)
                PolylineLayer(
                  polylines: polylines
                      .map((points) => Polyline(
                            points: points,
                            strokeWidth: 5.0,
                            color: customBlue.withOpacity(0.8),
                          ))
                      .toList(),
                ),
              // --- MARKERS ---
              MarkerLayer(markers: markers),
            ],
          ),

          // --- SOS BUTTON ---
          _buildSosButton(),

          // --- SEARCH BAR OVERLAY ---
          _buildSearchOverlay(),

          // --- WEATHER OVERLAY ---
          _buildWeatherOverlay(),

          // --- LOCATE ME BUTTON ---
          _buildLocateMeButton(),

          // --- ROUTE INFO CHIP (shows when route is active) ---
          if (_userLocation != null && _searchedLocation != null) ...[
            _buildMobilitySelector(),
            _buildRouteInfoChip(),
          ],

          // --- EMERGENCY DASHBOARD (SOS MODE) ---
          if (_isSosActive) _buildEmergencyDashboard(),
        ],
      ),
    );
  }

  Widget _buildMarkerIcon(Place place, bool isTarget) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (c) => PlaceDetailsScreen(place: place))),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated Pulse for Target
          if (isTarget)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.4),
              duration: const Duration(seconds: 1),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 40 * value,
                  height: 40 * value,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.4 * (1.5 - value)),
                    shape: BoxShape.circle,
                  ),
                );
              },
              onEnd:
                  () {}, // Handled by repeating tween if needed, but simple pulse is fine
            ),
          // Main Marker
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isTarget ? Colors.red : Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(
                color: isTarget ? Colors.redAccent : Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              _getCategoryIcon(place.category),
              color: isTarget ? Colors.white : customBlue,
              size: 20,
            ),
          ),
          // Name Label (Optional, showing on long press or small text below)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                place.name.split(' ').first,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 7,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'nature':
        return Icons.nature_people;
      case 'temple':
        return Icons.temple_hindu;
      case 'museum':
        return Icons.museum;
      case 'city':
        return Icons.location_city;
      case 'park':
        return Icons.park;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.location_on;
    }
  }

  Widget _buildLocateMeButton() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: FloatingActionButton(
        heroTag: 'locate_me',
        onPressed: _isLocating ? null : _locateMe,
        backgroundColor: Colors.white,
        elevation: 6,
        tooltip: 'Locate Me',
        child: _isLocating
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: customBlue),
              )
            : const Icon(Icons.my_location, color: customBlue, size: 28),
      ),
    );
  }

  Widget _buildSosButton() {
    return Positioned(
      bottom: 170,
      right: 20,
      child: FloatingActionButton(
        heroTag: 'sos_button',
        onPressed: _toggleSosMode,
        backgroundColor: _isSosActive ? Colors.red : Colors.white,
        elevation: 8,
        tooltip: 'Safety & Help',
        child: Icon(
          _isSosActive ? Icons.close : Icons.sos,
          color: _isSosActive ? Colors.white : Colors.red,
          size: 28,
        ),
      ),
    );
  }

  void _toggleSosMode() {
    setState(() {
      _isSosActive = !_isSosActive;
      if (_isSosActive) {
        _findNearestEmergencyServices();
        if (_nearestHospital == null &&
            _nearestPolice == null &&
            _nearestPharmacy == null) {
          Fluttertoast.showToast(
              msg: "No emergency services found in our database yet.");
        } else {
          Fluttertoast.showToast(
            msg: "Safety Mode Active! Markers filtered for help.",
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        Fluttertoast.showToast(msg: "Safety Mode Disabled.");
      }
    });
  }

  void _findNearestEmergencyServices() {
    if (_userLocation == null) return;
    _nearestHospital = _findNearestByCategory('Hospital');
    _nearestPolice = _findNearestByCategory('Police');
    _nearestPharmacy = _findNearestByCategory('Pharmacy');
  }

  Place? _findNearestByCategory(String category) {
    if (_userLocation == null || _allPlaces.isEmpty) return null;

    final List<Place> emergencyPlaces = _allPlaces
        .where((p) => p.category.toLowerCase().contains(category.toLowerCase()))
        .toList();

    if (emergencyPlaces.isEmpty) return null;

    final Distance distance = const Distance();
    emergencyPlaces.sort((a, b) {
      final double d1 =
          distance.as(LengthUnit.Meter, _userLocation!, a.coordinates);
      final double d2 =
          distance.as(LengthUnit.Meter, _userLocation!, b.coordinates);
      return d1.compareTo(d2);
    });

    return emergencyPlaces.first;
  }

  Widget _buildMobilitySelector() {
    return Positioned(
      bottom: 110,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMobilityItem(TravelMode.driving, Icons.directions_car),
                _buildMobilityItem(TravelMode.cycling, Icons.directions_bike),
                _buildMobilityItem(TravelMode.walking, Icons.directions_walk),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobilityItem(TravelMode mode, IconData icon) {
    bool isSelected = _travelMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            _travelMode = mode;
          });
          _fetchRoute();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? customBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey,
              size: 18,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  mode.name[0].toUpperCase() + mode.name.substring(1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyDashboard() {
    return Positioned(
      top: 150,
      left: 20,
      right: 20,
      child: Column(
        children: [
          if (_nearestHospital != null)
            _buildEmergencyItem(
                'Nearest Hospital', _nearestHospital!, Colors.red),
          if (_nearestPolice != null)
            _buildEmergencyItem('Nearest Police', _nearestPolice!, Colors.blue),
          if (_nearestPharmacy != null)
            _buildEmergencyItem(
                'Nearest Pharmacy', _nearestPharmacy!, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(String label, Place place, Color color) {
    final Distance distance = const Distance();
    final double meters = _userLocation != null
        ? distance.as(LengthUnit.Meter, _userLocation!, place.coordinates)
        : 0;
    final String distanceText = meters > 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.toInt()} m';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Icon(
              label.contains('Hospital')
                  ? Icons.local_hospital
                  : label.contains('Police')
                      ? Icons.local_police
                      : Icons.local_pharmacy,
              color: color,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                  Text(
                    place.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Distance: $distanceText',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.directions, color: color),
              onPressed: () {
                setState(() {
                  _searchedLocation = place.coordinates;
                  _isSosActive = false; // Turn off SOS to show route
                });
                _fetchRoute();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoChip() {
    String distanceText = '${_routeDistanceKm.toStringAsFixed(1)} km';

    if (_isFetchingRoute) {
      distanceText = 'Computing...';
    } else if (_routePoints.isEmpty &&
        _userLocation != null &&
        _searchedLocation != null) {
      final Distance distance = const Distance();
      final double km = distance.as(
        LengthUnit.Kilometer,
        _userLocation!,
        _searchedLocation!,
      );
      distanceText = '${km.toStringAsFixed(1)} km (line)';
    }

    String durationText = '';
    if (_routeDurationMinutes > 0) {
      if (_routeDurationMinutes >= 60) {
        int hours = _routeDurationMinutes ~/ 60;
        int mins = (_routeDurationMinutes % 60).toInt();
        durationText = '${hours}h ${mins}m';
      } else {
        durationText = '${_routeDurationMinutes.toStringAsFixed(0)} min';
      }
    }

    // --- Format Costs ---
    final NumberFormat currencyFormat = NumberFormat.currency(
      symbol: 'Rs ',
      decimalDigits: 0,
    );
    String costCarText =
        _routeCostCar != null ? currencyFormat.format(_routeCostCar) : '';
    String costBikeText =
        _routeCostBike != null ? currencyFormat.format(_routeCostBike) : '';
    String costTukText =
        _routeCostTuk != null ? currencyFormat.format(_routeCostTuk) : '';

    IconData modeIcon;
    switch (_travelMode) {
      case TravelMode.walking:
        modeIcon = Icons.directions_walk;
        break;
      case TravelMode.cycling:
        modeIcon = Icons.directions_bike;
        break;
      case TravelMode.driving:
        modeIcon = Icons.directions_car;
        break;
    }

    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(modeIcon, color: customBlue, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dist: $distanceText',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        if (durationText.isNotEmpty)
                          Text(
                            'Time: $durationText',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        if (costCarText.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                _buildCostItem(Icons.directions_car,
                                    costCarText, Colors.blue),
                                const SizedBox(width: 12),
                                _buildCostItem(Icons.motorcycle, costBikeText,
                                    Colors.green),
                                const SizedBox(width: 12),
                                _buildCostItem(Icons.electric_rickshaw,
                                    costTukText, Colors.orange),
                              ],
                            ),
                          ),
                        if (_routeCo2SavedKg != null && _routeCo2SavedKg! > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.eco,
                                    color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'CO2 Saved: ${_routeCo2SavedKg!.toStringAsFixed(2)} kg',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.black12,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          _searchedLocation = null;
                          _routePoints = [];
                          _routeDistanceKm = 0.0;
                          _routeDurationMinutes = 0.0;
                          _routeCostCar = null;
                          _routeCostBike = null;
                          _routeCostTuk = null;
                          _routeCo2SavedKg = null;
                          _searchController.clear();
                        });
                      },
                      icon:
                          const Icon(Icons.close, color: Colors.grey, size: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostItem(IconData icon, String cost, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          cost,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: color.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: SearchAnchor(
        searchController: _searchController,
        builder: (context, controller) {
          return SearchBar(
            controller: controller,
            hintText: 'Search Kandy...',
            onTap: () => controller.openView(),
            onSubmitted: _performSearch,
            leading: const Icon(Icons.search),
            trailing: [
              IconButton(
                icon: const Icon(Icons.mic, color: Colors.blue),
                onPressed: () => Fluttertoast.showToast(msg: 'Listening...'),
              )
            ],
            backgroundColor:
                MaterialStateProperty.all(Colors.white.withOpacity(0.9)),
            elevation: MaterialStateProperty.all(2),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
            )),
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
          final filtered = _allPlaces
              .where((place) => place.name.toLowerCase().contains(query))
              .toList();

          if (filtered.isEmpty) {
            return [
              const ListTile(
                title: Text('No results found'),
              )
            ];
          }

          return filtered.map((place) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: place.image.startsWith('assets/')
                    ? Image.asset(place.image,
                        width: 40, height: 40, fit: BoxFit.cover)
                    : Image.network(place.image,
                        width: 40, height: 40, fit: BoxFit.cover),
              ),
              title: Text(place.name),
              subtitle: Text(place.location),
              onTap: () {
                controller.closeView(place.name);
                _performSearch(place.name);
              },
            );
          }).toList();
        },
      ),
    );
  }

  Widget _buildWeatherOverlay() {
    return Positioned(
      top: 115,
      right: 20,
      child: GestureDetector(
        onTap: () => _showWeatherForecast(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                  _isWeatherLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync, color: customBlue, size: 16),
                  const SizedBox(width: 6),
                  _isWeatherLoading
                      ? const SizedBox.shrink()
                      : Icon(_getWeatherIcon(_weatherCode),
                          color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _weatherLocationName,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54),
                      ),
                      Row(
                        children: [
                          Text(
                            _temperature != null
                                ? '${_temperature!.toStringAsFixed(1)}°C'
                                : '--°C',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_elevation != null ||
                              (!_isWeatherLoading && _temperature != null)) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: customBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.terrain,
                                      color: customBlue, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _elevation != null
                                        ? '${_elevation!.toStringAsFixed(0)}m'
                                        : '...m',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWeatherForecast() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '7-Day Forecast',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _weatherLocationName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),

                  // Location Switcher
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _buildWeatherLocationChip(
                          'Kandy',
                          const LatLng(7.2906, 80.6337),
                          setModalState,
                        ),
                        if (_userLocation != null) ...[
                          const SizedBox(width: 8),
                          _buildWeatherLocationChip(
                            'Your Location',
                            _userLocation!,
                            setModalState,
                          ),
                        ],
                        if (_searchedLocation != null) ...[
                          const SizedBox(width: 8),
                          _buildWeatherLocationChip(
                            'Search Result',
                            _searchedLocation!,
                            setModalState,
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Expanded(
                    child: FutureBuilder<List<ForecastDay>>(
                      key: ValueKey(_weatherLatLng),
                      future: _weatherService.fetchWeeklyForecast(
                          _weatherLatLng.latitude, _weatherLatLng.longitude),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        final days = snapshot.data ?? [];
                        return ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: days.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final day = days[index];
                            final isToday = index == 0;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      isToday ? 'Today' : _getDayName(day.date),
                                      style: TextStyle(
                                        fontWeight: isToday
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Icon(_getWeatherIcon(day.weatherCode),
                                      color: Colors.orange, size: 28),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${day.maxTemp.round()}°',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          '${day.minTemp.round()}°',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherLocationChip(
      String name, LatLng latLng, StateSetter setModalState) {
    bool isSelected = _weatherLocationName == name;
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          setModalState(() {
            _updateWeather(latLng, name);
          });
          setState(() {}); // Update the overlay as well
        }
      },
      selectedColor: customBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? customBlue : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  IconData _getWeatherIcon(int? code) {
    if (code == null) return Icons.wb_sunny;
    // WMO Weather interpretation codes (WW)
    // https://open-meteo.com/en/docs
    if (code == 0) return Icons.wb_sunny; // Clear sky
    if (code >= 1 && code <= 3)
      return Icons.cloud_queue; // Mainly clear, partly cloudy, and overcast
    if (code >= 45 && code <= 48) return Icons.foggy; // Fog
    if (code >= 51 && code <= 67) return Icons.umbrella; // Drizzle, Rain
    if (code >= 71 && code <= 77) return Icons.ac_unit; // Snow
    if (code >= 80 && code <= 82) return Icons.beach_access; // Rain showers
    if (code >= 95) return Icons.thunderstorm; // Thunderstorm
    return Icons.wb_cloudy_outlined;
  }
}

// --- 4. AI Guide Screen (Chatbot Simulation) ---

class AIGuideScreen extends StatefulWidget {
  final VoidCallback? onViewMap;
  const AIGuideScreen({super.key, this.onViewMap});

  @override
  State<AIGuideScreen> createState() => _AIGuideScreenState();
}

class _AIGuideScreenState extends State<AIGuideScreen> {
  final TextEditingController _controller = TextEditingController();
  final AIService _aiService = AIService();
  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'welcome',
      userId: 'ai_guide',
      userName: 'Kandy AI Guide',
      message:
          'Hello! I am your AI travel guide for Kandy. How can I assist you with your trip today?',
      timestamp: DateTime.now(),
      type: 'admin',
    ),
  ];

  bool _isLoading = false;

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
      userName: 'You',
      message: text,
      timestamp: DateTime.now(),
      type: 'user',
    );

    setState(() {
      _messages.insert(0, userMessage);
      _isLoading = true;
    });

    _controller.clear();

    try {
      final aiResponse = await _aiService.chatQuery(text);
      _addBotResponse(aiResponse);
    } catch (e) {
      _addBotResponse(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addBotResponse(String text) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'ai_guide',
          userName: 'Kandy AI Guide',
          message: text,
          timestamp: DateTime.now(),
          type: 'admin',
        ),
      );
    });
  }

  void _showPlannerDialog() {
    final hoursController = TextEditingController();
    final interestsController = TextEditingController();
    final startController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: customBlue),
            SizedBox(width: 10),
            Text("Plan My Day"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tell our AI what you're looking for and we'll create a custom Kandy itinerary for you.",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              _buildPlannerField(
                  hoursController, "Available Time", "e.g. 4 hours, Full day"),
              _buildPlannerField(interestsController, "Interests",
                  "e.g. Nature, Temples, Local Food"),
              _buildPlannerField(startController, "Starting Point",
                  "e.g. Railway Station, Lake Round"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateItinerary(
                hoursController.text,
                interestsController.text,
                startController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: customBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Generate Plan"),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerField(
      TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ),
    );
  }

  Future<void> _generateItinerary(
      String time, String interests, String start) async {
    if (time.isEmpty || interests.isEmpty || start.isEmpty) return;

    setState(() => _isLoading = true);

    // Add a placeholder message for UX
    _addBotResponse("Generating your custom Kandy plan... Please wait.");

    try {
      final plan = await _aiService.generateItinerary(
        hours: time,
        interests: interests,
        startLocation: start,
      );

      // Remove placeholder and add real response
      setState(() {
        _messages.removeAt(0);
      });
      _addBotResponse(plan);
    } catch (e) {
      setState(() {
        _messages.removeAt(0);
      });
      _addBotResponse("Sorry, I couldn't generate the plan. $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ModernScreenHeader(
              title: 'AI Guide',
              subtitle: 'Ask me anything about Kandy',
              icon: Icons.psychology_rounded,
              color: customBlue,
              trailing: ElevatedButton.icon(
                onPressed: _showPlannerDialog,
                icon: const Icon(Icons.auto_awesome, size: 16),
                label: const Text("Plan Day", style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customBlue.withOpacity(0.1),
                  foregroundColor: customBlue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(customBlue),
              ),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                reverse: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) => _ChatMessageBubble(
                  message: _messages[index],
                  onViewMap: widget.onViewMap,
                ),
              ),
            ),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 100),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                enabled: !_isLoading,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration(
                  hintText: 'Ask your travel question...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey : customBlue,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded),
              color: Colors.white,
              onPressed:
                  _isLoading ? null : () => _handleSubmitted(_controller.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onViewMap;

  const _ChatMessageBubble({required this.message, this.onViewMap});

  bool _isItinerary(String text) {
    final lower = text.toLowerCase();
    return (lower.contains('itinerary') || lower.contains('plan')) &&
        (lower.contains('time') ||
            lower.contains('visit') ||
            lower.contains('kandy'));
  }

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.type == 'user';
    final bool hasPlan = !isUser && _isItinerary(message.message);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              backgroundColor: customBlue.withOpacity(0.1),
              child: const Icon(Icons.psychology_rounded,
                  color: customBlue, size: 20),
            ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser ? customRed : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isUser ? 20 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBody(
                    data: message.message,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                      strong: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                if (hasPlan && onViewMap != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: onViewMap,
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text("View on Map",
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customBlue,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundColor: customRed.withOpacity(0.1),
              child:
                  const Icon(Icons.person_rounded, color: customRed, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// --- 5. Saved Places Screen ---

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final PlaceService _placeService = PlaceService();

  @override
  Widget build(BuildContext context) {
    final favorites = Provider.of<FavoritesProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<Place>>(
          stream: _placeService.getPlaces(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const _ModernScreenHeader(
                    title: 'Saved Places',
                    subtitle: 'Loading your favorites...',
                    icon: Icons.bookmark_rounded,
                    color: customBlue,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: 6,
                      itemBuilder: (context, index) =>
                          SkeletonLoader.listItem(),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final allPlaces = snapshot.data ?? [];
            final savedPlaces = allPlaces
                .where((place) => favorites.isSaved(place.id))
                .toList();

            return Column(
              children: [
                _ModernScreenHeader(
                  title: 'Saved Places',
                  subtitle: '${savedPlaces.length} places saved',
                  icon: Icons.bookmark_rounded,
                  color: customBlue,
                ),
                Expanded(
                  child: savedPlaces.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bookmark_border_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No places saved yet!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the bookmark icon on places you love.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: savedPlaces.length,
                          itemBuilder: (context, index) {
                            final place = savedPlaces[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: SavedLocationTile(place: place),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class SavedLocationTile extends StatefulWidget {
  final Place place;
  const SavedLocationTile({super.key, required this.place});

  @override
  State<SavedLocationTile> createState() => _SavedLocationTileState();
}

class _SavedLocationTileState extends State<SavedLocationTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(place: widget.place),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'place_img_${widget.place.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPlaceImage(
                  widget.place.image,
                  width: 80,
                  height: 80,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: customBlue,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.place.location,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        widget.place.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_added, color: customRed),
              onPressed: () {
                Provider.of<FavoritesProvider>(context, listen: false)
                    .toggleSave(widget.place.id);
                Fluttertoast.showToast(
                  msg: "${widget.place.name} removed from saved list.",
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. Community Screen (Live Chat Simulation) ---

class CommunityScreen extends StatefulWidget {
  final String currentUserId;
  const CommunityScreen({super.key, required this.currentUserId});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // New state for Pro Chat features
  XFile? _selectedImage;
  bool _isUploading = false;
  ChatMessage? _replyingTo;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  void _onReply(ChatMessage message) {
    setState(() {
      _replyingTo = message;
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _onDelete(ChatMessage message) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Admin email check or owner check
    final bool isAdmin = user.email == 'sanoadksano@gmail.com';
    final bool isOwner = message.userId == widget.currentUserId;

    if (!isAdmin && !isOwner) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text(
            'This will permanently remove the message and any attached image.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _chatService.deleteMessage(message.id,
            imageUrl: message.imageUrl);
        Fluttertoast.showToast(msg: "Message deleted");
      } catch (e) {
        Fluttertoast.showToast(msg: "Error deleting message");
      }
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty && _selectedImage == null) return;

    final user = FirebaseAuth.instance.currentUser;
    String? imageUrl;

    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      imageUrl = await _chatService.uploadChatImage(_selectedImage!);
      setState(() => _isUploading = false);

      if (imageUrl == null) {
        Fluttertoast.showToast(msg: "Failed to upload image");
        return;
      }
    }

    final message = ChatMessage(
      id: '',
      userId: widget.currentUserId,
      userName: user?.displayName ?? user?.email?.split('@').first ?? 'You',
      message: text,
      timestamp: DateTime.now(),
      type: user?.email == 'sanoadksano@gmail.com' ? 'admin' : 'user',
      imageUrl: imageUrl,
      replyToId: _replyingTo?.id,
      replyToMessage: _replyingTo?.message,
      replyToUserName: _replyingTo?.userName,
    );

    await _chatService.sendMessage(message);

    setState(() {
      _controller.clear();
      _selectedImage = null;
      _replyingTo = null;
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _ModernScreenHeader(
              title: 'Community',
              subtitle: 'Connect with fellow travelers',
              icon: Icons.people_rounded,
              color: const Color.fromARGB(255, 56, 186, 238),
            ),
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _chatService.getMessages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No messages yet. Say hi!',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) => _CommunityMessageBubble(
                      message: messages[index],
                      currentUserId: widget.currentUserId,
                      onReply: _onReply,
                      onDelete: _onDelete,
                    ),
                  );
                },
              ),
            ),
            if (_isUploading)
              const LinearProgressIndicator(minHeight: 2, color: customBlue),
            _buildTextComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: customBlue, width: 4),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Replying to ${_replyingTo!.userName}",
                          style: const TextStyle(
                            color: customBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _replyingTo!.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: _cancelReply,
                  ),
                ],
              ),
            ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImage!.path),
                            height: 100,
                            width: 100,
                            fit: BoxFit.cover,
                          ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_rounded, color: customBlue),
                onPressed: _pickImage,
              ),
              Flexible(
                child: TextField(
                  controller: _controller,
                  onSubmitted: _handleSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Send a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: customBlue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white),
                  onPressed: () => _handleSubmitted(_controller.text),
                ),
              ),
            ],
          ),
          const SizedBox(height: 100), // Bottom padding for floating nav
        ],
      ),
    );
  }
}

class _CommunityMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentUserId;
  final Function(ChatMessage) onReply;
  final Function(ChatMessage) onDelete;

  const _CommunityMessageBubble({
    required this.message,
    required this.currentUserId,
    required this.onReply,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.userId == currentUserId;
    final bool isAdmin = message.type == 'admin';

    return Dismissible(
      key: Key(message.id),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (direction) async {
        onReply(message);
        return false; // Don't actually dismiss the widget
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: customBlue),
      ),
      child: GestureDetector(
        onLongPress: () => onDelete(message),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe)
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isAdmin
                          ? Colors.orange[100]
                          : customBlue.withOpacity(0.1),
                      child: Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.person,
                        size: 16,
                        color: isAdmin ? Colors.orange : customBlue,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message.userName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isAdmin ? Colors.orange : Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? customBlue : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 0),
                    bottomRight: Radius.circular(isMe ? 0 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyToId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isMe
                              ? Colors.white.withOpacity(0.2)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border(
                            left: BorderSide(
                              color: isMe ? Colors.white70 : customBlue,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.replyToUserName ?? 'User',
                              style: TextStyle(
                                color: isMe ? Colors.white : customBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              message.replyToMessage ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (message.imageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: _buildPlaceImage(message.imageUrl!),
                        ),
                      ),
                    if (message.message.isNotEmpty)
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Modern UI Components ---

class _ModernBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const _ModernBottomNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark
                  ? theme.cardColor.withOpacity(0.6)
                  : Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ModernNavItem(
                  icon: Icons.home_rounded,
                  isActive: selectedIndex == 0,
                  onTap: () => onTap(0),
                ),
                _ModernNavItem(
                  icon: Icons.map_rounded,
                  isActive: selectedIndex == 1,
                  onTap: () => onTap(1),
                ),
                _ModernNavItem(
                  icon: Icons.auto_awesome_rounded,
                  isActive: selectedIndex == 2,
                  onTap: () => onTap(2),
                ),
                _ModernNavItem(
                  icon: Icons.bookmark_rounded,
                  isActive: selectedIndex == 3,
                  onTap: () => onTap(3),
                ),
                _ModernNavItem(
                  icon: Icons.account_balance_wallet_rounded,
                  isActive: selectedIndex == 4,
                  onTap: () => onTap(4),
                ),
                _ModernNavItem(
                  icon: Icons.forum_rounded,
                  isActive: selectedIndex == 5,
                  onTap: () => onTap(5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernNavItem extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModernNavItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? customBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: isActive ? customBlue : Colors.grey, size: 28),
      ),
    );
  }
}

class _ModernHeader extends StatelessWidget {
  const _ModernHeader();

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    String? name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    String? email = user?.email;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first;
      return prefix[0].toUpperCase() + prefix.substring(1);
    }
    return 'Traveler';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${_getUserName()}!',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Explore Kandy',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: customBlue,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: customBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.menu_rounded,
                  color: customBlue,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernSearchBar extends StatelessWidget {
  final SearchController controller;
  final List<Place> allPlaces;

  const _ModernSearchBar({
    required this.controller,
    required this.allPlaces,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SearchAnchor(
        searchController: controller,
        builder: (context, controller) {
          return Container(
            height: 56,
            padding: const EdgeInsets.only(left: 16, right: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  color: Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onTap: () => controller.openView(),
                    onChanged: (value) {
                      // Handled by the controller listener in the parent
                    },
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      hintText: 'Search places, temples, restaurants...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 15),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: customBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(150),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: customBlue,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        suggestionsBuilder: (context, controller) {
          final query = controller.text.toLowerCase();
          final filtered = allPlaces
              .where((place) => place.name.toLowerCase().contains(query))
              .toList();

          if (filtered.isEmpty) {
            return [
              const ListTile(
                title: Text('No results found'),
              )
            ];
          }

          return filtered.map((place) {
            return ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildPlaceImage(
                  place.image,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(place.name),
              subtitle: Text(place.location),
              onTap: () {
                controller.closeView(place.name);
                // The listener on the parent handles updating the grid
              },
            );
          }).toList();
        },
      ),
    );
  }
}

class _ModernCategoryList extends StatefulWidget {
  final Function(String) onCategorySelected;
  final String selectedCategory;

  const _ModernCategoryList({
    required this.onCategorySelected,
    required this.selectedCategory,
  });

  @override
  State<_ModernCategoryList> createState() => _ModernCategoryListState();
}

class _ModernCategoryListState extends State<_ModernCategoryList> {
  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'Temples', 'icon': Icons.temple_buddhist_rounded},
    {'name': 'Nature', 'icon': Icons.forest_rounded},
    {'name': 'City', 'icon': Icons.location_city_rounded},
    {'name': 'Food', 'icon': Icons.restaurant_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final categoryName = category['name'] as String;
          final isSelected = widget.selectedCategory == categoryName;

          return GestureDetector(
            onTap: () {
              widget.onCategorySelected(categoryName);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [customBlue, Color(0xFF1E88E5)],
                      )
                    : null,
                color: isSelected ? null : theme.cardColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? customBlue.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: isSelected ? 10 : 5,
                    offset: Offset(0, isSelected ? 5 : 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    category['icon'],
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categoryName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ModernSectionSliver extends StatelessWidget {
  final String title;
  final List<Place> places;
  final IconData icon;

  const _ModernSectionSliver({
    required this.title,
    required this.places,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (places.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(40.0),
            child: Text("No places found for this category."),
          ),
        ),
      );
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: customBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: customBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ModernLocationCard(place: places[index]),
              childCount: places.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _ModernLocationCard extends StatefulWidget {
  final Place place;

  const _ModernLocationCard({required this.place});

  @override
  State<_ModernLocationCard> createState() => _ModernLocationCardState();
}

class _ModernLocationCardState extends State<_ModernLocationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(place: widget.place),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section relative to card width
                Expanded(
                  flex: 12,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Hero(
                          tag: 'place_img_${widget.place.id}',
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: _buildPlaceImage(
                              widget.place.image,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Consumer<FavoritesProvider>(
                            builder: (context, favorites, child) {
                          final isSaved = favorites.isSaved(widget.place.id);
                          return GestureDetector(
                            onTap: () {
                              favorites.toggleSave(widget.place.id);
                              final msg = !isSaved
                                  ? "${widget.place.name} saved!"
                                  : "${widget.place.name} removed from saved.";
                              Fluttertoast.showToast(msg: msg);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.cardColor.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isSaved
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: customBlue,
                                size: 18,
                              ),
                            ),
                          );
                        }),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                widget.place.rating.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (widget.place.isHiddenGem)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.purple.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.diamond,
                                    color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  "Hidden Gem",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.place.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: theme.textTheme.titleLarge?.color ??
                              Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: customBlue, size: 12),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.place.location,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildPlaceImage(String imagePath,
    {double? width, double? height, BoxFit fit = BoxFit.cover}) {
  if (imagePath.startsWith('assets/')) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildErrorImage(width, height),
    );
  } else {
    return Image.network(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (ctx, err, stack) => _buildErrorImage(width, height),
      loadingBuilder: (ctx, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      },
    );
  }
}

Widget _buildErrorImage(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    child: const Icon(Icons.broken_image, color: Colors.grey),
  );
}

// Modern Screen Header for AI Guide, Saved Places, and Community
class _ModernScreenHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget? trailing;

  const _ModernScreenHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color ??
                        Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 16),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _CheckInButton extends StatefulWidget {
  final Place place;
  const _CheckInButton({required this.place});

  @override
  State<_CheckInButton> createState() => _CheckInButtonState();
}

class _CheckInButtonState extends State<_CheckInButton> {
  bool _isCheckingIn = false;
  final UserService _userService = UserService();

  Future<void> _handleCheckIn() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      Fluttertoast.showToast(msg: "Please login to check-in!");
      return;
    }

    setState(() => _isCheckingIn = true);

    try {
      final result = await _userService.checkIn(userId, widget.place);
      if (result['success']) {
        Fluttertoast.showToast(msg: result['message']);
        if (result['newBadges'] != null &&
            (result['newBadges'] as List).isNotEmpty) {
          _showBadgeDialog(result['newBadges'][0].toString());
        }
        setState(() {}); // Rebuild
      } else {
        Fluttertoast.showToast(msg: result['message'].toString());
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Check-in failed: $e");
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  void _showBadgeDialog(String badgeName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.stars, color: Colors.amber, size: 50),
            SizedBox(height: 10),
            Text("Badge Earned!", textAlign: TextAlign.center),
          ],
        ),
        content: Text(
          "Congratulations! You've earned the '$badgeName' badge for discovering ${widget.place.name}.",
          textAlign: TextAlign.center,
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: customBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Awesome!"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: UserService()
          .getUserById(FirebaseAuth.instance.currentUser?.uid ?? ''),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final hasVisited =
            user?.visitedPlaces.contains(widget.place.id) ?? false;

        if (hasVisited) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  "Checked In",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            onPressed: _isCheckingIn ? null : _handleCheckIn,
            icon: _isCheckingIn
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.location_on),
            label: Text(
              _isCheckingIn ? "Checking..." : "Check-in here",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: customBlue,
              foregroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        );
      },
    );
  }
}
