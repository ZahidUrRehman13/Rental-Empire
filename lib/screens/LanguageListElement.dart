
import 'package:flutter/material.dart';

import '../models/language_model_class.dart';


class LanguageListElement extends StatefulWidget {
  Language language;
  Function(Language) onSelect;

  LanguageListElement({Key? key, required this.language, required this.onSelect})
      : super(key: key);



  @override
  _LanguageListElementState createState() => _LanguageListElementState();
}

class _LanguageListElementState extends State<LanguageListElement> {

  Widget? _displayTrailingIcon() {
    if(widget.language.isDownloadable!) {
      if(widget.language.isDownloaded!) {
        return Icon(Icons.check_circle);
      } else {
        return Icon(Icons.file_download);
      }
    } else {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(this.widget.language.name!),
      trailing: this._displayTrailingIcon(),
      onTap: () {
        this.widget.onSelect(this.widget.language);
      },
    );
  }
}