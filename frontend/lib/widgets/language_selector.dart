import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class LanguageSelector extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const LanguageSelector({
    Key? key,
    this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  String _selectedLanguage = 'en';
  Map<String, String> _languages = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _selectedLanguage = TranslationService.currentLanguage;
    _languages = TranslationService.getSupportedLanguages();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_languages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade700, // Green background
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.language,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedLanguage == 'en' ? 'EN' : 'አማ',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (String newLang) async {
          await TranslationService.setLanguage(newLang);

          setState(() {
            _selectedLanguage = newLang;
          });

          widget.onLanguageChanged?.call();
        },
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  Radio<String>(
                    value: 'en',
                    groupValue: _selectedLanguage,
                    onChanged: null,
                    activeColor: Colors.green,
                  ),
                  const Text('English'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'am',
              child: Row(
                children: [
                  Radio<String>(
                    value: 'am',
                    groupValue: _selectedLanguage,
                    onChanged: null,
                    activeColor: Colors.green,
                  ),
                  const Text('አማርኛ'),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }
}