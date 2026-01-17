/// 简易卡尔曼滤波器，用于平滑传感器（如气压计）的噪声数据。
class KalmanFilter {
  double _q; // 过程噪声协方差 (Process noise covariance)
  double _r; // 测量噪声协方差 (Measurement noise covariance)
  double _p = 1.0; // 估计误差协方差 (Estimation error covariance)
  double _x = 0.0; // 估计值 (Estimated value)
  double _k = 0.0; // 卡尔曼增益 (Kalman gain)

  KalmanFilter({double q = 0.1, double r = 0.1, double initialValue = 0.0})
      : _q = q,
        _r = r,
        _x = initialValue;

  /// 更新并返回滤波后的新值
  double update(double measurement) {
    // 预测阶段
    _p = _p + _q;

    // 测量更新阶段
    _k = _p / (_p + _r);
    _x = _x + _k * (measurement - _x);
    _p = (1 - _k) * _p;

    return _x;
  }

  /// 获取当前估计值
  double get value => _x;
}
