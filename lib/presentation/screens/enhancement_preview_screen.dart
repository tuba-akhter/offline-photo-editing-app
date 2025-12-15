import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EnhancementPreviewScreen extends StatefulWidget {
  final String imagePath;
  const EnhancementPreviewScreen({super.key, required this.imagePath});

  @override
  State<EnhancementPreviewScreen> createState() => _EnhancementPreviewScreenState();
}

class _EnhancementPreviewScreenState extends State<EnhancementPreviewScreen> {
  bool _isProcessing = false;
  File? _enhancedImage;

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    // TODO: Call TFLite Service here
    await Future.delayed(const Duration(seconds: 3)); // Simulate processing

    // For now, just use original image as "enhanced" for demo
    if (mounted) {
      setState(() {
        _enhancedImage = File(widget.imagePath);
        _isProcessing = false;
      });
      // Show saved snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enhancement Complete!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          if (_enhancedImage != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: () => context.push('/result'),
            )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : _enhancedImage != null
                      ? Image.file(_enhancedImage!) // TODO: Implement Before/After Slider
                      : Image.file(File(widget.imagePath)),
            ),
          ),
          if (!_isProcessing && _enhancedImage == null)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _processImage,
                child: const Text('Enhance Now'),
              ),
            ),
        ],
      ),
    );
  }
}
