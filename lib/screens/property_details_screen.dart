
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color detailsForest = Color(0xFF07583C);
const Color detailsMoss = Color(0xFFEAF4E8);
const Color detailsInk = Color(0xFF173329);

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailsScreen> createState() =>
      _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  static const String baseUrl =
      'https://backend-0c33.onrender.com/api';

  Map<String, dynamic>? property;
  bool loading = true;
  String? error;

  int selectedImage = 0;

  @override
  void initState() {
    super.initState();
    fetchProperty();
  }

  Future<void> fetchProperty() async {
    setState(() {
      loading = true;
      error = null;
    });

    final client = HttpClient();

    try {
      final request = await client.getUrl(
        Uri.parse('$baseUrl/properties/${widget.propertyId}'),
      );

      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/json',
      );

      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode != 200) {
        throw Exception('Unable to load property details.');
      }

      final decoded = jsonDecode(body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid property details response.');
      }

      if (!mounted) return;

      setState(() {
        property = decoded;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    } finally {
      client.close(force: true);
    }
  }

  String get title =>
      property?['title']?.toString() ?? 'Rental property';

  String get ownerName =>
      property?['owner_name']?.toString() ?? 'Property Owner';

  String get ownerPhone =>
      property?['owner_phone']?.toString() ?? '';

  String get description =>
      property?['description']?.toString() ??
      'Contact the property owner for more information.';

  String get location {
    final p = property ?? {};

    final parts = [
      p['area'],
      p['location'],
      p['city'],
      p['address'],
    ]
        .where((value) =>
            value != null && value.toString().trim().isNotEmpty)
        .map((value) => value.toString())
        .toList();

    return parts.isEmpty ? 'Rourkela, Odisha' : parts.join(', ');
  }

  String get propertyType =>
      property?['property_type']?.toString() ??
      property?['type']?.toString() ??
      'Rental';

  String money(dynamic amount) {
    if (amount == null || amount.toString().isEmpty) {
      return 'Not specified';
    }

    final number = num.tryParse(amount.toString());

    if (number == null) return amount.toString();

    return '₹${number.toStringAsFixed(number % 1 == 0 ? 0 : 2)}';
  }

  List<String> get images {
    final p = property ?? {};
    final result = <String>[];

    for (final key in ['image_urls', 'images']) {
      final value = p[key];

      if (value is List) {
        result.addAll(
          value
              .where((item) =>
                  item != null && item.toString().isNotEmpty)
              .map((item) => item.toString()),
        );
      }
    }

    for (final key in ['image_url']) {
      final value = p[key];
      if (value != null && value.toString().isNotEmpty) {
        result.add(value.toString());
      }
    }

    return result.toSet().toList();
  }

  Future<void> openContact(String value) async {
    final uri = Uri.parse(value);

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this app.')),
      );
    }
  }

  Future<void> callOwner() async {
    if (ownerPhone.isEmpty) return;
    await openContact('tel:$ownerPhone');
  }

  Future<void> whatsappOwner() async {
    if (ownerPhone.isEmpty) return;

    final phone = ownerPhone.replaceAll(RegExp(r'\D'), '');
    final fullPhone =
        phone.startsWith('91') ? phone : '91$phone';

    final message = Uri.encodeComponent(
      'Hello, I found your property on RentKhoj: $title ($location). Is it still available?',
    );

    await openContact(
      'https://wa.me/$fullPhone?text=$message',
    );
  }

  Future<void> emailOwner() async {
    final email = property?['owner_email']?.toString() ?? '';

    if (email.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Owner email is not available.'),
        ),
      );
      return;
    }

    final subject = Uri.encodeComponent('Rental enquiry: $title');
    final body = Uri.encodeComponent(
      'Hello, I am interested in $title at $location.',
    );

    await openContact('mailto:$email?subject=$subject&body=$body');
  }

  Widget infoItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: detailsMoss,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: detailsForest, size: 23),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: detailsInk,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: detailsInk,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: detailsForest),
        ),
      );
    }

    if (error != null || property == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Property details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.home_work_outlined,
                  size: 55,
                  color: detailsForest,
                ),
                const SizedBox(height: 15),
                const Text(
                  'Property unavailable',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(error ?? 'Property not found.'),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: fetchProperty,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final p = property!;
    final photos = images;

    final rent = p['monthly_rent'] ?? p['rent'] ?? p['price'];
    final deposit = p['deposit'] ?? p['security_deposit'];
    final bedrooms = p['bedrooms'] ?? p['bhk'];
    final bathrooms = p['bathrooms'];
    final furnishing = p['furnishing']?.toString() ?? 'Not specified';

    return Scaffold(
      backgroundColor: const Color(0xFFFCFDF9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 310,
            backgroundColor: detailsForest,
            foregroundColor: Colors.white,
            title: const Text(
              'Property Details',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (photos.isNotEmpty)
                    Image.network(
                      photos[selectedImage],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: detailsMoss,
                        child: const Icon(
                          Icons.home_work,
                          size: 70,
                          color: detailsForest,
                        ),
                      ),
                    )
                  else
                    Container(
                      color: detailsMoss,
                      child: const Icon(
                        Icons.home_work,
                        size: 70,
                        color: detailsForest,
                      ),
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black38,
                          Colors.transparent,
                          Colors.black26,
                        ],
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 58,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 9),
                          itemBuilder: (_, index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() => selectedImage = index);
                              },
                              child: Container(
                                width: 72,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selectedImage == index
                                        ? Colors.white
                                        : Colors.white54,
                                    width: selectedImage == index ? 3 : 1,
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(photos[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  propertyType.toUpperCase(),
                  style: const TextStyle(
                    color: detailsForest,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: detailsInk,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: detailsForest,
                      size: 19,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                // RENT AND DEPOSIT
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: detailsForest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Monthly rent',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              money(rent),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 27,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 48,
                        color: Colors.white30,
                      ),
                      const SizedBox(width: 17),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Security deposit',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              money(deposit),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 27),

                sectionTitle('Property overview'),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.55,
                  children: [
                    infoItem(
                      Icons.home_work_outlined,
                      'Property type',
                      propertyType,
                    ),
                    infoItem(
                      Icons.bed_outlined,
                      'Bedrooms',
                      bedrooms?.toString() ?? 'Not specified',
                    ),
                    infoItem(
                      Icons.bathtub_outlined,
                      'Bathrooms',
                      bathrooms?.toString() ?? 'Not specified',
                    ),
                    infoItem(
                      Icons.chair_outlined,
                      'Furnishing',
                      furnishing,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                sectionTitle('About this property'),

                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 28),

                sectionTitle('Property owner'),

                Container(
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7EEE7)),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 27,
                        backgroundColor: detailsMoss,
                        child: Icon(
                          Icons.person,
                          size: 29,
                          color: detailsForest,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ownerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: detailsInk,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Property Owner',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.verified_user_outlined,
                        color: detailsForest,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                sectionTitle('Contact owner'),

                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: ownerPhone.isEmpty ? null : callOwner,
                    icon: const Icon(Icons.call),
                    label: const Text('Call owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: detailsForest,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed:
                        ownerPhone.isEmpty ? null : whatsappOwner,
                    icon: const Icon(Icons.chat),
                    label: const Text('WhatsApp owner'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: detailsForest,
                      side: const BorderSide(color: detailsForest),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 11),

                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: emailOwner,
                    icon: const Icon(Icons.email_outlined),
                    label: const Text('Enquire by email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: detailsForest,
                      side: const BorderSide(color: detailsForest),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5E5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF9A641A),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Inspect the property and confirm all details with the owner before making any payment.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFF79551D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
