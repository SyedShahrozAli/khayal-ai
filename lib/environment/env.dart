import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'API_BASE_URL', obfuscate: true)
  static final String apiBaseUrl = _Env.apiBaseUrl;

  @EnviedField(varName: 'GOOGLE_CLIENT_ID', obfuscate: true)
  static final String googleClientId = _Env.googleClientId;

  @EnviedField(varName: 'GOOGLE_SERVER_CLIENT_ID', obfuscate: true)
  static final String googleServerClientId = _Env.googleServerClientId;

  @EnviedField(varName: 'REVENUE_CAT_PLAY_STORE', obfuscate: true)
  static final String revenueCatPlayStore = _Env.revenueCatPlayStore;

  @EnviedField(varName: 'REVENUE_CAT_APP_STORE', obfuscate: true)
  static final String revenueCatAppStore = _Env.revenueCatAppStore;
}