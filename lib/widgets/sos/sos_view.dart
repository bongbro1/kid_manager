import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/viewmodels/location/sos_view_model.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

class SosView extends StatelessWidget {
  final double lat;
  final double lng;
  final double? acc;

  bool hasProvider<T>(BuildContext context) {
    try {
      context.read<T>();
      return true;
    } catch (e) {
      return false;
    }
  }
  const SosView({
    super.key,
    required this.lat,
    required this.lng,
    this.acc,
  });

  @override
  Widget build(BuildContext context) {
    final ok = hasProvider<SosViewModel>(context);
    debugPrint('SosView: HAS SosViewModel? $ok');
    debugPrint('SosView FILE = kid_manager/widgets/sos/sos_view.dart (new version)');
    if (!ok) {
      return const Scaffold(
        body: Center(child: Text('SOS Provider NOT FOUND (debug)')),
      );
    }

    final sosVm = context.watch<SosViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (sosVm.error != null)
              Text(sosVm.error!, style: const TextStyle(color: Colors.red)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: sosVm.sending
                    ? null
                    : () async {
                  final sosId = await context.read<SosViewModel>().triggerSos(
                    lat: lat,
                    lng: lng,
                    acc: acc,
                  );
                  if (sosId != null && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: sosVm.sending
                    ? const CircularProgressIndicator()
                    : const Text('GỬI SOS'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}