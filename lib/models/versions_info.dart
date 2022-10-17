class VersionsInfo {
  double? osVersion;
  String? appVersionName;
  int? appVersionCode;

  String? get appVersion {
    String? s = appVersionName;
    if (s == null) {
      return null;
    }

    if (appVersionCode != null) {
      s += '+$appVersionCode';
    }

    return s;
  }

  VersionsInfo();

  VersionsInfo.fromMap(Map<String, dynamic> data)
      : osVersion = data['osVersion'],
        appVersionName = data['appVersionName'],
        appVersionCode = data['appVersionCode'];

  @override
  String toString() {
    return 'Os version: $osVersion; app: $appVersionName+$appVersionCode';
  }
}
