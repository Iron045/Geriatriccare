import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/sos_location_service.dart';
import '../../domain/entities/sos_alert.dart';
import '../providers/sos_providers.dart';

class ElderSosCountdownPage extends ConsumerStatefulWidget {
  const ElderSosCountdownPage({super.key, required this.elderId});

  final String elderId;

  @override
  ConsumerState<ElderSosCountdownPage> createState() =>
      _ElderSosCountdownPageState();
}

class _ElderSosCountdownPageState
    extends ConsumerState<ElderSosCountdownPage> {
  String? alertId;
  bool sending = false;
  bool closing = false;
  bool locating = false;
  bool sentWithoutLocation = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _sendAlert();
  }

  Future<void> _sendAlert() async {
    if (sending || alertId != null) return;
    setState(() {
      sending = true;
      locating = true;
      errorMessage = null;
    });
    try {
      final location = await SosLocationService.captureCurrentPosition();
      final position = location.position;
      if (mounted) {
        setState(() {
          locating = false;
          sentWithoutLocation = !location.hasLocation;
        });
      }
      final id = await ref
          .read(sosRepositoryProvider)
          .sendAlert(
            SosAlert(
              id: '',
              elderUserId: widget.elderId,
              triggerMethod: SosTriggerMethod.button,
              status: SosStatus.active,
              triggeredAt: DateTime.now(),
              latitude: position?.latitude,
              longitude: position?.longitude,
              locationAccuracy: position?.accuracy,
              locationCapturedAt: position?.timestamp,
            ),
          );
      if (mounted) setState(() => alertId = id);
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) {
        setState(() {
          sending = false;
          locating = false;
        });
      }
    }
  }

  Future<void> _closeAlert(SosAlert? alert) async {
    if (closing) return;
    final id = alertId;
    if (id == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => closing = true);
    try {
      if (alert?.status == SosStatus.acknowledged) {
        await ref.read(sosRepositoryProvider).resolveAlert(id);
      } else {
        await ref.read(sosRepositoryProvider).cancelAlert(id);
      }
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể cập nhật SOS: $error')),
        );
        setState(() => closing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentAlert = alertId == null
        ? null
        : ref.watch(sosAlertProvider(alertId!)).asData?.value;
    final acknowledged = currentAlert?.status == SosStatus.acknowledged;
    final sent = alertId != null;
    return PopScope(
      canPop: !sent || closing,
      child: Scaffold(
        backgroundColor: acknowledged ? AppColors.success : AppColors.danger,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                const SizedBox(height: 18),
                Icon(
                  acknowledged
                      ? Icons.verified_user_rounded
                      : Icons.warning_rounded,
                  color: Colors.white,
                  size: 82,
                ),
                Text(
                  acknowledged
                      ? 'ĐÃ CÓ NGƯỜI TIẾP NHẬN'
                      : sent
                      ? 'ĐÃ GỬI CẢNH BÁO'
                      : 'ĐANG GỬI...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  acknowledged
                      ? 'Người thân đã xác nhận và đang liên hệ với bạn.'
                      : sent
                      ? 'Cảnh báo đã được gửi đến tài khoản con cái đã liên kết.'
                      : locating
                      ? 'Đang xác định vị trí của bạn...'
                      : 'Đang chuẩn bị gửi cảnh báo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
                const Spacer(),
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .22),
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: Center(
                    child: sending
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 5,
                          )
                        : Icon(
                            acknowledged
                                ? Icons.phone_in_talk_rounded
                                : Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 100,
                          ),
                  ),
                ),
                const Spacer(),
                if (errorMessage != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Không thể gửi cảnh báo: $errorMessage',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: sending ? null : _sendAlert,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('GỬI LẠI'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (sent && sentWithoutLocation && !acknowledged) ...[
                  const Text(
                    'Cảnh báo đã gửi nhưng không kèm vị trí. Hãy bật GPS và cấp quyền vị trí cho lần sau.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: acknowledged
                        ? AppColors.success
                        : AppColors.danger,
                    minimumSize: const Size.fromHeight(68),
                  ),
                  onPressed: closing ? null : () => _closeAlert(currentAlert),
                  icon: closing
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          acknowledged
                              ? Icons.check_circle_rounded
                              : Icons.cancel_outlined,
                        ),
                  label: Text(
                    acknowledged ? 'KẾT THÚC CẢNH BÁO' : 'HỦY BÁO ĐỘNG',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  acknowledged
                      ? 'Chỉ kết thúc khi bạn đã an toàn.'
                      : 'Hủy nếu bạn bấm nhầm.',
                  style: const TextStyle(color: Colors.white70, fontSize: 17),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
