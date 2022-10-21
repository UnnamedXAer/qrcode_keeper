import 'dart:math' as math;

import 'package:flutter/material.dart';

class QRCodeFavorite extends StatefulWidget {
  const QRCodeFavorite({
    required this.favorite,
    this.onTap,
    super.key,
  });
  final bool favorite;
  final VoidCallback? onTap;

  @override
  State<QRCodeFavorite> createState() => _QRCodeFavoriteState();
}

class _QRCodeFavoriteState extends State<QRCodeFavorite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: widget.favorite ? 1 : 0,
    );

    _scaleAnimation = Tween(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.bounceOut,
      ),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.favorite ? Colors.amber.shade400 : null;
    return GestureDetector(
      onTap: widget.onTap == null ? null : _onTap,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 8,
          ),
          child: Row(
            children: [
              Icon(
                Icons.star_border_outlined,
                color: color,
                size: 28,
              ),
              Icon(
                Icons.star_border_outlined,
                color: color,
                size: 28,
              ),
              Icon(
                Icons.star_border_outlined,
                color: color,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap() {
    if (_controller.value > 0) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    widget.onTap!();
  }
}

