import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/services/prayer_display_snapshot.dart';
import 'package:huda/core/services/prayer_location_generation.dart';
import 'package:huda/core/services/prayer_location_repository.dart';
import 'package:huda/core/services/prayer_notification_gateway.dart';
import 'package:huda/core/services/prayer_notification_models.dart';
import 'package:huda/core/services/prayer_notification_scheduler.dart';
import 'package:huda/core/services/prayer_reliability_storage.dart';
import 'package:huda/core/services/prayer_time_zone_service.dart';
import 'package:huda/core/services/windows_prayer_notification_gateway.dart';
import 'package:huda/core/services/windows_prayer_worker_cache.dart';
import 'package:synchronized/synchronized.dart';

typedef WindowsPrayerGatewayFactory =
    PrayerNotificationGateway Function(String appId, String deviceTimeZone);

class WindowsPrayerWorkerResult {
  const WindowsPrayerWorkerResult(this.result, this.diagnostics);
  final PrayerScheduleResult result;
  final Map<String, int> diagnostics;
}

class _Bootstrap {
  const _Bootstrap(this.token, this.ready, this.gatewayFactory);
  final RootIsolateToken token;
  final SendPort ready;
  final WindowsPrayerGatewayFactory? gatewayFactory;
}

class _Request {
  const _Request({
    required this.reply,
    required this.directory,
    required this.appId,
    required this.zone,
    required this.reason,
    required this.force,
    this.candidate,
    this.fixedNow,
  });
  final SendPort reply;
  final String directory;
  final String appId;
  final String zone;
  final String reason;
  final bool force;
  final PrayerLocationGeneration? candidate;
  final DateTime? fixedNow;
}

/// One dispatcher per engine serializes complete jobs, including publication.
/// The on-disk ownership lock also coordinates app-side location/settings writes.
class WindowsPrayerSchedulingWorker {
  WindowsPrayerSchedulingWorker({this.gatewayFactory});
  static final shared = WindowsPrayerSchedulingWorker();
  final WindowsPrayerGatewayFactory? gatewayFactory;
  final Lock _lock = Lock();
  Future<SendPort>? _started;
  Isolate? _isolate;
  ReceivePort? _errors;
  ReceivePort? _exits;
  Completer<WindowsPrayerWorkerResult>? _active;
  int _generation = 0;

  Future<SendPort> _start() async {
    final token = RootIsolateToken.instance;
    if (token == null) {
      throw StateError('Scheduling controller must run on root isolate');
    }
    final generation = ++_generation;
    _errors?.close();
    _exits?.close();
    _errors = ReceivePort();
    _exits = ReceivePort();
    void failed(dynamic error) {
      if (generation != _generation) return;
      _started = null;
      _isolate = null;
      if (_active != null && !_active!.isCompleted) {
        _active!.completeError(
          StateError('Windows scheduling worker exited: $error'),
        );
      }
    }

    _errors!.listen(failed);
    _exits!.listen((_) => failed('exit'));
    final ready = ReceivePort();
    try {
      _isolate = await Isolate.spawn(
        _workerMain,
        _Bootstrap(token, ready.sendPort, gatewayFactory),
        debugName: 'huda-windows-prayer-reconciliation',
        onError: _errors!.sendPort,
        onExit: _exits!.sendPort,
        errorsAreFatal: true,
      );
      return (await ready.first.timeout(const Duration(seconds: 30)))
          as SendPort;
    } finally {
      ready.close();
    }
  }

  Future<WindowsPrayerWorkerResult> run({
    required String directory,
    required String appId,
    required String zone,
    required String reason,
    required bool force,
    required WindowsPrayerWorkerRpc rpc,
    PrayerLocationGeneration? candidate,
    DateTime? fixedNow,
  }) => _lock.synchronized(() async {
    final started = _started ??= _start();
    SendPort commands;
    try {
      commands = await started;
    } catch (_) {
      _started = null;
      rethrow;
    }
    final responses = ReceivePort();
    final completion = Completer<WindowsPrayerWorkerResult>();
    _active = completion;
    responses.listen((dynamic message) async {
      final response = message as Map;
      if (response['operation'] == 'complete') {
        if (!completion.isCompleted) {
          completion.complete(response['result'] as WindowsPrayerWorkerResult);
        }
        return;
      }
      final reply = response['reply'] as SendPort;
      try {
        final value = await rpc(
          response['operation'] as String,
          Map<String, Object?>.from(response['arguments'] as Map),
        );
        reply.send({'ok': true, 'value': value});
      } catch (error) {
        reply.send({'ok': false, 'error': '$error'});
      }
    });
    commands.send(
      _Request(
        reply: responses.sendPort,
        directory: directory,
        appId: appId,
        zone: zone,
        reason: reason,
        force: force,
        candidate: candidate,
        fixedNow: fixedNow,
      ),
    );
    try {
      return await completion.future;
    } finally {
      _active = null;
      responses.close();
    }
  });

