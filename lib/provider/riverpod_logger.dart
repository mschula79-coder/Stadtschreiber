import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stadtschreiber/services/debug_service.dart';

base class RiverpodLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    DebugService.log('''
-------------------------
Provider: ${context.provider.name ?? context.provider.runtimeType}
Previous: $previousValue
New:      $newValue
-------------------------
''');
  }
}
