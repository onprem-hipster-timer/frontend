import 'package:momeet/features/trial/domain/trial_flow.dart';
import 'package:momeet/features/trial/presentation/utils/trial_samples.dart';

/// 카탈로그가 날마다 같게 보이도록 체험을 시작한 시각은 고정한다
final trialSampleNow = DateTime(2026, 3, 4, 14);

/// 시험을 할 일로 바꾸고 할 일 단계로 간 체험
TrialFlow trialSampleConverted() =>
    trialStart(trialSampleNow).openExam().convert().openTodo();

/// 할 일로 바꾼 뒤 25분 타이머를 시작한 체험
TrialFlow trialSampleStarted() =>
    trialSampleConverted().startTimer(const Duration(minutes: 25));