  /// Only stops an idle worker. Tests can then prove recovery in a fresh isolate.
  Future<void> dispose() => _lock.synchronized(() async {
    ++_generation;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _started = null;
    _errors?.close();
    _exits?.close();
  });
}

Future<Object?> _rpc(
  SendPort root,
  String operation,
  Map<String, Object?> arguments,
) async {
  final reply = ReceivePort();
  try {
    root.send({
      'operation': operation,
      'arguments': arguments,
      'reply': reply.sendPort,
    });
    final response =
        (await reply.first.timeout(const Duration(seconds: 60))) as Map;
    if (response['ok'] != true) throw StateError(response['error'] as String);
    return response['value'];
  } finally {
    reply.close();
  }
}

@pragma('vm:entry-point')
Future<void> _workerMain(_Bootstrap bootstrap) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(bootstrap.token);
  PrayerTimeZoneService.initializeDatabase();
  final commands = ReceivePort();
  bootstrap.ready.send(commands.sendPort);
  await for (final dynamic command in commands) {
    final request = command as _Request;
    final cache = WindowsPrayerWorkerCache(
      (operation, arguments) => _rpc(request.reply, operation, arguments),
    );
    PrayerNotificationGateway? gateway;
    PrayerScheduleResult result;
    try {
      await cache.init();
      final storage = await AtomicPrayerReliabilityStorage.create(
        directory: Directory(request.directory),
      );
      final now = request.fixedNow == null
          ? DateTime.now
          : () => request.fixedNow!;
      final repository = PrayerLocationRepository(
        cacheHelper: cache,
        storage: storage,
        now: now,
      );
      gateway =
          bootstrap.gatewayFactory?.call(request.appId, request.zone) ??
          WindowsPrayerNotificationGateway(
            appId: request.appId,
            deviceTimeZone: request.zone,
          );
      final scheduler = PrayerNotificationScheduler(
        cacheHelper: cache,
        notifications: gateway,
        locationRepository: repository,
        now: now,
        deferWidgetPublication: true,
      );
      result = request.candidate == null
          ? await scheduler.reconcile(
              reason: request.reason,
              force: request.force,
            )
          : await scheduler.activateCandidate(
              candidate: request.candidate!,
              reason: request.reason,
            );
      await _publishAfterUnlock(repository, request.reply);
    } catch (error, stack) {
      debugPrint('Windows scheduling worker failed: $error\n$stack');
      result = const PrayerScheduleResult(
        status: PrayerScheduleStatus.failed,
        message: PrayerScheduleResult.localFailureMessage,
      );
    } finally {
      if (gateway is VerifiedPrayerNotificationGateway) {
        try {
          await (gateway as VerifiedPrayerNotificationGateway)
              .releasePendingSnapshot();
        } catch (error) {
          debugPrint('Windows notification snapshot release deferred: $error');
        }
      }
    }
    request.reply.send({
      'operation': 'complete',
      'result': WindowsPrayerWorkerResult(result, {
        if (gateway is WindowsPrayerNotificationGateway) ...{
          'additions': gateway.additions,
          'cancellations': gateway.cancellations,
          'pendingQueries': gateway.pendingQueries,
        },
      }),
    });
  }
}

Future<void> _publishAfterUnlock(
  PrayerLocationRepository repository,
  SendPort root,
) async {
  final publication = await repository.synchronized((session) async {
    final state = session.state;
    if (!state.widgetPublicationPending ||
        state.journal != null ||
        state.activeLocation == null) {
      return null;
    }
    return <String, Object?>{
      'generation': state.activeLocation!,
      'scheduleRevision': state.scheduleRevision,
      'publicationRevision': state.widgetPublicationRevision,
      'configurationSignature': state.committedConfigurationSignature!,
    };
  });
  if (publication == null) return;
  var published = false;
  try {
    await _rpc(root, 'publish', publication);
    published = true;
  } catch (error) {
    debugPrint('Windows prayer publication deferred: $error');
  }
  await repository.synchronized((session) async {
    final state = session.state;
    if (state.widgetPublicationRevision != publication['publicationRevision'] ||
        state.scheduleRevision != publication['scheduleRevision'] ||
        state.activeLocation?.revision !=
            (publication['generation']! as PrayerLocationGeneration).revision ||
        state.committedConfigurationSignature !=
            publication['configurationSignature']) {
      return;
    }
    await session.save(
      state.copyWith(
        widgetPublicationPending: !published,
        displaySnapshot: state.displaySnapshot?.withIssues(
          {...state.displaySnapshot!.issues}
            ..removeAll(published ? {PrayerWorkflowIssue.widget} : {})
            ..addAll(published ? {} : {PrayerWorkflowIssue.widget}),
        ),
        workflowIssues: {...state.workflowIssues}
          ..removeAll(published ? {PrayerWorkflowIssue.widget} : {})
          ..addAll(published ? {} : {PrayerWorkflowIssue.widget}),
      ),
    );
    await session.repairProjections();
  });
}
