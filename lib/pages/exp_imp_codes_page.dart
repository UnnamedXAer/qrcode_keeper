import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qrcode_keeper/helpers/snackbar.dart';
import 'package:qrcode_keeper/services/database.dart';
import 'package:qrcode_keeper/widgets/error_text.dart';

class ExpImpCodesPage extends StatefulWidget {
  const ExpImpCodesPage({super.key});

  @override
  State<ExpImpCodesPage> createState() => _ExpImpCodesPageState();
}

class _ExpImpCodesPageState extends State<ExpImpCodesPage> {
  String _dataExport = '';
  final _controllerDataImport = TextEditingController();
  bool _working = false;
  String? _exportError;
  String? _importError;

  @override
  void dispose() {
    _controllerDataImport.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Codes Export/Import'),
        ),
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _setExportToText,
              icon: const Icon(Icons.download),
              label: const Text('Export Codes to Json'),
            ),
            const Text('Export Json:'),
            if (_exportError != null) _buildError(_exportError!),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.lightGreen.shade100,
                child: SelectableText(
                  _dataExport,
                  onTap: (() {
                    Clipboard.setData(ClipboardData(text: _dataExport));
                  }),
                ),
              ),
            ),
            const Divider(),
            const Text('Import Json:'),
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.pink.shade100,
                child: TextField(
                  controller: _controllerDataImport,
                  expands: true,
                  maxLines: null,
                ),
              ),
            ),
            if (_importError != null) _buildError(_importError!),
            OutlinedButton.icon(
              onPressed: _importFromText,
              icon: const Icon(Icons.download),
              label: const Text('Import Codes from Json'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String text) {
    return Expanded(
      child: SizedBox(
        height: 300,
        child: SingleChildScrollView(
          child: ErrorText(text),
        ),
      ),
    );
  }

  void _setExportToText() async {
    if (_working) {
      return;
    }

    setState(() {
      _working = true;
    });

    final dbs = DBService();
    try {
      final data = await dbs.exportCodesToJSON();
      setState(() {
        _dataExport = data;
        _working = false;
        _exportError = null;
      });
      // ignore: use_build_context_synchronously
      SnackbarCustom.show(
        context,
        title: SnackbarCustom.successTitle,
        level: MessageLevel.success,
      );
    } catch (err) {
      setState(() {
        _exportError = '$err';
        _working = false;
      });
    }
  }

  void _importFromText() async {
    if (_controllerDataImport.text.isEmpty || _working) {
      return;
    }

    setState(() {
      _working = true;
    });

    final dbs = DBService();
    try {
      await dbs.importCodesFromJson(_controllerDataImport.text);
      if (mounted) Navigator.of(context).pop(true);
    } catch (err) {
      _importError = '$err';
      _working = false;
    }
  }
}
