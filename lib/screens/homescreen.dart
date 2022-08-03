import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:translation_rental/MapDirectry/location_screen.dart';
import 'package:translation_rental/MapDirectry/rela_time_locations.dart';
import 'package:translation_rental/models/language_model_class.dart';
import 'package:translation_rental/widgets/ChooseLanguage.dart';
import 'package:translator/translator.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped }

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool _isTextTouched = false;
  Language _firstLanguage = Language('en', 'English', true, true, true);
  Language _secondLanguage = Language('te', 'Telugu', true, true, true);
  final FocusNode _textFocusNode = FocusNode();
  AnimationController? _controller;
  Animation? _animation;

  stt.SpeechToText? _speech;
  bool _isListening = false;

  final GoogleTranslator _translator = GoogleTranslator();
  String _textTranslated = "";

  final FlutterTts flutterTts = FlutterTts();

  bool blueText = true;
  late TextEditingController _textEditingController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    )..addListener(() {
        setState(() {});
      });
    _speech = stt.SpeechToText();
    _textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    _controller!.dispose();
    _textFocusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  _onLanguageChanged(Language firstCode, Language secondCode) {
    setState(() {
      _firstLanguage = firstCode;
      _secondLanguage = secondCode;
      _onTextChanged(_textEditingController.text);
    });
  }

  // Generate animations to enter the text to translate
  _onTextTouched(bool isTouched) {
    Tween tween = SizeTween(
      begin: const Size(0.0, kToolbarHeight),
      end: const Size(0.0, 0.0),
    );

    _animation = tween.animate(_controller!);

    if (isTouched) {
      FocusScope.of(context).requestFocus(_textFocusNode);
      _controller!.forward();
    } else {
      FocusScope.of(context).requestFocus(FocusNode());
      _controller!.reverse();
    }

    setState(() {
      _isTextTouched = isTouched;
    });
  }

  _onTextChanged(String text) {
    if (text != "") {
      _translator
          .translate(text,
              from: _firstLanguage.code!, to: _secondLanguage.code!)
          .then((translatedText) {
        setState(() {
          _textTranslated = translatedText.text;
          // print(_textTranslated);
        });
      });
    } else {
      setState(() {
        _textTranslated = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    Future _speak(String text) async {
      await flutterTts.setLanguage(_secondLanguage.code!);
      await flutterTts.setPitch(0.5);
      print(await flutterTts.getVoices);
      await flutterTts.speak(text);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
            _isTextTouched ? _animation!.value.height : kToolbarHeight),
        child: AppBar(
          title: Text(widget.title),
          elevation: 0.0,
          backgroundColor: const Color(0xFF072A6C),
          actions: [
            IconButton(
                onPressed: () {
                  showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (BuildContext context) => _rating());
                },
                icon: const Icon(Icons.star_rate)),
            IconButton(
                onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context)=> const RealTimeLocationScreen()));
                },
                icon: const Icon(Icons.pin_drop_outlined))
          ],
        ),
      ),
      body: Column(
        children: [
          ChooseLanguage(
            onLanguageChanged: _onLanguageChanged,
          ),
          Container(
            margin: const EdgeInsets.only(left: 16.0),
            height: height * 0.13,
            width: double.infinity,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      maxLines: 10,
                      onChanged: _onTextChanged,
                      decoration: const InputDecoration(
                        hintText: "Enter Text or Speak ",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_textEditingController.text == "") {
                            Fluttertoast.showToast(
                                msg: "The Spoken text is not available",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                          _speak(_textEditingController.text);
                        },
                        icon: const Icon(Icons.mic),
                      ),
                      IconButton(
                        onPressed: () {
                          if (_textEditingController.text == "") {
                            Fluttertoast.showToast(
                                msg: "there is no text available to remove",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                                backgroundColor: Colors.black,
                                textColor: Colors.white,
                                fontSize: 16.0);
                          }
                          setState(() {
                            _textEditingController.text = "";
                            _textTranslated = "";
                          });
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          const Divider(),
          Visibility(
            visible: _textEditingController.text != "",
            child: Container(
              margin: const EdgeInsets.only(left: 16.0),
              // height: _hight*0.1,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _textTranslated,
                        maxLines: 10,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_textTranslated == "") {
                          Fluttertoast.showToast(
                              msg: "The Spoken text is not available",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black,
                              textColor: Colors.white,
                              fontSize: 16.0);
                        }
                        _speak(_textTranslated);
                      },
                      icon: const Icon(Icons.mic),
                    )
                  ],
                ),
              ),
            ),
          ),
          Visibility(
              visible: _textEditingController.text != "",
              child: const Divider()),
          const Spacer(),
          Visibility(
            visible: Provider.of<InternetConnectionStatus>(context)==InternetConnectionStatus.disconnected,
            child:  Container(
                alignment: Alignment.bottomCenter,
                color: Colors.grey,
                padding:const EdgeInsets.all(16.0),
                child:  const Center(child: Text('Check your Internet Connection',style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0
                ),))),
          ),

        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: Theme.of(context).primaryColor,
        endRadius: 75.0,
        duration: const Duration(milliseconds: 2000),
        repeatPauseDuration: const Duration(milliseconds: 100),
        repeat: true,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF072A6C),
          onPressed: _listen,
          child: Icon(_isListening ? Icons.stop : Icons.mic),
        ),
      ),
    );
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech!.initialize(
        onStatus: (val) => setState(() {
          print('onStatus: $val');
        }),
        onError: (val) => print('onError: $val'),
        options: [SpeechToText.androidIntentLookup],
        debugLogging: true,
      );
      if (available) {
        setState(() => _isListening = true);
        _speech!.listen(
          onResult: (val) => setState(() {
            _textEditingController.text = val.recognizedWords;
            _onTextChanged(_textEditingController.text);

            print(_textEditingController.text);
          }),
        );
      }
    } else {
      setState(() {
        _isListening = false;
        blueText = false;
      });
      _speech!.stop();
    }
  }

  Widget _rating() {
    var height = MediaQuery.of(context).size.height;
    var width = MediaQuery.of(context).size.width;
    double? _ratingValue;
    return StatefulBuilder(builder:
        (BuildContext context, void Function(void Function()) setState) {
      return Container(
        margin: EdgeInsets.only(
          top: height * 0.05,
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 5.0,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
              child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.always,
            child: Container(
                height: height * 0.7,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(30)),
                  color: Colors.white,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.cancel_outlined,
                                size: 35,
                              ))
                        ],
                      ),
                      SizedBox(
                        height: height * 0.01,
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          top: height * 0.015,
                        ),
                        height: height * 0.065,
                        width: width * 0.9,
                        child: TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            // labelText: widget.labelText,
                            hintText: "Enter Name",
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          top: height * 0.015,
                        ),
                        height: height * 0.065,
                        width: width * 0.9,
                        child: TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            // labelText: widget.labelText,
                            hintText: "Enter Email",
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter email';
                            }
                            return null;

                          },
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(
                          top: height * 0.015,
                        ),
                        height: height * 0.065,
                        width: width * 0.9,
                        child: TextFormField(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            // labelText: widget.labelText,
                            hintText: "Message",
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  width: 2, color: Colors.black12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Please enter message';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(
                        height: height * 0.02,
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: width * 0.12),
                        child: Column(
                          children: [
                            const Text(
                              'Rate Us?',
                              style: TextStyle(fontSize: 24),
                            ),
                            SizedBox(height: height * 0.02),
                            // implement the rating bar
                            RatingBar(
                                initialRating: 2.5,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                ratingWidget: RatingWidget(
                                    full: const Icon(Icons.star,
                                        color: Colors.orange),
                                    half: const Icon(
                                      Icons.star_half,
                                      color: Colors.orange,
                                    ),
                                    empty: const Icon(
                                      Icons.star_outline,
                                      color: Colors.orange,
                                    )),
                                onRatingUpdate: (value) {
                                  setState(() {
                                    _ratingValue = value;
                                  });
                                }),
                            SizedBox(height: height * 0.01),
                            // Display the rate in number
                            Container(
                              width: width * 0.2,
                              height: height * 0.15,
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: Text(
                                _ratingValue != null
                                    ? _ratingValue.toString()
                                    : 'Rate it!',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15),
                              ),
                            )
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: width * 0.25),
                        child: MaterialButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Fluttertoast.showToast(
                                  msg: "Thanks to Rate Us!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  backgroundColor: Colors.black,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              Navigator.pop(context);

                            } else {
                              print('Validate form error');
                            }
                          },
                          textColor: Colors.white,
                          color: Colors.orange,
                          child: const Text('Submit'),
                        ),
                      )
                    ],
                  ),
                )),
          )),
        ),
      );
    });


  }

}
