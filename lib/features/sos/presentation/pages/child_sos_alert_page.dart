import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/sos_alert.dart';
import '../providers/sos_providers.dart';

class ChildSosAlertPage extends ConsumerStatefulWidget {
  const ChildSosAlertPage({
    super.key,
    required this.alert,
    required this.childId,
    required this.elderDisplayName,
    this.elderPhone,
  });

  final SosAlert alert;
  final String childId;
  final String elderDisplayName;
  final String? elderPhone;

  @override
  ConsumerState<ChildSosAlertPage> createState() =>
      _ChildSosAlertPageState();
}

class _ChildSosAlertPageState extends ConsumerState<ChildSosAlertPage> {
  bool _acknowledging = false;
  bool _closingScheduled = false;

  Future<void> _acknowledge() async {
    if (_acknowledging) return;
    setState(() => _acknowledging = true);
    try {
      await ref
          .read(sosRepositoryProvider)
          .acknowledgeAlert(
            alertId: widget.alert.id,
            childId: widget.childId,
          );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể tiếp nhận cảnh báo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  Future<void> _copyPhone() async {
    final phone = widget.elderPhone?.trim();
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Người thân chưa có số điện thoại.')),
      );
      return;
    }
    await Clipboard.setData(ClipboardData(text: phone));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã sao chép số điện thoại $phone.')),
      );
    }
  }

  Future<void> _openLocation(SosAlert alert) async {
    final latitude = alert.latitude;
    final longitude = alert.longitude;
    if (latitude == null || longitude == null) return;
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': '$latitude,$longitude',
    });
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    await Clipboard.setData(ClipboardData(text: uri.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã sao chép liên kết vị trí.')),
      );
    }
  }

  void _closeWhenElderEnds(SosStatus status) {
    if (_closingScheduled ||
        (status != SosStatus.cancelled && status != SosStatus.resolved)) {
      return;
    }
    _closingScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cảnh báo SOS đã được kết thúc.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveAlert =
        ref.watch(sosAlertProvider(widget.alert.id)).asData?.value ??
        widget.alert;
    _closeWhenElderEnds(liveAlert.status);
    final acknowledged = liveAlert.status == SosStatus.acknowledged;
    final color = acknowledged ? AppColors.success : AppColors.danger;

    return PopScope(
      canPop: acknowledged,
      child: Scaffold(
        backgroundColor: color,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  acknowledged
                      ? Icons.verified_user_rounded
                      : Icons.emergency_rounded,
                  size: 92,
                  color: Colors.white,
                ),
                const SizedBox(height: 18),
                Text(
                  acknowledged ? 'ĐÃ TIẾP NHẬN SOS' : 'CẢNH BÁO SOS',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  acknowledged
                      ? 'Bạn đã thông báo cho người thân rằng cảnh báo đã được tiếp nhận.'
                      : '${widget.elderDisplayName} đang cần được hỗ trợ khẩn cấp!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: const Icon(
                    Icons.notifications_active_rounded,
                    size: 130,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (liveAlert.latitude != null &&
                    liveAlert.longitude != null) ...[
                  FilledButton.icon(
                    onPressed: () => _openLocation(liveAlert),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(66),
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: Colors.black87,
                    ),
                    icon: const Icon(Icons.location_on_rounded),
                    label: const Text('XEM VỊ TRÍ TRÊN BẢN ĐỒ'),
                  ),
                  const SizedBox(height: 14),
                ],
                FilledButton.icon(
                  onPressed: _copyPhone,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(66),
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                  ),
                  icon: const Icon(Icons.phone_rounded),
                  label: Text(
                    widget.elderPhone?.trim().isNotEmpty == true
                        ? 'LIÊN HỆ ${widget.elderPhone}'
                        : 'LIÊN HỆ NGƯỜI THÂN',
                  ),
                ),
                const SizedBox(height: 14),
                if (!acknowledged)
                  OutlinedButton.icon(
                    onPressed: _acknowledging ? null : _acknowledge,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(66),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 3),
                    ),
                    icon: _acknowledging
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.done_all_rounded),
                    label: const Text('ĐÃ TIẾP NHẬN'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(66),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 3),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('ĐÓNG'),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'Hãy liên hệ ngay và chỉ đóng màn hình sau khi đã tiếp nhận.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
