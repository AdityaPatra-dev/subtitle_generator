import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final bool isUpdateAvailable;
  final String releaseName;
  final String releaseNotes;
  final String releaseUrl;
  final String? apkDownloadUrl;
  final int? apkSizeBytes;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.isUpdateAvailable,
    required this.releaseName,
    required this.releaseNotes,
    required this.releaseUrl,
    this.apkDownloadUrl,
    this.apkSizeBytes,
  });
}

class UpdateCheckerService {
  final Dio _dio;

  static const String _owner = 'AdityaPatra-dev';
  static const String _repo = 'subtitle_generator';
  static const String _fallbackCurrentVersion = '1.0.0';

  UpdateCheckerService([Dio? dio]) : _dio = dio ?? Dio();

  /// Compares two semver strings (e.g. "1.0.1" > "1.0.0", "v1.2.0" > "1.1.9")
  static bool isNewerVersion(String latestStr, String currentStr) {
    try {
      final cleanLatest = latestStr.replaceAll(RegExp(r'^[vV]'), '').trim();
      final cleanCurrent = currentStr.replaceAll(RegExp(r'^[vV]'), '').trim();

      // Split off build number e.g. "1.0.0+1" -> "1.0.0" and "1"
      final latestBase = cleanLatest.split('+')[0];
      final currentBase = cleanCurrent.split('+')[0];

      final latestParts = latestBase.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final currentParts = currentBase.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      while (latestParts.length < 3) latestParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);

      for (int i = 0; i < 3; i++) {
        if (latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }

      // Check build number if major.minor.patch are identical
      final latestBuild = cleanLatest.contains('+') ? int.tryParse(cleanLatest.split('+')[1]) ?? 0 : 0;
      final currentBuild = cleanCurrent.contains('+') ? int.tryParse(cleanCurrent.split('+')[1]) ?? 0 : 0;

      return latestBuild > currentBuild;
    } catch (_) {
      return false;
    }
  }

  /// Checks GitHub Releases API for the latest published release
  Future<AppUpdateInfo> checkForUpdates() async {
    String currentVersion = _fallbackCurrentVersion;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (_) {
      // Running in unit test or non-platform context
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'subtitle-generator-app',
      };
      if (Platform.environment.containsKey('GITHUB_TOKEN')) {
        headers['Authorization'] = 'Bearer ${Platform.environment['GITHUB_TOKEN']}';
      }

      final response = await _dio.get(
        'https://api.github.com/repos/$_owner/$_repo/releases/latest',
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to check for updates: HTTP ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final tagName = data['tag_name']?.toString() ?? '1.0.0';
      final releaseName = data['name']?.toString() ?? tagName;
      final body = data['body']?.toString() ?? 'No release notes provided.';
      final htmlUrl = data['html_url']?.toString() ?? 'https://github.com/$_owner/$_repo/releases';

      // Find APK asset
      String? apkUrl;
      int? apkSize;
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      for (final asset in assets) {
        final a = asset as Map<String, dynamic>;
        final name = a['name']?.toString() ?? '';
        if (name.endsWith('.apk')) {
          apkUrl = a['browser_download_url']?.toString();
          apkSize = a['size'] as int?;
          break;
        }
      }

      final updateAvailable = isNewerVersion(tagName, currentVersion);

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: tagName,
        isUpdateAvailable: updateAvailable,
        releaseName: releaseName,
        releaseNotes: body,
        releaseUrl: htmlUrl,
        apkDownloadUrl: apkUrl,
        apkSizeBytes: apkSize,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // No releases yet
        return AppUpdateInfo(
          currentVersion: currentVersion,
          latestVersion: currentVersion,
          isUpdateAvailable: false,
          releaseName: 'Latest',
          releaseNotes: 'Application is running the current version.',
          releaseUrl: 'https://github.com/$_owner/$_repo',
        );
      }
      rethrow;
    }
  }

  /// Downloads the APK and triggers the in-place package installer
  Future<void> downloadAndInstallUpdate({
    required String downloadUrl,
    required String fileName,
    required void Function(int received, int total) onProgress,
  }) async {
    if (Platform.isAndroid) {
      // Download to cache/temp directory
      final cacheDir = await getTemporaryDirectory();
      final targetPath = '${cacheDir.path}/$fileName';

      // Remove any existing older download with same name
      final existing = File(targetPath);
      if (await existing.exists()) {
        await existing.delete();
      }

      await _dio.download(
        downloadUrl,
        targetPath,
        onReceiveProgress: onProgress,
      );

      // Launch the Android Package Installer
      final result = await OpenFilex.open(
        targetPath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        throw Exception('Package installer error: ${result.message}');
      }
    } else {
      // On Desktop (Linux/Windows/macOS) or web: open release download in browser
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch update URL: $downloadUrl');
      }
    }
  }
}
