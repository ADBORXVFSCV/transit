import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  final List<String> contentUrls;

  const LoadingScreen({super.key, required this.contentUrls});

  @override
  // ignore: library_private_types_in_public_api
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with dark overlay
          Container(
            decoration: BoxDecoration(
              image: widget.contentUrls.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(widget.contentUrls[0]),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        const Color.fromARGB(123, 0, 0, 0), // Subtle overlay for readability
                        BlendMode.darken,
                      ),
                    )
                  : null,
              color: const Color(0xFF0A0E21), // Fallback background (matches main.dart theme)
            ),
            child: Center(
              child: widget.contentUrls.isEmpty
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                    )
                  : Image.network(
                      widget.contentUrls[0],
                      fit: BoxFit.contain,
                      height: 300, // Preview size for center image
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}