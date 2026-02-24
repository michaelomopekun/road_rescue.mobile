import 'package:flutter/material.dart';

class WorkshopAddressCard extends StatelessWidget {
  // final String workshopAddress;
  // final double latitude;
  // final double longitude;
  final VoidCallback onEditPressed;

  const WorkshopAddressCard({
    super.key,
    // required this.workshopAddress,
    // required this.latitude,
    // required this.longitude,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'WORKSHOP ADDRESS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[500],
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            TextButton(
              onPressed: onEditPressed,
              child: Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.teal[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Map Preview
        Container(
          height: 200,
          // decoration: BoxDecoration(
          //   borderRadius: BorderRadius.circular(12),
          //   border: Border.all(color: Colors.grey[200]!),
          //   image: DecorationImage(
          //     image: NetworkImage(
          //       'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=15&size=400x200&key=YOUR_GOOGLE_API_KEY&markers=color:red%7C$latitude,$longitude',
          //     ),
          //     fit: BoxFit.cover,
          //     onError: (exception, stackTrace) {
          //       // Fallback if image fails to load
          //     },
          //   ),
          // ),
          child: Stack(
            children: [
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Address Info Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   workshopAddress,
              //   style: Theme.of(
              //     context,
              //   ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              //   maxLines: 2,
              //   overflow: TextOverflow.ellipsis,
              // ),
              const SizedBox(height: 4),
              Text(
                'Workshop Location',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
