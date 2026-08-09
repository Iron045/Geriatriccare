import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/voice_reminder_providers.dart';

class VoiceRecorderPage extends ConsumerStatefulWidget {
  const VoiceRecorderPage({super.key});

  @override
  ConsumerState<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends ConsumerState<VoiceRecorderPage> {
  final recorder = AudioRecorder();
  final player = AudioPlayer();
  final titleController = TextEditingController(text: 'Lời nhắc yêu thương');
  final chunks = <Uint8List>[];
  StreamSubscription<Uint8List>? audioSubscription;
  Timer? timer;
  Duration duration = Duration.zero;
  Uint8List? recordedBytes;
  bool recording = false;
  bool uploading = false;
  bool playing = false;

  @override
  void initState() {
    super.initState();
    player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => playing = false);
    });
  }

  Future<void> startRecording() async {
    try {
      if (!await recorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần cấp quyền microphone.')),
          );
        }
        return;
      }
      chunks.clear();
      recordedBytes = null;
      duration = Duration.zero;
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );
      audioSubscription = stream.listen((data) => chunks.add(data));
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (duration.inSeconds >= 299) {
          stopRecording();
        } else {
          setState(() => duration += const Duration(seconds: 1));
        }
      });
      setState(() => recording = true);
    } catch (error) {
      if (mounted) _showError('Không thể bắt đầu ghi âm', error);
    }
  }

  Future<void> stopRecording() async {
    if (!recording) return;
    try {
      timer?.cancel();
      await recorder.stop();
      await audioSubscription?.cancel();
      final length = chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final bytes = Uint8List(length);
      var offset = 0;
      for (final chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      setState(() {
        recording = false;
        recordedBytes = bytes.isEmpty ? null : bytes;
      });
    } catch (error) {
      if (mounted) _showError('Không thể dừng ghi âm', error);
    }
  }

  Future<void> togglePlayback() async {
    final bytes = recordedBytes;
    if (bytes == null) return;
    if (playing) {
      await player.stop();
      setState(() => playing = false);
    } else {
      await player.play(BytesSource(bytes));
      setState(() => playing = true);
    }
  }

  Future<void> upload() async {
    final bytes = recordedBytes;
    final userId = ref.read(authRepositoryProvider).currentUserId;
    if (bytes == null || userId == null || duration.inSeconds == 0) return;
    setState(() => uploading = true);
    try {
      await ref
          .read(voiceReminderRepositoryProvider)
          .upload(
            ownerId: userId,
            title: titleController.text.trim().isEmpty
                ? 'Lời nhắc yêu thương'
                : titleController.text.trim(),
            audioBytes: bytes,
            durationSeconds: duration.inSeconds,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bản ghi âm lên Firebase.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) _showError('Không thể tải bản ghi lên Firebase', error);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _showError(String message, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$message: $error')));
  }

  @override
  void dispose() {
    timer?.cancel();
    audioSubscription?.cancel();
    recorder.dispose();
    player.dispose();
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      toolbarHeight: 82,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const Border(bottom: BorderSide(color: AppColors.border)),
      titleSpacing: 0,
      title: const AppBrand(compact: true),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(28),
        children: [
          Text(
            'Ghi âm lời nhắc',
            style: Theme.of(
              context,
            ).textTheme.headlineLarge?.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          const Text(
            'Ghi một lời nhắn bằng giọng nói dành cho người thân.',
            style: TextStyle(fontSize: 18, color: AppColors.textMuted),
          ),
          const SizedBox(height: 28),
          TextField(
            controller: titleController,
            enabled: !recording && !uploading,
            decoration: const InputDecoration(
              labelText: 'Tên lời nhắc',
              prefixIcon: Icon(Icons.title_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 42),
          Text(
            _formatDuration(duration),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: uploading
                  ? null
                  : recording
                  ? stopRecording
                  : startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: recording ? 150 : 132,
                height: recording ? 150 : 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: recording ? AppColors.danger : AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: (recording ? AppColors.danger : AppColors.primary)
                          .withValues(alpha: .24),
                      blurRadius: 24,
                      spreadRadius: recording ? 10 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  recording ? Icons.stop_rounded : Icons.mic_rounded,
                  size: 66,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            recording
                ? 'Chạm để dừng ghi âm'
                : recordedBytes == null
                ? 'Chạm để bắt đầu ghi âm'
                : 'Bản ghi đã sẵn sàng',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 19, color: AppColors.textMuted),
          ),
          if (recordedBytes != null && !recording) ...[
            const SizedBox(height: 36),
            OutlinedButton.icon(
              onPressed: uploading ? null : togglePlayback,
              icon: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(playing ? 'Dừng phát' : 'Nghe lại'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: uploading ? null : upload,
              icon: uploading
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload_rounded),
              label: Text(uploading ? 'Đang tải lên...' : 'Lưu bản ghi'),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: uploading
                  ? null
                  : () => setState(() {
                      recordedBytes = null;
                      duration = Duration.zero;
                    }),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Ghi lại'),
            ),
          ],
        ],
      ),
    ),
  );
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.toString().padLeft(2, '0');
  final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
