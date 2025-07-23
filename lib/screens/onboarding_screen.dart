import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}



class _OnboardingScreenState extends State<OnboardingScreen> {
  bool showVideo = false;
  bool hideAllAnimations = false;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  
@override
void initState() {
  super.initState();
  
  // Initialize video
  _videoController = VideoPlayerController.networkUrl(
  Uri.parse('https://sample-videos.com/video321/mp4/720/big_buck_bunny_720p_5mb.mp4')
)
    ..initialize().then((_) {
      setState(() {
        _isVideoInitialized = true;
      });
      _videoController!.setLooping(true);
    });
  
  // Start video transition after 3 seconds
  Future.delayed(Duration(seconds: 3), () {
    setState(() {
      showVideo = true;
    });
    // Start playing video when transition begins
    if (_isVideoInitialized) {
      _videoController!.play();
    }
  });
  
  // Hide all animations after tire zoom completes
  Future.delayed(Duration(seconds: 5), () {
    setState(() {
      hideAllAnimations = true;
    });
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Rotating tire in center (only show until animations complete)
            if (!hideAllAnimations)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(24, 0, 0, 0),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(Icons.donut_large, size: 80, color: Colors.black),
                )
                  .animate(onPlay: (controller) => controller.repeat())
                  .rotate(duration: 2000.ms, curve: Curves.linear)
                  .scale(
                    begin: Offset(1.0, 1.0),
                    end: Offset(showVideo ? 15.0 : 1.0, showVideo ? 15.0 : 1.0),
                    duration: showVideo ? 2000.ms : 0.ms,
                    curve: Curves.easeInOut,
                  ),
              ),
            
            // Futuristic App name with Exo 2 (only show when video not started)
            if (!showVideo)
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Text(
                  'adboTransit',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.exo2(
                    fontSize: 36,
                    fontWeight: FontWeight.w900, // Extra bold
                    color: Colors.black,
                    letterSpacing: 2.0,
                  ),
                )
                  .animate()
                  .fadeIn(duration: 1500.ms, delay: 800.ms)
                  .slideY(begin: -0.3, duration: 1200.ms, delay: 800.ms, curve: Curves.easeOutCubic)
                  .then(delay: 1000.ms)
                  .fadeOut(duration: 800.ms)
                  .slideY(begin: 0, end: -0.2, duration: 800.ms),
              ),
              
            // Video container (appears during transition and stays)
            // Video container (appears during transition and stays)
if (showVideo && _isVideoInitialized)
  SizedBox.expand(
    child: VideoPlayer(_videoController!),
  )
    .animate()
    .fadeIn(duration: 1500.ms, delay: 500.ms)
    .scale(
      begin: Offset(0.0, 0.0), 
      duration: 1500.ms, 
      curve: Curves.easeInOutCubic
    ),

    // Video container with fallback
if (showVideo)
  Container(
    width: double.infinity,
    height: double.infinity,
    color: Colors.grey[800],
    child: _isVideoInitialized 
        ? VideoPlayer(_videoController!)
        : Center(
            child: Text(
              'Loading Video...',
              style: GoogleFonts.exo2(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              
            ),
          ),
  )
    .animate()
    .fadeIn(duration: 1500.ms, delay: 500.ms)
    .scale(begin: Offset(0.0, 0.0), duration: 1500.ms, curve: Curves.easeInOutCubic),

          ],
        ),
      ),
    );
  }
  @override
void dispose() {
  _videoController?.dispose();
  super.dispose();
}
}
