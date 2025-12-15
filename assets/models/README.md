# AI Models

This directory is where you should place your TensorFlow Lite (`.tflite`) models.

## Required Model
**Filename**: `RealESRGAN.tflite`
**Source**: `Real-ESRGAN-x4plus_w8a8` (Quantized, ~16.7MB)
**Status**: Downloaded.

## Technical Details
This model is a quantized TFLite version of Real-ESRGAN x4plus, optimized for mobile (specifically Qualcomm devices, but generic enough for TFLite).
Input: RGB Image
Output: Enhanced RGB Image (x4 upscaling likely, code logic assumes standard RGB)

If you change the model, update `lib/data/services/ai_inference_service.dart`.
