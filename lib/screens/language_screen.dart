import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() =>
      _LanguageScreenState();
}

class _LanguageScreenState
    extends State<LanguageScreen> {

  String selectedLanguage = "English";

  final List<Map<String, String>> languages = [
    {
      "name": "English",
      "symbol": "🇬🇧",
    },
    {
      "name": "తెలుగు",
      "symbol": "🇮🇳",
    },
    {
      "name": "हिंदी",
      "symbol": "🇮🇳",
    },
  ];

  // ==========================================================
  // LOAD SAVED LANGUAGE
  // ==========================================================

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    final String? savedLanguage =
    prefs.getString('selected_language');

    if (savedLanguage != null &&
        savedLanguage.isNotEmpty &&
        mounted) {
      setState(() {
        selectedLanguage = savedLanguage;
      });
    }
  }

  // ==========================================================
  // SAVE LANGUAGE
  // ==========================================================

  Future<void> _saveLanguage() async {
    final SharedPreferences prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(
      'selected_language',
      selectedLanguage,
    );
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,

        decoration:
        const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xffE0F7FA),
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [
              // ==================================================
              // LANGUAGE ICON
              // ==================================================

              Container(
                height: 100,
                width: 100,

                decoration:
                BoxDecoration(
                  color: Colors.teal,

                  borderRadius:
                  BorderRadius.circular(
                    35,
                  ),
                ),

                child: const Icon(
                  Icons.language,
                  color: Colors.white,
                  size: 55,
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              // ==================================================
              // TITLE
              // ==================================================

              const Text(
                "Choose Language",

                style: TextStyle(
                  fontSize: 30,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              const Text(
                "Select your preferred language",

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(
                height: 40,
              ),

              // ==================================================
              // LANGUAGE OPTIONS
              // ==================================================

              ...languages.map(
                    (language) {
                  final bool selected =
                      selectedLanguage ==
                          language["name"];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedLanguage =
                        language["name"]!;
                      });
                    },

                    child: Container(
                      margin:
                      const EdgeInsets
                          .symmetric(
                        horizontal: 40,
                        vertical: 8,
                      ),

                      padding:
                      const EdgeInsets
                          .all(18),

                      decoration:
                      BoxDecoration(
                        color: selected
                            ? Colors.teal
                            : Colors.white,

                        borderRadius:
                        BorderRadius
                            .circular(
                          22,
                        ),

                        boxShadow:
                        const [
                          BoxShadow(
                            blurRadius: 12,
                            color:
                            Colors.black12,
                          ),
                        ],
                      ),

                      child: Row(
                        children: [
                          Text(
                            language["symbol"]!,

                            style:
                            const TextStyle(
                              fontSize: 28,
                            ),
                          ),

                          const SizedBox(
                            width: 20,
                          ),

                          Text(
                            language["name"]!,

                            style:
                            TextStyle(
                              fontSize: 20,

                              fontWeight:
                              FontWeight
                                  .w600,

                              color: selected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),

                          const Spacer(),

                          if (selected)
                            const Icon(
                              Icons
                                  .check_circle,
                              color:
                              Colors.white,
                              size: 25,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 35,
              ),

              // ==================================================
              // CONTINUE BUTTON
              // ==================================================

              SizedBox(
                width: 260,
                height: 55,

                child:
                ElevatedButton(
                  style:
                  ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.teal,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),

                  onPressed: () async {
                    // Save selected language.
                    await _saveLanguage();

                    if (!mounted) {
                      return;
                    }

                    // Open Home Screen.
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) =>
                        const HomeScreen(),
                      ),
                    );
                  },

                  child: const Text(
                    "Continue",

                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}