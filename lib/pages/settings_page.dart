import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qrcode_keeper/exceptions/app_exception.dart';
import 'package:qrcode_keeper/helpers/date.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/models/versions_info.dart';
import 'package:qrcode_keeper/pages/exp_imp_codes_page.dart';
import 'package:qrcode_keeper/services/local_notifications_service.dart';
import 'package:qrcode_keeper/services/native_code_service.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool? _hasNotifPermissions;
  bool _initializingNotifications = false;
  String? _notifError;
  VersionsInfo? _versions;
  int _exportPresses = 0;
  Timer? _exportPresserTimeout;

  final _notificationDays = Map<int, bool>.fromIterable(
    List.generate(DateTime.daysPerWeek, (index) => index + 1),
    value: (_) => false,
  );
  TimeOfDay _notificationTime = const TimeOfDay(hour: 10, minute: 15);

  @override
  void initState() {
    super.initState();

    _initServices().then((_) {
      return _setCurrentNotificationsState();
    });
    _readVersions();
  }

  @override
  void dispose() {
    _exportPresserTimeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: remove this calculation by using correct widgets
    final height = MediaQuery.of(context).size.height -
        2 * kBottomNavigationBarHeight -
        3 * 16;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [_buildHiddenExportButton(context)],
      ),
      body: Container(
        height: double.infinity,
        // color: Colors.lightBlue.shade100,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Container(
            height: height,
            // color: Colors.lightGreen.shade200,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_initializingNotifications)
                  const Center(
                    child: CircularProgressIndicator.adaptive(),
                  )
                else
                  Column(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    // mainAxisSize: MainAxisSize.min,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      ListTile(
                        title: const Text('Notifications Permissions:'),
                        leading: const Icon(Icons.notifications_outlined),
                        enableFeedback: false,
                        trailing: Checkbox(
                          tristate: true,
                          value: (_hasNotifPermissions),
                          onChanged: _hasNotifPermissions == true
                              ? null
                              : (value) {
                                  if (_hasNotifPermissions != true) {
                                    _requestNotifPermissions();
                                  }
                                },
                          fillColor: MaterialStateProperty.resolveWith<Color>(
                            (states) {
                              if (_hasNotifPermissions == null) {
                                return Colors.blue;
                              } else if (!_hasNotifPermissions!) {
                                return Colors.orange.shade800;
                              }

                              return Colors.green;
                            },
                          ),
                        ),
                      ),
                      if (_notifError != null) ErrorText(_notifError!),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 180,
                        child: OutlinedButton.icon(
                          onPressed: _openTimePickerHandler,
                          icon: const Icon(Icons.watch_later_outlined),
                          label: Text(_notificationTime.format(context)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        runSpacing: 16,
                        alignment: WrapAlignment.end,
                        children: [
                          for (final day in _notificationDays.entries)
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(kWeekDays[day.key]!.substring(0, 3)),
                                Transform.rotate(
                                  angle: -0.5,
                                  child: SizedBox(
                                    width: 50,
                                    child: Switch(
                                      onChanged: _initializingNotifications
                                          ? null
                                          : (v) {
                                              setState(() {
                                                _notificationDays[day.key] = v;
                                              });
                                              _updateNotifications();
                                            },
                                      value: day.value,
                                    ),
                                  ),
                                ),
                              ],
                            )
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                Text(
                  'version: ${_versions?.appVersion ?? '-'}',
                  style: Theme.of(context).textTheme.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector _buildHiddenExportButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _exportPresses++;
        _exportPresserTimeout?.cancel();
        if (_exportPresses == 4) {
          Navigator.of(context, rootNavigator: true)
              .push<bool?>(
            MaterialPageRoute(
              builder: (context) => const ExpImpCodesPage(),
              fullscreenDialog: true,
            ),
          )
              .then((value) {
            if (value == true) {
              SnackbarCustom.show(
                context,
                title: SnackbarCustom.successTitle,
                message: 'Imported',
                level: MessageLevel.success,
              );
            }
          });
          return;
        }
        _exportPresserTimeout?.cancel();
        _exportPresserTimeout = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            _exportPresses = 0;
          }
        });
      },
      child: Container(
        width: 48,
        color: Colors.transparent,
      ),
    );
  }

  void _openTimePickerHandler() async {
    final nowTime = TimeOfDay.now();
    final notifTime = await showTimePicker(
      context: context,
      initialTime:
          kReleaseMode ? const TimeOfDay(hour: 10, minute: 0) : nowTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child ?? const Text('error'),
        );
      },
    );
    if (notifTime == null) {
      return;
    }
    setState(() {
      _notificationTime = notifTime;
    });

    _updateNotifications();
  }

  void _updateNotifications() async {
    Set<int> days = {};
    _notificationDays.forEach((key, value) {
      if (value) {
        days.add(key);
      }
    });

    final ns = LocalNotificationsService();
    try {
      ns.scheduleWeekDaysNotifications(
        days: days,
        notificationTime: _notificationTime,
        title: 'Qr Keeper Remainder',
        body: 'Go fetch some food (daily)',
      );
    } on AppException catch (ex) {
      SnackbarCustom.hideCurrent(context);
      SnackbarCustom.show(context, mounted: mounted, message: ex.message);
    } on Exception catch (ex) {
      debugPrint('_updateNotifications: ex: $ex');
      SnackbarCustom.hideCurrent(context);
      SnackbarCustom.show(
        context,
        mounted: mounted,
        title: SnackbarCustom.errorTitle,
      );
    }
  }

  Future<void> _initServices() async {
    final notifServiceInitialized = await _initNotifService();
    if (notifServiceInitialized) {
      return _requestNotifPermissions();
    }
  }

  Future<bool> _initNotifService() async {
    setState(() {
      _initializingNotifications = true;
    });
    try {
      await LocalNotificationsService.initialize();
      setState(() {
        _initializingNotifications = false;
      });

      return true;
    } catch (err) {
      debugPrint('Initialize notifications: err: $err');
      setState(() {
        _initializingNotifications = false;
      });
      SnackbarCustom.show(
        context,
        mounted: mounted,
        title: SnackbarCustom.errorTitle,
        message: 'Could not initialize notifications settings.',
        level: MessageLevel.error,
      );
      return false;
    }
  }

  Future<void> _requestNotifPermissions() async {
    try {
      final ns = LocalNotificationsService();
      final hasPermissions = await ns.requestPermissions();

      setState(() {
        if (hasPermissions == false) {
          _notifError =
              'You must grant notifications permissions otherwise no notification will show up (see Android Settings / Applications).';
        } else if (hasPermissions == null) {
          throw AppException(
            'Verifying notifications permissions failed.',
            'requestPermissions has returned null',
          );
        } else {
          _notifError = null;
        }
        _hasNotifPermissions = hasPermissions;
      });
    } on Exception catch (ex) {
      debugPrint('_requestNotifPermissions: ex: $ex');
      setState(() {
        _hasNotifPermissions = null;
        _notifError =
            'Couldn\'t verify notifications permissions, ensure the app has them granted otherwise no notification will show up (see Android Settings / Applications)';
      });
      SnackbarCustom.hideCurrent(context, mounted: mounted);
      SnackbarCustom.show(
        context,
        mounted: mounted,
        title: SnackbarCustom.errorTitle,
        message: 'Failed to get notification permissions.',
        level: MessageLevel.error,
      );
    }
  }

  Future<void> _setCurrentNotificationsState() async {
    final ns = LocalNotificationsService();
    try {
      final weekDaysNotifications =
          await ns.getPendingWeekDayNotificationRequests();
      if (weekDaysNotifications.isEmpty) {
        return;
      }

      _notificationTime = weekDaysNotifications[0].time;

      _notificationDays.forEach((key, value) {
        _notificationDays[key] = false;
      });

      for (var notif in weekDaysNotifications) {
        _notificationDays[notif.weekDay] = true;
      }

      setState(() {});
    } on Exception catch (ex) {
      debugPrint('_setCurrentNotificationsState: ex: $ex');
      setState(() {
        _notifError = 'Couldn\'t get notifications state.';
      });
    }
  }

  void _readVersions() async {
    _versions = await NativeCodeService.getVersionsInfo();
    setState(() {});
  }
}
