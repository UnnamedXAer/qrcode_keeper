import 'package:flutter/material.dart';

class QRCodeFavorite extends StatefulWidget {
  const QRCodeFavorite({
    required this.favorite,
    this.onTap,
    this.size = 28.0,
    this.starsCnt = 3,
    super.key,
  });
  final bool favorite;
  final VoidCallback? onTap;
  final int starsCnt;
  final double size;

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
    final color = widget.favorite
        ? Colors.amber.shade400
        : const Color.fromRGBO(136, 136, 136, 1);
    return GestureDetector(
      onTap: widget.onTap == null ? null : _onTap,
      child: Center(
        child: Container(
          width: widget.starsCnt * widget.size + 2 * 16,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.starsCnt; i++)
                  Icon(
                    Icons.star_border_outlined,
                    color: color,
                    size: widget.size,
                  ),
              ],
            ),
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
