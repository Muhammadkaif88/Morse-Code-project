import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

void main() {
  runApp(const MorseApp());
}

class MorseApp extends StatelessWidget {
  const MorseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Morse Transmitter",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MorseScreen(),
    );
  }
}

class MorseScreen extends StatefulWidget {
  const MorseScreen({super.key});

  @override
  State<MorseScreen> createState() => _MorseScreenState();
}

class _MorseScreenState extends State<MorseScreen> {
  TextEditingController controller = TextEditingController();

  int unit = 250;
  String status = "Idle";
  String morsePreview = "";

  Map<String, String> morseMap = {
    'A': '.-', 'B': '-...', 'C': '-.-.', 'D': '-..',
    'E': '.', 'F': '..-.', 'G': '--.', 'H': '....',
    'I': '..', 'J': '.---', 'K': '-.-', 'L': '.-..',
    'M': '--', 'N': '-.', 'O': '---', 'P': '.--.',
    'Q': '--.-', 'R': '.-.', 'S': '...', 'T': '-',
    'U': '..-', 'V': '...-', 'W': '.--', 'X': '-..-',
    'Y': '-.--', 'Z': '--..'
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      await Permission.camera.request();
    }
  }

  String convertToMorse(String text) {
    text = text.toUpperCase();
    String result = "";

    for (int i = 0; i < text.length; i++) {
      String char = text[i];

      if (char == ' ') {
        result += "   "; // Word gap
      } else if (morseMap.containsKey(char)) {
        result += "${morseMap[char] ?? ''} "; // Letter gap within word
      }
    }

    return result.trim();
  }

  Future<void> sendMorse(String text) async {
    // Re-check permissions before sending
    var permStatus = await Permission.camera.status;
    if (!permStatus.isGranted) {
      permStatus = await Permission.camera.request();
      if (!permStatus.isGranted) {
        setState(() {
          status = "Error: Camera permission denied";
        });
        return;
      }
    }

    setState(() {
      status = "Sending...";
    });

    text = text.toUpperCase();

    try {
      for (int i = 0; i < text.length; i++) {
        String char = text[i];

        if (char == ' ') {
          await Future.delayed(Duration(milliseconds: unit * 6));
          continue;
        }

        String morse = morseMap[char] ?? '';

        for (int j = 0; j < morse.length; j++) {
          String symbol = morse[j];

          await TorchLight.enableTorch();

          if (symbol == '.') {
            await Future.delayed(Duration(milliseconds: unit));
          } else {
            await Future.delayed(Duration(milliseconds: unit * 3));
          }

          await TorchLight.disableTorch();
          await Future.delayed(Duration(milliseconds: unit));
        }

        await Future.delayed(Duration(milliseconds: unit * 2));
      }

      setState(() {
        status = "Done ✅";
      });
    } catch (e) {
      setState(() {
        status = "Error: $e";
      });
      debugPrint('Torch error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Morse Transmitter"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: "Enter Message",
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                      setState(() {
                        morsePreview = convertToMorse(value);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      morsePreview.isEmpty ? "Morse Preview" : morsePreview,
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      sendMorse(controller.text);
                    }
                  },
                  child: const Text(
                    "SEND FLASH SIGNAL",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    status == "Sending..." ? Icons.flash_on : Icons.info_outline,
                    color: status == "Sending..." ? Colors.orange : Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Status: $status",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: status == "Sending..." ? Colors.orange : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
