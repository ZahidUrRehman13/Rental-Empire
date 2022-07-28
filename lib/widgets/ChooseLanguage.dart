
import 'package:flutter/material.dart';

import '../models/language_model_class.dart';
import '../screens/LanguagePage.dart';


class ChooseLanguage extends StatefulWidget {
  final Function(Language firstCode, Language secondCode) onLanguageChanged;

  const ChooseLanguage({Key? key, required this.onLanguageChanged}) : super(key: key);



  // @override
  // _ChooseLanguageState createState() => _ChooseLanguageState();
  @override
  _ChooseLanguageState createState() => _ChooseLanguageState();
}

class _ChooseLanguageState extends State<ChooseLanguage> {
  Language _firstLanguage = Language('en', 'English', true, true, true);
  Language _secondLanguage = Language('te', 'Telugu', true, true, true);




  // Switch the first and the second language
  void _switchLanguage() {
    Language tmpLanguage = _firstLanguage;

    setState(() {
      _firstLanguage = _secondLanguage;
      _secondLanguage = tmpLanguage;
    });

    widget.onLanguageChanged(_firstLanguage, _secondLanguage);
  }

  // Choose a new first language
  void _chooseFirstLanguage(String title, bool isAutomaticEnabled) async {
    final language = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePage(
          title: title,
          isAutomaticEnabled: isAutomaticEnabled,
        ),
      ),
    );

    if (language != null) {
      setState(() {
        _firstLanguage = language;
      });

      widget.onLanguageChanged(_firstLanguage, _secondLanguage);
    }
  }

  // Choose a new second language
  void _chooseSecondLanguage(String title, bool isAutomaticEnabled) async {
    final language = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguagePage(
          title: title,
          isAutomaticEnabled: isAutomaticEnabled,
        ),
      ),
    );

    if (language != null) {
      setState(() {
        _secondLanguage = language;
      });

     widget.onLanguageChanged(_firstLanguage, _secondLanguage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55.0,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            width: 0.5,
            color: Colors.grey,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  _chooseFirstLanguage("Translate from", true);
                },
                child: Center(
                  child: Text(
                    _firstLanguage.name!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.white,
            child: IconButton(
              icon: Icon(
                Icons.compare_arrows,
                color: Colors.grey[700],
              ),
              onPressed:_switchLanguage,
            ),
          ),
          Expanded(
            child: Material(
              color: Colors.white,
              child: InkWell(
                onTap: () {
                  _chooseSecondLanguage("Translate to", false);
                },
                child: Center(
                  child: Text(
                   _secondLanguage.name!,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 15.0,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}