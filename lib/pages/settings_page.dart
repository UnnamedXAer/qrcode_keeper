import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qrcode_keeper/exceptions/app_exception.dart';
import 'package:qrcode_keeper/helpers/date.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/services/local_notifications_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String>? _notificationsInfo;
  bool? _hasNotifPermissions;
  bool _initializingNotifications = false;
  final _notificationDays = Map<int, bool>.fromIterable(
    List.generate(DateTime.daysPerWeek, (index) => index + 1),
    value: (_) => false,
  );
  TimeOfDay _notificationTime = const TimeOfDay(hour: 10, minute: 15);

  @override
  void initState() {
    super.initState();
    _initServices();
  }

  void _initServices() async {
    final notifServiceInitialized = await _initNotifService();
    if (notifServiceInitialized) {
      _requestNotifPermissions();
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

  void _requestNotifPermissions() async {
    try {
      final ns = LocalNotificationsService();
      final hasPermissions = await ns.requestPermissions();
      log('perm: $hasPermissions');
      setState(() {
        _hasNotifPermissions = hasPermissions;
      });
    } catch (err) {
      SnackbarCustom.show(
        context,
        mounted: mounted,
        title: SnackbarCustom.errorTitle,
        message: 'Failed to request notification permissions.',
        level: MessageLevel.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    log('🔔 notif perms: $_hasNotifPermissions');

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: _initializingNotifications
            ? const Center(
                child: CircularProgressIndicator.adaptive(),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  ListTile(
                    title: const Text('Permissions:'),
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
                            return Colors.green.withOpacity(.32);
                          } else if (!_hasNotifPermissions!) {
                            return Colors.orange.shade800;
                          }

                          return Colors.green;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final nowTime = TimeOfDay.now();
                      final notifTime = await showTimePicker(
                        context: context,
                        initialTime: kReleaseMode
                            ? const TimeOfDay(hour: 10, minute: 0)
                            : nowTime,
                        builder: (context, child) {
                          return MediaQuery(
                            data: MediaQuery.of(context)
                                .copyWith(alwaysUse24HourFormat: true),
                            child: child ?? const Text('error'),
                          );
                        },
                      );
                      if (notifTime == null) {
                        return;
                      }
                    },
                    icon: const Icon(Icons.notifications_outlined),
                    label: const Text('Schedule Notification!'),
                  ),
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
                    children: [
                      for (final day in _notificationDays.entries)
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(kWeekDays[day.key]!.substring(0, 3)),
                            Transform.rotate(
                              angle: -0.5,
                              child: Switch(
                                onChanged: (v) {
                                  setState(() {
                                    _notificationDays[day.key] = v;
                                  });
                                  _updateNotifications();
                                },
                                value: day.value,
                              ),
                            ),
                          ],
                        )
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      final ns = LocalNotificationsService();
                      ns.getPendingNotificationRequestText().then((value) {
                        setState(() => _notificationsInfo = value);
                      });
                    },
                    icon: const Icon(Icons.circle_notifications_outlined),
                    label: const Text('See Scheduled Notifications!'),
                  ),
                  const SizedBox(height: 16),
                  ..._notificationsInfo != null
                      ? _notificationsInfo!.map((e) => Text(e)).toList()
                      : [const Text('-')],
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {
                      final ns = LocalNotificationsService();
                      ns
                          .cancelAll()
                          .then((_) => ns.getPendingNotificationRequestText())
                          .then((value) {
                        setState(() => _notificationsInfo = value);
                      });
                    },
                    icon: const Icon(Icons.notifications_off_outlined),
                    label: const Text('Cancel All Notifications!'),
                  ),
                ],
              ),
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

    if (days.isEmpty) {
      return;
    }

    final ns = LocalNotificationsService();
    try {
      ns.showTZScheduledForDays(
        days: days,
        notificationTime: _notificationTime,
        title: 'Qr Keeper Remainder',
        body: 'Go fetch some pasza (daily)',
        // body: payload,
        payload: null,
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
}
