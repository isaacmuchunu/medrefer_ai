import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/app_export.dart';

class MapViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> specialists;
  final Function(Map<String, dynamic>) onSpecialistTap;

  const MapViewWidget({
    super.key,
    required this.specialists,
    required this.onSpecialistTap,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  Map<String, dynamic>? _selectedSpecialist;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(40.7128, -74.0060), // New York City
    zoom: 12.0,
  );

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  @override
  void didUpdateWidget(MapViewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.specialists != widget.specialists) {
      _createMarkers();
    }
  }

  void _createMarkers() {
    _markers.clear();

    for (int i = 0; i < widget.specialists.length; i++) {
      final specialist = widget.specialists[i];
      final lat = (specialist['latitude'] ?? 40.7128 + (i * 0.01)).toDouble();
      final lng = (specialist['longitude'] ?? -74.0060 + (i * 0.01)).toDouble();

      _markers.add(
        Marker(
          markerId: MarkerId(specialist['id'].toString()),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: specialist['name'] ?? 'Unknown',
            snippet: specialist['specialty'] ?? '',
            onTap: () => _showSpecialistPreview(specialist),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            specialist['isAvailable'] == true
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed,
          ),
          onTap: () => _showSpecialistPreview(specialist),
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _showSpecialistPreview(Map<String, dynamic> specialist) {
    setState(() {
      _selectedSpecialist = specialist;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSpecialistPreviewCard(specialist),
    );
  }

  Widget _buildSpecialistPreviewCard(Map<String, dynamic> specialist) {
    final bool isAvailable = specialist['isAvailable'] ?? false;
    final double rating = (specialist['rating'] ?? 0.0).toDouble();

    return Container(
      margin: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Container(
                  width: 15.w,
                  height: 15.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.lightTheme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CustomImageWidget(
                      imageUrl: specialist['profileImage'] ?? '',
                      width: 15.w,
                      height: 15.w,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              specialist['name'] ?? 'Unknown',
                              style: AppTheme.lightTheme.textTheme.titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: isAvailable
                                  ? AppTheme.successLight.withValues(alpha: 0.1)
                                  : AppTheme.errorLight.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAvailable ? 'Available' : 'Busy',
                              style: AppTheme.lightTheme.textTheme.labelSmall
                                  ?.copyWith(
                                color: isAvailable
                                    ? AppTheme.successLight
                                    : AppTheme.errorLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        specialist['specialty'] ?? '',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return CustomIconWidget(
                              iconName: index < rating.floor()
                                  ? 'star'
                                  : 'star_border',
                              color: index < rating.floor()
                                  ? AppTheme.accentLight
                                  : AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                              size: 16,
                            );
                          }),
                          SizedBox(width: 2.w),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'location_on',
                  color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    specialist['hospital'] ?? '',
                    style: AppTheme.lightTheme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  specialist['distance'] ?? '0.0 km',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle get directions
                    },
                    icon: CustomIconWidget(
                      iconName: 'directions',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 18,
                    ),
                    label: Text('Directions'),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSpecialistTap(specialist);
                    },
                    icon: CustomIconWidget(
                      iconName: 'contact_phone',
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text('Contact'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPosition,
          markers: _markers,
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          top: 2.h,
          right: 4.w,
          child: Column(
            children: [
              FloatingActionButton(
                mini: true,
                heroTag: "location",
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                onPressed: _goToCurrentLocation,
                child: CustomIconWidget(
                  iconName: 'my_location',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(height: 1.h),
              FloatingActionButton(
                mini: true,
                heroTag: "zoom_in",
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                onPressed: _zoomIn,
                child: CustomIconWidget(
                  iconName: 'zoom_in',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(height: 1.h),
              FloatingActionButton(
                mini: true,
                heroTag: "zoom_out",
                backgroundColor: AppTheme.lightTheme.colorScheme.surface,
                onPressed: _zoomOut,
                child: CustomIconWidget(
                  iconName: 'zoom_out',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 2.h,
          left: 4.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    color: AppTheme.successLight,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Available',
                  style: AppTheme.lightTheme.textTheme.labelSmall,
                ),
                SizedBox(width: 4.w),
                Container(
                  width: 3.w,
                  height: 3.w,
                  decoration: BoxDecoration(
                    color: AppTheme.errorLight,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Busy',
                  style: AppTheme.lightTheme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _goToCurrentLocation() {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(const LatLng(40.7128, -74.0060)),
    );
  }

  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
