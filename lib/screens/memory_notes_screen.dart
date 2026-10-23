import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../language/app_translations.dart';

class MemoryNotesScreen extends StatefulWidget {
  const MemoryNotesScreen({
    super.key,
  });

  @override
  State<MemoryNotesScreen> createState() =>
      _MemoryNotesScreenState();
}

class _MemoryNotesScreenState
    extends State<MemoryNotesScreen> {
  final TextEditingController _noteController =
  TextEditingController();

  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> _notes = [];

  String _selectedImagePath = '';

  bool _isLoading = true;

  bool _isSaving = false;

  String selectedLanguage = 'English';

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _loadLanguage();
    _loadNotes();
  }

  // ==========================================================
  // LOAD LANGUAGE
  // ==========================================================

  Future<void> _loadLanguage() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final String? savedLanguage =
      prefs.getString('selected_language');

      if (!mounted) return;

      setState(() {
        selectedLanguage =
            savedLanguage ?? 'English';
      });
    } catch (e) {
      print(
        'ERROR LOADING LANGUAGE: $e',
      );
    }
  }

  // ==========================================================
  // TRANSLATION
  // ==========================================================

  String t(String key) {
    return AppTranslations(
      selectedLanguage,
    ).text(key);
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ==========================================================
  // LOAD SAVED NOTES
  // ==========================================================

  Future<void> _loadNotes() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      final String? savedNotes =
      prefs.getString('memory_notes');

      if (savedNotes != null &&
          savedNotes.isNotEmpty) {
        try {
          final List<dynamic> decoded =
          jsonDecode(savedNotes);

          _notes = decoded
              .map(
                (item) =>
            Map<String, dynamic>.from(
              item,
            ),
          )
              .toList();
        } catch (e) {
          _notes = [];

          print(
            'ERROR DECODING MEMORY NOTES: $e',
          );
        }
      }
    } catch (e) {
      print(
        'ERROR LOADING MEMORY NOTES: $e',
      );
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ==========================================================
  // SAVE NOTES TO PHONE
  // ==========================================================

  Future<void> _saveNotesToPhone() async {
    try {
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();

      await prefs.setString(
        'memory_notes',
        jsonEncode(_notes),
      );
    } catch (e) {
      print(
        'ERROR SAVING MEMORY NOTES: $e',
      );

      if (mounted) {
        _showMessage(
          t('unableSave'),
        );
      }
    }
  }

  // ==========================================================
  // TAKE PHOTO WITH CAMERA
  // ==========================================================

  Future<void> _takePhoto() async {
    try {
      final XFile? image =
      await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImagePath =
            image.path;
      });
    } catch (e) {
      _showMessage(
        t('unableCamera'),
      );
    }
  }

  // ==========================================================
  // PICK PHOTO FROM GALLERY
  // ==========================================================

  Future<void> _pickPhoto() async {
    try {
      final XFile? image =
      await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImagePath =
            image.path;
      });
    } catch (e) {
      _showMessage(
        t('unableGallery'),
      );
    }
  }

  // ==========================================================
  // SHOW PHOTO OPTIONS
  // ==========================================================

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape:
      const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding:
            const EdgeInsets.all(20),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Text(
                  t('addPhoto'),
                  style:
                  const TextStyle(
                    fontSize: 21,
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                ListTile(
                  leading:
                  const CircleAvatar(
                    backgroundColor:
                    Color(0xFFE0F2F1),
                    child: Icon(
                      Icons
                          .camera_alt_rounded,
                      color:
                      Color(0xFF009688),
                    ),
                  ),

                  title: Text(
                    t('takePhoto'),
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _takePhoto();
                  },
                ),

                ListTile(
                  leading:
                  const CircleAvatar(
                    backgroundColor:
                    Color(0xFFE0F2F1),
                    child: Icon(
                      Icons
                          .photo_library_rounded,
                      color:
                      Color(0xFF009688),
                    ),
                  ),

                  title: Text(
                    t('chooseGallery'),
                  ),

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickPhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================================
  // SAVE NEW NOTE
  // ==========================================================

  Future<void> _saveNote() async {
    if (_isSaving) {
      return;
    }

    final String note =
    _noteController.text.trim();

    if (note.isEmpty &&
        _selectedImagePath.isEmpty) {
      _showMessage(
        t('pleaseWriteNoteOrPhoto'),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    final Map<String, dynamic> newNote = {
      'note': note,
      'imagePath': _selectedImagePath,
      'date': DateTime.now()
          .toIso8601String(),
    };

    setState(() {
      _notes.insert(
        0,
        newNote,
      );

      _noteController.clear();

      _selectedImagePath = '';
    });

    await _saveNotesToPhone();

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    _showMessage(
      t('memoryNoteSaved'),
    );
  }

  // ==========================================================
  // DELETE NOTE
  // ==========================================================

  Future<void> _deleteNote(
      int index) async {
    if (index < 0 ||
        index >= _notes.length) {
      return;
    }

    setState(() {
      _notes.removeAt(index);
    });

    await _saveNotesToPhone();

    _showMessage(
      t('memoryNoteDeleted'),
    );
  }

  // ==========================================================
  // MESSAGE
  // ==========================================================

  void _showMessage(
      String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
        SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================================
  // FORMAT DATE
  // ==========================================================

  String _formatDate(
      String dateString) {
    try {
      final DateTime date =
      DateTime.parse(dateString);

      final String day =
      date.day
          .toString()
          .padLeft(2, '0');

      final String month =
      date.month
          .toString()
          .padLeft(2, '0');

      final String year =
      date.year.toString();

      final int hour24 =
          date.hour;

      final String period =
      hour24 >= 12
          ? 'PM'
          : 'AM';

      int hour12 =
          hour24 % 12;

      if (hour12 == 0) {
        hour12 = 12;
      }

      final String minute =
      date.minute
          .toString()
          .padLeft(2, '0');

      return '$day/$month/$year • '
          '$hour12:$minute $period';
    } catch (e) {
      return '';
    }
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
      BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
      true,

      backgroundColor:
      const Color(0xFFF5FAF9),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
        const Color(0xFFF5FAF9),
        foregroundColor:
        const Color(0xFF00695C),

        title: Text(
          t('memoryNotes'),
          style:
          const TextStyle(
            fontWeight:
            FontWeight.bold,
            fontSize: 23,
          ),
        ),
      ),

      body: _isLoading
          ? const Center(
        child:
        CircularProgressIndicator(
          color:
          Color(0xFF009688),
        ),
      )
          : _buildNotesPage(),
    );
  }

  // ==========================================================
  // MAIN SCROLLABLE PAGE
  // ==========================================================

  Widget _buildNotesPage() {
    final double keyboardPadding =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    final int extraItems =
    _notes.isEmpty ? 1 : 0;

    return ListView.builder(
      keyboardDismissBehavior:
      ScrollViewKeyboardDismissBehavior
          .onDrag,

      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        keyboardPadding + 30,
      ),

      itemCount:
      2 +
          _notes.length +
          extraItems,

      itemBuilder:
          (context, index) {
        // ======================================================
        // ADD NOTE AREA
        // ======================================================

        if (index == 0) {
          return _buildAddNoteArea();
        }

        // ======================================================
        // SAVED MEMORIES TITLE
        // ======================================================

        if (index == 1) {
          return _buildSavedMemoriesTitle();
        }

        // ======================================================
        // EMPTY STATE
        // ======================================================

        if (_notes.isEmpty) {
          return _buildEmptyState();
        }

        // ======================================================
        // NOTE CARDS
        // ======================================================

        final int noteIndex =
            index - 2;

        return _buildNoteCard(
          _notes[noteIndex],
          noteIndex,
        );
      },
    );
  }

  // ==========================================================
  // ADD NOTE AREA
  // ==========================================================

  Widget _buildAddNoteArea() {
    return Container(
      width: double.infinity,

      padding:
      const EdgeInsets.all(16),

      margin:
      const EdgeInsets.only(
        bottom: 8,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          22,
        ),

        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            offset: Offset(0, 5),
            color:
            Color(0x16000000),
          ),
        ],
      ),

      child: Column(
        children: [
          TextField(
            controller:
            _noteController,

            maxLines: 5,

            minLines: 3,

            textInputAction:
            TextInputAction.newline,

            scrollPadding:
            const EdgeInsets.only(
              bottom: 150,
            ),

            decoration:
            InputDecoration(
              hintText:
              t('writeMemoryNote'),

              hintStyle:
              const TextStyle(
                color: Colors.grey,
              ),

              filled: true,

              fillColor:
              const Color(
                0xFFF5FAF9,
              ),

              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  16,
                ),

                borderSide:
                BorderSide.none,
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // SELECTED PHOTO
          // ====================================================

          if (_selectedImagePath
              .isNotEmpty)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                  BorderRadius.circular(
                    16,
                  ),

                  child: Image.file(
                    File(
                      _selectedImagePath,
                    ),

                    width:
                    double.infinity,

                    height: 180,

                    fit: BoxFit.cover,
                  ),
                ),

                Positioned(
                  top: 8,
                  right: 8,

                  child:
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImagePath =
                        '';
                      });
                    },

                    child: Container(
                      width: 36,
                      height: 36,

                      decoration:
                      const BoxDecoration(
                        color:
                        Colors.black54,
                        shape:
                        BoxShape.circle,
                      ),

                      child:
                      const Icon(
                        Icons.close,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          if (_selectedImagePath
              .isNotEmpty)
            const SizedBox(
              height: 12,
            ),

          // ====================================================
          // BUTTONS
          // ====================================================

          Row(
            children: [
              Expanded(
                child:
                OutlinedButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _showPhotoOptions,

                  icon:
                  const Icon(
                    Icons
                        .add_a_photo_rounded,
                  ),

                  label:
                  Text(
                    t('addPhoto'),
                  ),

                  style:
                  OutlinedButton
                      .styleFrom(
                    foregroundColor:
                    const Color(
                      0xFF00796B,
                    ),

                    side:
                    const BorderSide(
                      color:
                      Color(
                        0xFF009688,
                      ),
                    ),

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child:
                ElevatedButton.icon(
                  onPressed:
                  _isSaving
                      ? null
                      : _saveNote,

                  icon:
                  _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color:
                      Colors.white,
                    ),
                  )
                      : const Icon(
                    Icons
                        .save_rounded,
                  ),

                  label:
                  Text(
                    t('saveNote'),
                  ),

                  style:
                  ElevatedButton
                      .styleFrom(
                    backgroundColor:
                    const Color(
                      0xFF009688,
                    ),

                    foregroundColor:
                    Colors.white,

                    shape:
                    RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(
                        14,
                      ),
                    ),

                    padding:
                    const EdgeInsets
                        .symmetric(
                      vertical: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // SAVED MEMORIES TITLE
  // ==========================================================

  Widget _buildSavedMemoriesTitle() {
    return Padding(
      padding:
      const EdgeInsets.fromLTRB(
        4,
        8,
        4,
        8,
      ),

      child: Row(
        children: [
          const Icon(
            Icons
                .sticky_note_2_rounded,

            color:
            Color(0xFF00796B),
          ),

          const SizedBox(
            width: 8,
          ),

          Text(
            t('savedMemories'),

            style:
            const TextStyle(
              fontSize: 19,
              fontWeight:
              FontWeight.bold,
              color:
              Color(0xFF00695C),
            ),
          ),

          const Spacer(),

          Text(
            '${_notes.length}',

            style:
            const TextStyle(
              fontSize: 16,
              fontWeight:
              FontWeight.w600,
              color:
              Color(0xFF00796B),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // EMPTY STATE
  // ==========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Container(
              width: 90,
              height: 90,

              decoration:
              const BoxDecoration(
                color:
                Color(0xFFE0F2F1),
                shape:
                BoxShape.circle,
              ),

              child: const Icon(
                Icons
                    .sticky_note_2_rounded,
                size: 48,
                color:
                Color(0xFF009688),
              ),
            ),

            const SizedBox(
              height: 18,
            ),

            Text(
              t('noMemoryNotes'),

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                fontSize: 21,
                fontWeight:
                FontWeight.bold,
                color:
                Colors.black87,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              t('saveImportantMemories'),

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(
                fontSize: 15,
                color:
                Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // NOTE CARD
  // ==========================================================

  Widget _buildNoteCard(
      Map<String, dynamic> note,
      int index) {
    final String text =
        note['note'] ?? '';

    final String imagePath =
        note['imagePath'] ?? '';

    final String date =
        note['date'] ?? '';

    final bool hasImage =
        imagePath.isNotEmpty &&
            File(imagePath)
                .existsSync();

    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 14,
      ),

      decoration:
      BoxDecoration(
        color: Colors.white,

        borderRadius:
        BorderRadius.circular(
          20,
        ),

        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color:
            Color(0x14000000),
          ),
        ],
      ),

      child: Padding(
        padding:
        const EdgeInsets.all(14),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,

          children: [
            if (hasImage)
              ClipRRect(
                borderRadius:
                BorderRadius.circular(
                  15,
                ),

                child: Image.file(
                  File(imagePath),

                  width:
                  double.infinity,

                  height: 190,

                  fit: BoxFit.cover,
                ),
              ),

            if (hasImage)
              const SizedBox(
                height: 12,
              ),

            if (text.isNotEmpty)
              Text(
                text,

                style:
                const TextStyle(
                  fontSize: 17,
                  height: 1.45,
                  color:
                  Colors.black87,
                ),
              ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                const Icon(
                  Icons
                      .access_time_rounded,
                  size: 17,
                  color:
                  Color(0xFF00897B),
                ),

                const SizedBox(
                  width: 5,
                ),

                Expanded(
                  child: Text(
                    _formatDate(date),

                    style:
                    const TextStyle(
                      fontSize: 13,
                      color:
                      Colors.black54,
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {
                    _showDeleteConfirmation(
                      index,
                    );
                  },

                  icon:
                  const Icon(
                    Icons
                        .delete_outline_rounded,
                    color:
                    Colors.redAccent,
                  ),

                  tooltip:
                  t('delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  void _showDeleteConfirmation(
      int index) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text(
            '${t('deleteMemoryNote')}?',
          ),

          content: Text(
            t('memoryNoteRemoved'),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },

              child: Text(
                t('cancel').toUpperCase(),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );

                _deleteNote(index);
              },

              child: Text(
                t('delete').toUpperCase(),

                style:
                const TextStyle(
                  color:
                  Colors.redAccent,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}