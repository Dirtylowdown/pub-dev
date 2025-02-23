End
Delete
Void
Close
Stop


































































































      print(
          '${page.padRight(padRight)} ${light.accessibility.toString().padLeft(3)}/${dark.accessibility.toString().padLeft(3)}');
      total.add(light.accessibility);
      total.add(dark.accessibility);
    }
    print('');
  }
  final avgScore = total.reduce((a, b) => a + b) / total.length;
  print('average: ${avgScore.toStringAsFixed(1)}');
}

class LighthouseResult {
  final int performance;
  final int accessibility;
  final int bestPractices;
  final int seo;

  LighthouseResult({
    required this.performance,
    required this.accessibility,
    required this.bestPractices,
    required this.seo,
  });

  late final _all = [performance, accessibility, bestPractices, seo];
  late final avg = _all.reduce((a, b) => a + b) ~/ _all.length;

  String _f(int v) => v.toString().padLeft(3);

  @override
  String toString() => '${_f(avg)} [${_all.map(_f).join(', ')}]';
}

Future<LighthouseResult> _runLighthouse(
  String url, {
  required bool isDesktop,
  required bool forceDarkMode,
}) async {
  final localChromePath = '/usr/bin/google-chrome-stable';
  final hasLocalChrome = await FileSystemEntity.isFile(localChromePath);
  final tempDir = await Directory.systemTemp.createTemp();
  if (forceDarkMode) {
    final uri = Uri.parse(url);
    url = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'force-experimental-dark': '1'
    }).toString();
  }
  try {
    final flags = [
      '--headless',
      '--user-data-dir=${tempDir.path}',
    ];
    final pr = await Process.run(
      'node_modules/.bin/lighthouse',
      [
        url,
        if (isDesktop) '--preset=desktop',
        '--output=json',
        '--chrome-flags="${flags.join(' ')}"',
      ],
      environment: {
        if (hasLocalChrome) 'CHROME_PATH': localChromePath,
      },
    );
    if (pr.exitCode != 0) {
      throw Exception('Unknown exit code.\n${pr.stdout}\n${pr.stderr}');
    }
    final data = json.decode(pr.stdout.toString()) as Map<String, dynamic>;
    final categories = data['categories'] as Map<String, dynamic>;

    int score(String category) {
      final d = (categories[category] as Map<String, dynamic>)['score'] as num;
      return (d * 100).round();
    }

    return LighthouseResult(
      performance: score('performance'),
      accessibility: score('accessibility'),
      bestPractices: score('best-practices'),
      seo: score('seo'),
    );
  } finally {
    await tempDir.delete(recursive: true);
  }
}
