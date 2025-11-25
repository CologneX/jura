import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jura/pages/journal_page.dart';
import 'package:jura/pages/settings_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jura/services/transaction_service.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class BottomNavigationWrapper extends StatefulWidget {
  const BottomNavigationWrapper({super.key});

  @override
  State<BottomNavigationWrapper> createState() =>
      _BottomNavigationWrapperState();
}

class _BottomNavigationWrapperState extends State<BottomNavigationWrapper> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      body: <Widget>[
        const JournalPage(),
        const AIPage(),
        SettingsPage(),
      ][_selectedIndex],
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24, top: 8),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.card,
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: theme.colorScheme.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.list,
                label: 'Journal',
                index: 0,
                theme: theme,
              ),
              _buildCenterNavItem(context: context, theme: theme),
              _buildNavItem(
                context: context,
                icon: Icons.settings,
                label: 'Settings',
                index: 2,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int index,
    required ShadThemeData theme,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.small.copyWith(
                  fontSize: 12,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem({
    required BuildContext context,
    required ShadThemeData theme,
  }) {
    final isSelected = _selectedIndex == 1;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = 1;
        });
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.muted,
        ),
        child: Icon(
          Icons.chat_bubble_rounded,
          size: 28,
          color: isSelected
              ? theme.colorScheme.primaryForeground
              : theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> with TickerProviderStateMixin {
  late stt.SpeechToText _speechToText;
  String _transcript = '';
  bool _isListening = false;
  double _soundLevel = 0.0;
  bool _isProcessing = false;
  String _statusMessage = "";
  late AnimationController _rippleController;
  final TransactionService _transactionService = TransactionService();
  double _dragOffset = 0.0;
  final double _cancelThreshold = 100.0;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initializeSpeech();
  }

  void refreshMessage() {
    setState(() {
      _statusMessage = "";
    });
  }

  Future<void> _initializeSpeech() async {
    try {
      await _speechToText.initialize(
        onError: (error) {
          log('Error: $error');
          setState(() => _isListening = false);
        },
        onStatus: (status) {
          log('Status: $status');
        },
      );
    } catch (e) {
      log('Failed to initialize speech to text: $e');
    }
  }

  void _startListening() async {
    if (!_isListening && _speechToText.isAvailable) {
      // Haptic feedback when starting
      HapticFeedback.heavyImpact();

      setState(() => _isListening = true);
      setState(() {
        _statusMessage = "Listening...";
      });
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcript = result.recognizedWords;
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            _soundLevel = level;
          });
          // Trigger ripple animation on sound level change
          _rippleController.forward(from: 0.0);
        },
        localeId: 'en_US',
      );
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      // Haptic feedback when stopping
      HapticFeedback.mediumImpact();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
        _dragOffset = 0.0;
      });

      // Process the transcript if not empty
      if (_transcript.isNotEmpty) {
        _statusMessage = "Processing...";
        await _processTranscript();
      }
      refreshMessage();
    }
  }

  void _cancelListening() async {
    if (_isListening) {
      await _speechToText.cancel();
      // Strong haptic feedback when canceling
      HapticFeedback.heavyImpact();
      setState(() {
        _isListening = false;
        _soundLevel = 0.0;
        _dragOffset = 0.0;
        _transcript = '';
        _statusMessage = 'Listening canceled';
      });

      // Clear status message after 1 second
      await Future.delayed(const Duration(seconds: 1));
      refreshMessage();
    }
  }

  Future<void> _processTranscript() async {
    if (_transcript.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Parsing with AI...';
    });

    try {
      setState(() {
        _statusMessage = 'Jura AI is processing, please wait hehe...';
      });

      final transaction = await _transactionService.processTranscriptGemini(
        _transcript,
      );

      setState(() {
        _statusMessage = transaction;
        _transcript = '';
        _isProcessing = false;
      });

      // Clear status message after 2 seconds
      await Future.delayed(const Duration(seconds: 2));
      refreshMessage();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
        _isProcessing = false;
      });

      // Clear error message after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  void dispose() {
    _speechToText.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Transcript text at the top
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Transcript', style: theme.textTheme.muted),
                const SizedBox(height: 8),
                if (_transcript.isEmpty)
                  Text(
                    'Hold the mic button and start speaking...',
                    style: theme.textTheme.large.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  )
                else
                  Text(_transcript, style: theme.textTheme.large),
              ],
            ),
          ),
          // Horizontal Stack
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Status message and Clear button
                if (_statusMessage.isNotEmpty)
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: theme.textTheme.small.copyWith(
                        color: _statusMessage.contains('Error')
                            ? theme.colorScheme.destructive
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ),
                const Spacer(),
              ],
            ),
          ),
          // Spacer to push button to bottom
          Spacer(),
          // Mic button at the bottom
          // bottom padding by 120
          Padding(
            padding: EdgeInsets.only(bottom: 96),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onLongPressStart: !_isProcessing
                        ? (_) => _startListening()
                        : null,
                    onLongPressEnd: !_isProcessing
                        ? (_) {
                            if (_dragOffset >= _cancelThreshold) {
                              _cancelListening();
                            } else {
                              _stopListening();
                            }
                          }
                        : null,
                    onLongPressMoveUpdate: _isListening
                        ? (details) {
                            setState(() {
                              _dragOffset = details.offsetFromOrigin.dy.clamp(
                                0.0,
                                double.infinity,
                              );
                            });

                            // Haptic feedback when crossing threshold
                            if (_dragOffset >= _cancelThreshold &&
                                details.offsetFromOrigin.dy <
                                    _cancelThreshold + 5) {
                              HapticFeedback.heavyImpact();
                            }
                          }
                        : null,
                    child: Transform.translate(
                      offset: Offset(0, _dragOffset),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 12,
                        children: [
                          if (_isListening)
                            Text(
                              "Drag down to cancel",
                              style: theme.textTheme.small.copyWith(
                                color: _dragOffset >= _cancelThreshold
                                    ? theme.colorScheme.destructive
                                    : theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Sound ripple layers
                              if (_isListening)
                                AnimatedBuilder(
                                  animation: _rippleController,
                                  builder: (context, child) {
                                    final rippleOpacity =
                                        (1.0 - _rippleController.value).clamp(
                                          0.0,
                                          1.0,
                                        );
                                    final rippleScale =
                                        1.0 +
                                        (_rippleController.value * 0.5) +
                                        (_soundLevel / 100.0 * 0.3);
                                    return Opacity(
                                      opacity: rippleOpacity,
                                      child: Transform.scale(
                                        scale: rippleScale,
                                        child: Container(
                                          width: 96,
                                          height: 96,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.colorScheme.primary
                                                  .withOpacity(0.3),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _dragOffset >= _cancelThreshold
                                      ? theme.colorScheme.destructive
                                            .withOpacity(0.1)
                                      : theme.colorScheme.primary.withOpacity(
                                          0.1,
                                        ),
                                ),
                                padding: const EdgeInsets.all(24),
                                child: Icon(
                                  _isProcessing
                                      ? Icons.hourglass_bottom
                                      : (_isListening &&
                                                _dragOffset >= _cancelThreshold
                                            ? Icons.close
                                            : Icons.mic),
                                  size: 48,
                                  color: _isProcessing
                                      ? theme.colorScheme.input
                                      : (_isListening &&
                                                _dragOffset >= _cancelThreshold
                                            ? theme.colorScheme.destructive
                                            : _isListening
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.primary),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // child: ,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
