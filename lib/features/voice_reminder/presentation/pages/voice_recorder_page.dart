import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_brand.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../medication/data/services/medication_notification_service.dart';
import '../../data/services/local_notification_sound_service.dart';
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
  bool useAsNotificationSound = true;
  int recordingSampleRate = 44100;

  bool get supportsLocalRecordedSound =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

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
      recordingSampleRate = 44100;
      await recorder.setOnConfigChanged((config) {
        recordingSampleRate = config.sampleRate;
      });
      final stream = await recorder.startStream(
        const RecordConfig(
          // Streaming WAV is not supported consistently on Android or web.
          // PCM is wrapped in a WAV header after the recording stops.
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 44100,
          numChannels: 1,
        ),
      );
      audioSubscription = stream.listen((data) => chunks.add(data));
      timer?.cancel();
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        if (duration.inSeconds >= 29) {
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
      final rawBytes = Uint8List(length);
      var offset = 0;
      for (final chunk in chunks) {
        rawBytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      final bytes = _pcm16ToWav(
        rawBytes,
        sampleRate: recordingSampleRate,
      );
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
    var localSoundSaved = false;
    Object? localSoundError;
    try {
      // The local reminder must not depend on Firebase Storage availability.
      if (useAsNotificationSound && supportsLocalRecordedSound) {
        try {
          await LocalNotificationSoundService.instance.saveAndSelect(
            audioBytes: bytes,
            title: titleController.text.trim().isEmpty
                ? 'Lời nhắc uống thuốc'
                : titleController.text.trim(),
          );
          await MedicationNotificationService.instance
              .rescheduleWithSelectedSound();
          localSoundSaved = true;
        } catch (error) {
          localSoundError = error;
        }
      }
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
      final successMessage = localSoundSaved
          ? 'Đã lưu Firebase và đặt bản ghi làm âm báo nhắc thuốc.'
          : localSoundError != null
          ? 'Đã lưu lên Firebase nhưng chưa đặt được âm báo: $localSoundError'
          : 'Đã lưu bản ghi âm lên Firebase.';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        _showError(
          localSoundSaved
              ? 'Đã đặt âm báo trên thiết bị nhưng không thể tải lên Firebase'
              : 'Không thể lưu bản ghi',
          error,
        );
      }
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: supportsLocalRecordedSound && useAsNotificationSound,
              onChanged: uploading || !supportsLocalRecordedSound
                  ? null
                  : (value) => setState(() => useAsNotificationSound = value),
              title: const Text('Dùng làm âm báo nhắc thuốc'),
              subtitle: Text(
                supportsLocalRecordedSound
                    ? 'Lưu trên thiết bị và áp dụng cho các lịch nhắc sắp tới.'
                    : 'Tính năng này hiện được hỗ trợ trên điện thoại Android.',
              ),
              secondary: const Icon(Icons.notifications_active_rounded),
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

Uint8List _pcm16ToWav(
  Uint8List pcmBytes, {
  required int sampleRate,
  int channels = 1,
}) {
  const bitsPerSample = 16;
  final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  final blockAlign = channels * bitsPerSample ~/ 8;
  final result = Uint8List(44 + pcmBytes.length);
  final data = ByteData.sublistView(result);

  void writeText(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      result[offset + index] = value.codeUnitAt(index);
    }
  }

  writeText(0, 'RIFF');
  data.setUint32(4, 36 + pcmBytes.length, Endian.little);
  writeText(8, 'WAVE');
  writeText(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, channels, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, byteRate, Endian.little);
  data.setUint16(32, blockAlign, Endian.little);
  data.setUint16(34, bitsPerSample, Endian.little);
  writeText(36, 'data');
  data.setUint32(40, pcmBytes.length, Endian.little);
  result.setRange(44, result.length, pcmBytes);
  return result;
}
