// lib/core/widgets/flip_card_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';

// A controller to programmatically trigger the flip action from the parent widget.
class FlipCardController {
  _FlipCardWidgetState? _state;

  void _attach(_FlipCardWidgetState state) {
    _state = state;
  }

  void flip() {
    _state?.flip();
  }

  void reset() {
    _state?.reset();
  }
}

class FlipCardWidget extends StatefulWidget {
  final Widget front;
  final Widget back;
  final FlipCardController controller;

  const FlipCardWidget({
    super.key,
    required this.front,
    required this.back,
    required this.controller,
  });

  @override
  State<FlipCardWidget> createState() => _FlipCardWidgetState();
}

class _FlipCardWidgetState extends State<FlipCardWidget> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isFrontVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void flip() {
    if (_animationController.isAnimating) return;
    if (_isFrontVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
    _isFrontVisible = !_isFrontVisible;
  }

  void reset() {
    // Reset the card to the front without an animation
    if (!_isFrontVisible) {
      _animationController.value = 0; // Directly set animation value to start
      _isFrontVisible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final angle = _animation.value * pi;
    final transform = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // This adds the 3D perspective effect
      ..rotateY(angle);

    return Transform(
      transform: transform,
      alignment: Alignment.center,
      // If the card is past 90 degrees, show the back side.
      // We also need to apply a transform to the back to "un-mirror" it.
      child: _isAnglePastHalfway(angle)
          ? Transform(
              transform: Matrix4.identity()..rotateY(pi), // Pre-flip the back
              alignment: Alignment.center,
              child: _buildCard(widget.back),
            )
          : _buildCard(widget.front),
    );
  }

  bool _isAnglePastHalfway(double angle) {
    // The angle is in radians, pi is 180 degrees.
    // We check if it's past 90 degrees (pi / 2).
    return angle >= (pi / 2);
  }

  // Helper to build the card's visual structure
  Widget _buildCard(Widget child) {
    return Card(
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: SingleChildScrollView(
            child: child,
          ),
        ),
      ),
    );
  }
}