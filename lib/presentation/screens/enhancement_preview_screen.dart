import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../data/services/ai_inference_service.dart';

class EnhancementPreviewScreen extends StatefulWidget {
  final String imagePath;
  const EnhancementPreviewScreen({super.key, required this.imagePath});

  @override
  State<EnhancementPreviewScreen> createState() => _EnhancementPreviewScreenState();
}

class _EnhancementPreviewScreenState extends State<EnhancementPreviewScreen> {
  bool _isProcessing = false;
  File? _enhancedImage;
  bool _showComparison = false; // Toggle for side-by-side view

  Future<void> _processImage() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      print('LOG: Starting enhancement process...');
      final service = AiInferenceService();
      
      final startTime = DateTime.now();
      print('LOG: Running inference on ${widget.imagePath} in background isolate...');
      
      // Run inference in background
      final enhancedImage = await service.enhanceImage(widget.imagePath);
      
      final duration = DateTime.now().difference(startTime);
      print('LOG: Inference completed in ${duration.inSeconds}s');

      if (mounted) {
        if (enhancedImage != null) {
           // Save to temp file to display
           final tempDir = await Directory.systemTemp.createTemp();
           final tempFile = File('${tempDir.path}/enhanced_result.png');
           await tempFile.writeAsBytes(img.encodePng(enhancedImage));
           
           setState(() {
             _enhancedImage = tempFile;
             _isProcessing = false;
             _showComparison = true; // Auto-enable comparison view
           });
           print('LOG: Enhanced image displayed.');
        } else {
           print('LOG: Enhanced image is null.');
           setState(() { _isProcessing = false; });
        }
      }
    } catch (e, stack) {
      print('LOG: Error during enhancement: $e');
      print(stack);
      if (mounted) {
        setState(() { _isProcessing = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Enhancement'),
        actions: [
          if (_enhancedImage != null)
            TextButton.icon(
              icon: Icon(_showComparison ? Icons.compare : Icons.image, color: Colors.white),
              label: Text(_showComparison ? 'Enhanced Only' : 'Compare', style: TextStyle(color: Colors.white)),
              onPressed: () {
                setState(() {
                  _showComparison = !_showComparison;
                });
              },
            ),
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
            child: _isProcessing
                ? const Center(child: CircularProgressIndicator())
                : _enhancedImage != null && _showComparison
                    ? _buildComparisonView()
                    : Center(
                        child: _enhancedImage != null
                            ? Image.file(_enhancedImage!)
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

  Widget _buildComparisonView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('BEFORE', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              Text('AFTER', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: Image.file(File(widget.imagePath), fit: BoxFit.contain)),
                  ],
                ),
              ),
              Container(width: 2, color: Colors.white),
              Expanded(
                child: Column(
                  children: [
                    Expanded(child: Image.file(_enhancedImage!, fit: BoxFit.contain)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.black87,
          child: Text(
            'Tip: Zoom in to see texture and detail improvements in the center region',
            style: TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
