import 'package:flutter/material.dart';

/// Wraps the application to enforce a realistic mobile smartphone viewport
/// when running on Web or Desktop, while displaying full-screen on mobile devices.
class MobileViewportWrapper extends StatelessWidget {
  final Widget child;

  const MobileViewportWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If already on a native mobile phone or small viewport, render full screen
        if (constraints.maxWidth <= 550) {
          return child;
        }

        // On Desktop / Web widescreen, render inside a sleek mobile phone frame
        return Container(
          color: const Color(0xFF0F172A), // Dark ambient studio background
          child: Center(
            child: Container(
              width: 420,
              height: constraints.maxHeight > 880 ? 860 : constraints.maxHeight - 20,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(38),
                border: Border.all(
                  color: const Color(0xFF334155),
                  width: 6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.45),
                    blurRadius: 35,
                    spreadRadius: 2,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Stack(
                  children: [
                    // The Mobile App
                    child,

                    // Top Mobile Speaker / Camera Notch Pill
                    Positioned(
                      top: 6,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 110,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E293B),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
