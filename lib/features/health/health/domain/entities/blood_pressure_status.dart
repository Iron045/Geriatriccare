enum BloodPressureStatusCode { low, optimal, normal, rising, high, crisis }

class BloodPressureStatus {
  const BloodPressureStatus({
    required this.code,
    required this.title,
    required this.message,
    required this.ctaLabel,
    required this.level,
  });

  final BloodPressureStatusCode code;
  final String title;
  final String message;
  final String ctaLabel;
  final int level;

  bool get needsAttention => level >= 2 || code == BloodPressureStatusCode.low;
  bool get isUrgent => code == BloodPressureStatusCode.crisis;
}

BloodPressureStatus classifyBloodPressure(int systolic, int diastolic) {
  // A crisis has priority over every other category to avoid hiding a
  // dangerous reading when the other number happens to be low.
  if (systolic > 180 || diastolic > 120) {
    return const BloodPressureStatus(
      code: BloodPressureStatusCode.crisis,
      title: 'Huyết áp rất cao',
      message:
          'Hãy ngồi nghỉ và đo lại ngay. Nếu có đau ngực, khó thở, yếu liệt, thay đổi thị lực hoặc khó nói, gọi cấp cứu 115.',
      ctaLabel: 'Xem hướng dẫn khẩn cấp',
      level: 4,
    );
  }
  if (systolic < 90 || diastolic < 60) {
    return const BloodPressureStatus(
      code: BloodPressureStatusCode.low,
      title: 'Huyết áp đang thấp',
      message:
          'Hãy ngồi hoặc nằm nghỉ, đứng dậy từ từ và đo lại. Liên hệ nhân viên y tế nếu chóng mặt hoặc ngất.',
      ctaLabel: 'Đo lại',
      level: 2,
    );
  }
  if (systolic >= 140 || diastolic >= 90) {
    return const BloodPressureStatus(
      code: BloodPressureStatusCode.high,
      title: 'Huyết áp đang cao',
      message:
          'Hãy nghỉ yên ít nhất 5 phút rồi đo lại và liên hệ bác sĩ nếu chỉ số vẫn cao.',
      ctaLabel: 'Đo lại sau 5 phút',
      level: 3,
    );
  }
  if (systolic >= 130 || diastolic >= 85) {
    return const BloodPressureStatus(
      code: BloodPressureStatusCode.rising,
      title: 'Huyết áp có xu hướng tăng',
      message: 'Hãy nghỉ ngơi, đo lại và tiếp tục theo dõi thường xuyên.',
      ctaLabel: 'Đo lại',
      level: 2,
    );
  }
  if (systolic >= 120 || diastolic >= 80) {
    return const BloodPressureStatus(
      code: BloodPressureStatusCode.normal,
      title: 'Chỉ số cần tiếp tục theo dõi',
      message: 'Chỉ số chưa đáng báo động. Hãy duy trì theo dõi định kỳ.',
      ctaLabel: 'Xem xu hướng',
      level: 1,
    );
  }
  return const BloodPressureStatus(
    code: BloodPressureStatusCode.optimal,
    title: 'Huyết áp đang ở mức tốt',
    message: 'Hãy lưu kết quả và duy trì thói quen theo dõi đều đặn.',
    ctaLabel: 'Lưu kết quả',
    level: 0,
  );
}
