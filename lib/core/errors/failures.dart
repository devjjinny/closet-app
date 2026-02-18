sealed class Failure {
  const Failure(this.message);
  final String message;

  @override
  String toString() => 'Failure: $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결을 확인해주세요']);
}

class WeatherFailure extends Failure {
  const WeatherFailure([super.message = '날씨 정보를 불러오지 못했어요']);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = '파일 업로드에 실패했어요']);
}

class ImageProcessingFailure extends Failure {
  const ImageProcessingFailure([super.message = '이미지 처리에 실패했어요']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = '인증에 실패했어요']);
}

class FirestoreFailure extends Failure {
  const FirestoreFailure([super.message = '데이터 저장/조회에 실패했어요']);
}
