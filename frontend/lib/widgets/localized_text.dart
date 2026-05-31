import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class LocalizedText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final List<String>? args;
  
  const LocalizedText(
    this.textKey, {
    Key? key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.args,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    String text = TranslationService.translate(textKey);
    
    // Replace placeholders if args provided
    if (args != null) {
      for (int i = 0; i < args!.length; i++) {
        text = text.replaceAll('{$i}', args![i]);
      }
    }
    
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
