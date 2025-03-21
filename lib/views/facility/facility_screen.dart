// lib/views/facility/facility_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/user_model.dart';
import '../../models/facility_model.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/facility_repository.dart';
import '../../services/image_service.dart';
import '../profile/edit_profile_screen.dart'; // Correction du chemin d'importation
import '../profile/sport_selection_screen.dart'; // Correction du chemin d'importation
import 'facility_detail_screen.dart';

class FacilityScreen extends StatefulWidget {
  const FacilityScreen({Key? key}) : super(key: key);

  @override
  _FacilityScreenState createState() => _FacilityScreenState();
}

class _FacilityScreenState extends State<FacilityScreen> {
  final _authRepository = AuthRepository();
  final _facilityRepository = FacilityRepository();
  final _imageService = ImageService();

  UserModel? _user;
  List<SportFacilityModel> _facilities = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedArrondissement;

  final List<String> _arrondissements = [
    'Tous',
    '1er',
    '2ème',
    '3ème',
    '4ème',
    '5ème',
    '6ème',
    '7ème',
    '8ème',
    '9ème',
    '10ème',
    '11ème',
    '12ème',
    '13ème',
    '14ème',
    '15ème',
    '16ème',
    '17ème',
    '18ème',
    '19ème',
    '20ème',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _user = await _authRepository.getCurrentUser();
      _facilities = await _facilityRepository.getAllFacilities();
    } catch (e) {
      setState(() {
        _errorMessage =
            'Erreur lors du chargement des données: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<SportFacilityModel> _getFilteredFacilities() {
    return _facilities.where((facility) {
      final nameMatches =
          facility.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final addressMatches =
          facility.address.toLowerCase().contains(_searchQuery.toLowerCase());

      final arrondissementMatches = _selectedArrondissement == null ||
          _selectedArrondissement == 'Tous' ||
          facility.arrondissement == _selectedArrondissement;

      return (nameMatches || addressMatches) && arrondissementMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final filteredFacilities = _getFilteredFacilities();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Installations sportives'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une installation...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Filtre par arrondissement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Arrondissement',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              value: _selectedArrondissement ?? 'Tous',
              items: _arrondissements
                  .map((arr) => DropdownMenuItem(
                        value: arr,
                        child: Text(arr),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedArrondissement = value;
                });
              },
            ),
          ),

          const SizedBox(height: 8),

          // Liste des installations
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : filteredFacilities.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sports_gymnastics,
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune installation trouvée',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            if (_searchQuery.isNotEmpty ||
                                _selectedArrondissement != 'Tous')
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _selectedArrondissement = 'Tous';
                                  });
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Effacer les filtres'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFacilities.length,
                        itemBuilder: (context, index) {
                          final facility = filteredFacilities[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FacilityDetailScreen(
                                      facility: facility,
                                      sports: [], // Vous devrez passer les sports ici
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12)),
                                    child: facility.photoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: facility.photoUrl!,
                                            height: 150,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Container(
                                              height: 150,
                                              color: Colors.grey.shade300,
                                              child: const Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Container(
                                              height: 150,
                                              color: Colors.grey.shade300,
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 48),
                                            ),
                                          )
                                        : Container(
                                            height: 150,
                                            color: Colors.blue.shade100,
                                            child: Center(
                                              child: Icon(Icons.sports,
                                                  size: 48,
                                                  color: Colors.blue.shade700),
                                            ),
                                          ),
                                  ),

                                  // Informations
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          facility.name,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 16,
                                                color: Colors.grey.shade700),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                facility.address,
                                                style: TextStyle(
                                                    color:
                                                        Colors.grey.shade700),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Arrondissement
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            facility.arrondissement,
                                            style: TextStyle(
                                                color: Colors.blue.shade800,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
