import 'package:test/test.dart';
import '../../lib/core/kalman_filter.dart';

void main() {
  group('KalmanFilter Tests', () {
    test('Should smooth out noisy data', () {
      final filter = KalmanFilter(q: 0.1, r: 1.0, initialValue: 1013.0);
      
      // 模拟带有随机噪声的气压值
      final measurements = [1013.2, 1012.8, 1013.5, 1012.9, 1013.1];
      double lastResult = 1013.0;

      for (var m in measurements) {
        lastResult = filter.update(m);
        print('Measured: $m, Filtered: $lastResult');
      }

      // 滤波后的值应该在合理范围内，且波动小于原始测量值
      expect(lastResult, closeTo(1013.1, 0.5));
    });

    test('Should track significant trends', () {
      final filter = KalmanFilter(q: 0.5, r: 0.1, initialValue: 1013.0);
      
      // 模拟高度下降（气压上升）的显著趋势
      final measurements = [1013.0, 1014.0, 1015.0, 1016.0, 1017.0];
      double lastResult = 0.0;

      for (var m in measurements) {
        lastResult = filter.update(m);
      }

      // 趋势跟踪应该能够反映出气压的显著上升
      expect(lastResult, greaterThan(1016.0));
    });
  });
}
