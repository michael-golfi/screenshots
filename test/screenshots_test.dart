import 'dart:convert';
import 'dart:io';

import 'package:process/process.dart';
import 'package:screenshots/src/archive.dart';
import 'package:screenshots/src/config.dart';
import 'package:screenshots/src/daemon_client.dart';
import 'package:screenshots/src/globals.dart';
import 'package:screenshots/src/image_processor.dart';
import 'package:screenshots/src/screens.dart';
import 'package:screenshots/src/resources.dart' as resources;
import 'package:screenshots/src/run.dart' as run;
import 'package:screenshots/src/utils.dart' as utils;
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';
import 'package:screenshots/src/fastlane.dart' as fastlane;
import 'package:path/path.dart' as p;

import 'common.dart';

void main() {
  test('screen info for device: Nexus 5X', () async {
    final expected = {
      'resources': {
        'statusbar white': 'resources/android/1080/statusbar.png',
        'statusbar': 'resources/android/1080/statusbar.png',
        'navbar': 'resources/android/1080/navbar.png',
        'frame': 'resources/android/phones/Nexus_5X.png',
        'statusbar black': 'resources/android/1080/statusbar.png'
      },
      'destName': 'phone',
      'resize': '80%',
      'devices': ['Nexus 5X'],
      'offset': '-4-9',
      'size': '1080x1920'
    };
    final screens = Screens();
    await screens.init();
    final screen = screens.screenProps('Nexus 5X');
    expect(screen, expected);
  });

  test('screen info for device: iPhone X', () async {
    final expected = {
      'resources': {
        'statusbar white': 'resources/ios/1125/statusbar_white.png',
        'statusbar': 'resources/ios/1125/statusbar_white.png',
        'frame': 'resources/ios/phones/Apple iPhone X Silver.png',
        'statusbar black': 'resources/ios/1125/statusbar_black.png'
      },
      'resize': '87%',
      'devices': ['iPhone X', 'iPhone XS', 'iPhone Xs'],
      'offset': '-0-0',
      'size': '1125x2436'
    };
    final screens = Screens();
    await screens.init();
    final screen = screens.screenProps('iPhone X');
    expect(screen, expected);
  });

  test('overlay statusbar', () async {
    final Screens screens = Screens();
    await screens.init();
    final screen = screens.screenProps('Nexus 6P');
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final configInfo = config.configInfo;
    final Map scrnResources = screen['resources'];
    await resources.unpackImages(scrnResources, '/tmp/screenshots');
    final statusbarPath =
        '${configInfo['staging']}/${scrnResources['statusbar']}';
    final screenshotPath = 'test/resources/0.png';
    final options = {
      'screenshotPath': screenshotPath,
      'statusbarPath': statusbarPath,
    };
    await im.convert('overlay', options);
  });

  test('unpack screen resource images', () async {
    final Screens screens = Screens();
    await screens.init();
    final screen = screens.screenProps('iPhone 7 Plus');
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final configInfo = config.configInfo;
    final staging = configInfo['staging'];
    final Map screenResources = screen['resources'];
    await resources.unpackImages(screenResources, staging);
  });

  test('append navbar', () async {
    final Screens screens = Screens();
    await screens.init();
    final screen = screens.screenProps('Nexus 9');
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final configInfo = config.configInfo;
    final Map scrnResources = screen['resources'];
    await resources.unpackImages(scrnResources, '/tmp/screenshots');
    final screenshotNavbarPath =
        '${configInfo['staging']}/${scrnResources['navbar']}';
    final screenshotPath = 'test/resources/nexus_9_0.png';
    final options = {
      'screenshotPath': screenshotPath,
      'screenshotNavbarPath': screenshotNavbarPath,
    };
    await im.convert('append', options);
  });

  test('frame screenshot', () async {
    final Screens screens = Screens();
    await screens.init();
    final screen = screens.screenProps('Nexus 9');
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final configInfo = config.configInfo;
    final Map scrnResources = screen['resources'];
    await resources.unpackImages(scrnResources, '/tmp/screenshots');
    final framePath = configInfo['staging'] + '/' + scrnResources['frame'];
    final size = screen['size'];
    final resize = screen['resize'];
    final offset = screen['offset'];
    final screenshotPath = 'test/resources/nexus_9_0.png';
    final options = {
      'framePath': framePath,
      'size': size,
      'resize': resize,
      'offset': offset,
      'screenshotPath': screenshotPath,
      'backgroundColor': ImageProcessor.kDefaultAndroidBackground,
    };
    await im.convert('frame', options);
  });

  test('parse json xcrun simctl list devices', () {
    final expected = {
      'iOS 11.2': [
        {
          'state': 'Shutdown',
          'availability': '(available)',
          'name': 'iPhone 7 Plus',
          'udid': '1DD6DBF1-846F-4644-8E97-76175788B9A5'
        }
      ],
      'iOS 11.1': [
        {
          'state': 'Shutdown',
          'availability': '(available)',
          'name': 'iPhone 7 Plus',
          'udid': 'BF17CEF1-A6B7-4689-96A2-CE9C271D5F16'
        }
      ]
    };
    final iosDevices = utils.getIosSimulators();
    final iPhone7Plus = iosDevices['iPhone 7 Plus'];
    expect(iPhone7Plus, expected);
  });

  test('get highest and available version of ios device', () {
    final expected = {
      'state': 'Shutdown',
      'availability': '(available)',
      'name': 'iPhone 7 Plus',
      'udid': '1DD6DBF1-846F-4644-8E97-76175788B9A5'
    };
    final iosDevices = utils.getIosSimulators();
    final deviceName = 'iPhone 7 Plus';
//    final deviceName = 'iPhone 5c';
    final highestDevice = utils.getHighestIosSimulator(iosDevices, deviceName);
    expect(highestDevice, expected);
  });

  test('read resource and write to path', () async {
    final scrnResources = [
      'resources/android/1080/statusbar.png',
      'resources/android/1080/navbar.png',
      'resources/android/phones/Nexus_5X.png'
    ];
    final dest = '/tmp';
    for (String resource in scrnResources) {
      await resources.writeImage(
          await resources.readResourceImage(resource), '$dest/$resource');
    }
  });

  test('unpack images', () async {
    final scrnResources = {
      'A': 'resources/android/1080/statusbar.png',
      'B': 'resources/android/1080/navbar.png',
      'C': 'resources/android/phones/Nexus_5X.png'
    };
    final dest = '/tmp';
    await resources.unpackImages(scrnResources, dest);
  });

  test('unpack script', () async {
    await resources.unpackScript(
        'resources/script/android-wait-for-emulator', '/tmp');
  });

  test('add prefix to files in directory', () async {
    await utils.prefixFilesInDir('/tmp/screenshots/test', 'my_prefix');
  });

  test('config guide', () async {
    final Screens screens = Screens();
    await screens.init();
    final Config config = Config(configPath: 'test/screenshots_test.yaml');
    final daemonClient = DaemonClient();
    await daemonClient.start;
    config.generateConfigGuide(screens, await daemonClient.devices);
  });

  test('rooted emulator', () async {
    final emulatorId = 'Nexus_5X_API_27';
    final stagingDir = '/tmp/tmp';
    await resources.unpackScripts(stagingDir);
    final daemonClient = DaemonClient();
    await daemonClient.start;
    final deviceId = await daemonClient.launchEmulator(emulatorId);
    final result = run.cmd('adb', ['root'], '.', true);
    expect(result, 'adbd cannot run as root in production builds\n');
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
  });

  test('get emulator id from device name', () {
    final _emulators = utils.getAvdNames();
    print(_emulators);
    final emulator =
        _emulators.firstWhere((emulator) => emulator.contains('Nexus_5X'));
    expect(emulator, 'Nexus_5X_API_27');
  });

  test('move files', () async {
    final fileName = 'filename';
    final srcDir = '/tmp/tmp1/multiple/levels/deep';
    final dstDir = '/tmp/tmp2/more/levels/deep';

    await File('$srcDir/$fileName').create(recursive: true);
    utils.moveFiles(srcDir, dstDir);
    expect(await File(dstDir + '/' + fileName).exists(), true);
  });

  test('start/stop emulator', () async {
    final expected = {
      'id': 'emulator-5554',
      'name': 'Android SDK built for x86',
      'platform': 'android-x86',
      'emulator': true
    };
    final emulatorName = 'Nexus 6P';
    final emulatorId = 'Nexus_6P_API_28';
    final daemonClient = DaemonClient();
    daemonClient.verbose = true;
    await daemonClient.start;
    final deviceId = await daemonClient.launchEmulator(emulatorId);
    final devices = await daemonClient.devices;
    final startedDevice = (devices, emulatorName) => devices
        .firstWhere((device) => device['emulator'] == true, orElse: () => null);
    expect(startedDevice(devices, emulatorName), expected);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
    expect(startedDevice(await daemonClient.devices, emulatorName), null);
  });

  test('change android locale', () async {
    final deviceName = 'Nexus 6P';
    final emulatorId = 'Nexus_6P_API_28';
    final origLocale = 'en-US';
    final newLocale = 'fr-CA';
    final daemonClient = DaemonClient();
    await daemonClient.start;
    daemonClient.verbose = true;
    final deviceId = await daemonClient.launchEmulator(emulatorId);
    print('emulator started');
    run.changeAndroidLocale(deviceId, deviceName, newLocale);
    // wait for locale to change
    await utils.waitAndroidLocaleChange(deviceId, newLocale);
    run.changeAndroidLocale(deviceId, deviceName, origLocale);
    await utils.waitAndroidLocaleChange(deviceId, origLocale);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
  }, timeout: Timeout(Duration(seconds: 180)));

  test('start/stop simulator', () async {
    final simulatorName = 'iPhone X';
    final simulatorInfo =
        utils.getHighestIosSimulator(utils.getIosSimulators(), simulatorName);
    // note: daemonClient should get an 'add.device' event after simulator startup
    final deviceId = simulatorInfo['udid'];
    run.startSimulator(deviceId);
    run.shutdownSimulator(deviceId);
  });

  test('start emulator on travis', () async {
    final androidHome = Platform.environment['ANDROID_HOME'];
    final emulatorName = 'Nexus_6P_API_27';
    await utils.streamCmd(
        '$androidHome/emulator/emulator',
        [
          '-avd',
          emulatorName,
          '-no-audio',
          '-no-window',
          '-no-snapshot',
          '-gpu',
          'swiftshader',
        ],
        '.',
        ProcessStartMode.detached);
  });

  test('delete all files with suffix', () async {
    final dirPath = '/tmp/tmp';
    final files = ['image1.png', 'image2.png'];
    final suffix = 'png';

    // create files
    files
        .forEach((fileName) async => await File('$dirPath/$fileName').create());

    // check created
    files.forEach((fileName) async =>
        expect(await File('$dirPath/$fileName').exists(), true));

    // delete files with suffix
    fastlane.clearFilesWithExt(dirPath, suffix);

    // check deleted
    files.forEach((fileName) async =>
        expect(await File('$dirPath/$fileName').exists(), false));
  });

  // reproduce https://github.com/flutter/flutter/issues/27785
  // on android (hangs during test)
  // tested on android emulator in default locale (en-US) and it worked
  // tested on android emulator in automatically changed to locale fr-CA and it hangs
  // tested on android emulator booted in locale fr-CA and it hangs
//  [trace] FlutterDriver: Isolate found with number: 939713595
//  [trace] FlutterDriver: Isolate is paused at start.
//  [trace] FlutterDriver: Attempting to resume isolate
//  [trace] FlutterDriver: Waiting for service extension
//  [info ] FlutterDriver: Connected to Flutter application.
//  00:04 +0: end-to-end test tap on the floating action button; verify counter
//  [warning] FlutterDriver: waitFor message is taking a long time to complete...
//  hangs
  test('change locale on android and test', () async {
    final emulatorId = 'Nexus_6P_API_28';
    final deviceName = 'any device name';
    final stagingDir = '/tmp/tmp';
    final origLocale = 'en-US';
    final newLocale = 'en-US'; // succeeds
//    final newLocale = 'fr-CA'; // fails
    final testAppDir = 'example';
    final testAppSrcPath = 'test_driver/main.dart';

    // unpack resources
    await resources.unpackScripts(stagingDir);

    final daemonClient = DaemonClient();
    await daemonClient.start;
    // start emulator
    final deviceId = await daemonClient.launchEmulator(emulatorId);

    // change locale
    await run.setAndroidLocale(deviceId, newLocale, deviceName);

    // run test
    await utils.streamCmd('flutter', ['drive', testAppSrcPath], testAppDir);

    // stop emulator
    await run.setAndroidLocale(deviceId, origLocale, deviceName);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
  },
      timeout:
          Timeout(Duration(seconds: 90))); // increase time to get stacktrace

  test('get android device locale', () async {
    final emulatorId = 'Nexus_6P_API_28';
    final stagingDir = '/tmp/tmp';
    final locale = 'en-US';

    await resources.unpackScripts(stagingDir);
    final daemonClient = DaemonClient();
    await daemonClient.start;
    final deviceId = await daemonClient.launchEmulator(emulatorId);
    final deviceLocale = utils.androidDeviceLocale(deviceId);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);

    expect(deviceLocale, locale);
  });

  // reproduce https://github.com/flutter/flutter/issues/27785
  // on ios
  // tested on ios device in default locale (en-US) and it worked
  // tested on ios device in manually changed to locale fr-CA and it hangs
  // tested on ios simulator in default locale (en-US) and it worked
  // tested on ios simulator in automatically changed to locale fr-CA and it hangs
  test('change locale on iOS and test', () async {
    final simulatorName = 'iPhone X';
    final stagingDir = '/tmp/tmp';
    final locale = 'en-US'; // default locale (works)
//    final locale = 'fr-CA'; // fails
    final testAppDir = 'example';
    final testAppSrcPath = 'test_driver/main.dart';

    // unpack resources
    await resources.unpackScripts(stagingDir);

    // change locale
    final simulatorInfo =
        utils.getHighestIosSimulator(utils.getIosSimulators(), simulatorName);
    final deviceId = simulatorInfo['udid'];
    await run.setSimulatorLocale(deviceId, simulatorName, locale, stagingDir,
        running: false);

    // start simulator
//    final daemonClient = DaemonClient();
//    await daemonClient.start;
    run.startSimulator(deviceId);

    // run test
    await utils.streamCmd(
        'flutter', ['-d', deviceId, 'drive', testAppSrcPath], testAppDir);

    // stop simulator
    run.shutdownSimulator(deviceId);
  },
      // increase time to get stacktrace
      timeout: Timeout(Duration(minutes: 2)));

  test('get ios simulator locale', () async {
    final udId = '03D4FC12-3927-4C8B-A226-17DE34AE9C18';
    var locale = utils.iosSimulatorLocale(udId);
    expect(locale, 'en-US');
  });

  test('get avd from a running emulator', () async {
    final expectedId = 'Nexus_6P_API_28';
    final daemonClient = DaemonClient();
    await daemonClient.start;
    // start emulator
    final deviceId = await daemonClient.launchEmulator(expectedId);
    final emulatorId = utils.getAndroidEmulatorId(deviceId);
    expect(emulatorId, expectedId);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
  });

  test('get real devices', () async {
    final expected = [
      {
        'id': '3b3455019e329e007e67239d9b897148244b5053',
        'name': 'Maurice’s iPhone',
        'platform': 'ios',
        'emulator': false,
        'model': 'iPhone 5c (GSM)'
      }
    ];
    final daemonClient = DaemonClient();
    await daemonClient.start;
    final devices = await daemonClient.devices;
    final iosDevices = utils.getIosDevices(devices);
    final androidDevices = utils.getAndroidDevices(devices);
    expect(androidDevices, []);
    expect(iosDevices, expected);
  });

  test('get devices', () {
    final expected = {
      'id': '3b3455019e329e007e67239d9b897148244b5053',
      'name': 'Maurice’s iPhone',
      'platform': 'ios',
      'emulator': false,
      'model': 'iPhone 5c (GSM)'
    };
    String deviceName = 'iPhone 5c';
    Map device = utils.getDevice([expected], deviceName);
    expect(device, expected);
    final isDeviceAttached = (device) => device != null;
    expect(isDeviceAttached(device), true);
    deviceName = 'iPhone X';
    device = utils.getDevice([expected], deviceName);
    expect(device, null);
    expect(isDeviceAttached(device), false);
  });

  test('get device type from config', () {
    final deviceName = 'Nexus 9P';
    final expected = DeviceType.android;
    final config = '''
devices:
  ios:
    iPhone X:
  android:
    $deviceName:
''';

    final configInfo = loadYaml(config);
    DeviceType deviceType = run.getDeviceType(configInfo, deviceName);
    expect(deviceType, expected);
  });

  test('get adb props, and show diffs', () async {
    final expected = {
      'added': {'xxx': 'yyy'},
      'removed': {'wifi.direct.interface': 'p2p-dev-wlan0'},
      'changed': {
        'orig': {'xmpp.auto-presence': 'true'},
        'new': {'xmpp.auto-presence': false}
      }
    };
    final emulatorId = 'Nexus_6P_API_28';

    final daemonClient = DaemonClient();
    await daemonClient.start;
    // start emulator
    final deviceId = await daemonClient.launchEmulator(emulatorId);

    Map props = getDeviceProps(deviceId);
    final newProps = Map.from(props);
    newProps['xmpp.auto-presence'] = false; //changed
    newProps['xxx'] = 'yyy'; // added
    newProps.remove('wifi.direct.interface'); // removed

    final Map diffs = diffMaps(props, newProps);
    expect(diffs, expected);
    expect(await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
  });

  group('ProcessWrapper', () {
    test('works in conjunction with subscribers to stdio streams', () async {
      final expected = 'README.md';
      final delegate = await Process.start('ls', ['-la']);
      final process = ProcessWrapper(delegate);
      final readme = await process.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .firstWhere((line) => line.contains(expected));
      expect(readme.contains(expected), isTrue);
    });

    test('scan syslog for string', () async {
//      final toLocale = 'en-US';
//      final expected =
//          'ContactsProvider: Locale has changed from [fr_CA] to [en_US]';
//      final expected = RegExp('Locale has changed from');
      final expected = RegExp(r'.*');
      final daemonClient = DaemonClient();
      await daemonClient.start;
      final emulatorId = 'Nexus_6P_API_28';
      final deviceId = await daemonClient.launchEmulator(emulatorId);
      String actual = await utils.waitSysLogMsg(deviceId, expected);
      expect(actual.contains(expected), isTrue);
      expect(
          await run.shutdownAndroidEmulator(daemonClient, deviceId), deviceId);
    });

    test('reg exp', () {
      final locale = 'fr-CA';
      final line =
          'ContactsProvider: Locale has changed from [en_US] to [${locale.replaceFirst('-', '_')}]';
//      final regExp = RegExp(
//          'ContactsProvider: Locale has changed from .* to [fr_CA]',
//          dotAll: true);
      final regExp = RegExp(
          'ContactsProvider: Locale has changed from .* to \\[${locale.replaceFirst('-', '_')}\\]');
      expect(regExp.stringMatch(line), line);
      expect(regExp.hasMatch(line), true);
    });
  });

  group('recording, comparison', () {
    test('recording mode', () async {
      final origDir = Directory.current;
      Directory.current = 'example';
      final configPath = 'screenshots.yaml';
      await run.run(configPath, utils.getStringFromEnum(RunMode.recording));
      final configInfo = Config(configPath: configPath).configInfo;
      final recordingDir = configInfo['recording'];
      expect(await utils.isRecorded(recordingDir), isTrue);
      Directory.current = origDir;
    }, timeout: Timeout(Duration(seconds: 180)));

    test('imagemagick compare', () {
      final recordedImage0 = 'test/resources/recording/Nexus 6P-0.png';
      final comparisonImage0 = 'test/resources/comparison/Nexus 6P-0.png';
      final comparisonImage1 = 'test/resources/comparison/Nexus 6P-1.png';
      final goodPair = {
        'recorded': recordedImage0,
        'comparison': comparisonImage0
      };
      final badPair = {
        'recorded': recordedImage0,
        'comparison': comparisonImage1
      };
      final pairs = {'good': goodPair, 'bad': badPair};

      pairs.forEach((behave, pair) {
        final recordedImage = pair['recorded'];
        final comparisonImage = pair['comparison'];
        bool doCompare = im.compare(comparisonImage, recordedImage);
        behave == 'good' ? expect(doCompare, true) : expect(doCompare, false);
        File(im.getDiffName(comparisonImage)).deleteSync();
      });
    });

    test('compare images in directories', () async {
      final comparisonDir = 'test/resources/comparison';
      final recordingDir = 'test/resources/recording';
      final deviceName = 'Nexus 6P';
      final expected = {
        'Nexus 6P-1.png': {
          'recording': 'test/resources/recording/Nexus 6P-1.png',
          'comparison': 'test/resources/comparison/Nexus 6P-1.png',
          'diff': 'test/resources/comparison/Nexus 6P-1-diff.png'
        }
      };

      final imageProcessor = ImageProcessor(null, null);
      final failedCompare = await imageProcessor.compareImages(
          deviceName, recordingDir, comparisonDir);
      expect(failedCompare, expected);
      // show diffs
      if (failedCompare.isNotEmpty) {
        imageProcessor.showFailedCompare(failedCompare);
      }
    });

    test('comparison mode', () async {
      final origDir = Directory.current;
      Directory.current = 'example';
      final configPath = 'screenshots.yaml';
      final configInfo = Config(configPath: configPath).configInfo;
      final recordingDir = configInfo['recording'];
      expect(await utils.isRecorded(recordingDir), isTrue);
      await run.run(configPath, utils.getStringFromEnum(RunMode.comparison));
      Directory.current = origDir;
    }, timeout: Timeout(Duration(seconds: 180)));

    test('cleanup diffs at start of normal run', () {
      final fastlaneDir = 'test/resources/comparison';
      Directory(fastlaneDir).listSync().forEach(
          (fsEntity) => File(im.getDiffName(fsEntity.path)).createSync());
      expect(
          Directory(fastlaneDir).listSync().where((fileSysEntity) =>
              p.basename(fileSysEntity.path).contains(im.diffSuffix)),
          isNotEmpty);
      im.deleteDiffs(fastlaneDir);
      expect(
          Directory(fastlaneDir).listSync().where((fileSysEntity) =>
              p.basename(fileSysEntity.path).contains(im.diffSuffix)),
          isEmpty);
    });
  });

  group('archiving', () {
    test('move images to archive dir', () {
      final stagingDir = 'test/resources';
      final archiveDir = '/tmp/screenshots_archive';
      final archive = Archive(stagingDir, archiveDir);
      final locale = 'en-US';
      final deviceType = DeviceType.android;
      final dstDir = archive.moveTestScreenshots(deviceType, locale);
      expect(Directory(dstDir).listSync(), isNotEmpty);
      // copy back to repeat test
      copyFiles(dstDir, '$stagingDir/test');
    });

    test('run with archiving enabled', () async {
      final origDir = Directory.current;
      Directory.current = 'example';
      final configPath = 'screenshots.yaml';
      await run.run(configPath, utils.getStringFromEnum(RunMode.archive));
      Directory.current = origDir;
    }, timeout: Timeout(Duration(seconds: 180)));
  });
}
