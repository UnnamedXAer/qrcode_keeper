import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:qrcode_keeper/services/local_notifications_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _notificationsInfoTextController = TextEditingController();
  bool? _perm = null;

  @override
  void initState() {
    super.initState();
    final ns = LocalNotificationsService();

    ns.requestPermissions().then((v) {
      log('perm: $v');
      setState(() {
        _perm = v;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            CheckboxListTile(
              tristate: true,
              value: _perm,
              onChanged: null,
              title: const Text('Permissions:'),
            ),
            TextButton.icon(
              onPressed: () {
                final ns = LocalNotificationsService();
                ns.show(
                  id: 1,
                  title: 'Qr Keeper Remainder',
                  body: 'Go fetch some pasza',
                  payload: DateTime.now().toString(),
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('show notification now!'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                const kOffsetSeconds = 60;

                final now = DateTime.now();
                final scheduledTime = now.add(
                  const Duration(seconds: kOffsetSeconds),
                );

                final time = Time(
                  scheduledTime.hour,
                  scheduledTime.minute,
                  scheduledTime.second,
                );

                final payload =
                    'Notification scheduled at ${now.toString()} for ${time.hour}:${time.minute}:${time.second}';

                log('🔔$payload');

                final ns = LocalNotificationsService();
                ns.showTZScheduled(
                  id: LocalNotificationsService.kDailyQrReminderId,
                  notificationTime: time,
                  title: 'Qr Keeper Remainder',
                  body: 'Go fetch some pasza (daily)',
                  payload: payload,
                );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Schedule Notification!'),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                final ns = LocalNotificationsService();
                ns.getPendingNotificationRequestText().then(
                      (value) => _notificationsInfoTextController.text = value,
                    );
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('See Scheduled Notifications!'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notificationsInfoTextController,
              minLines: 4,
              maxLines: 10,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                final ns = LocalNotificationsService();
                ns.cancelAll();
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Cancel All Notifications!'),
            ),
          ],
        ),
      ),
    );
  }
}
