import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final Color? color;
  final double size;
  final double strokeWidth;

  const LoadingIndicator({
    super.key,
    this.color,
    this.size = 24.0,
    this.strokeWidth = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).primaryColor,
          ),
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}
