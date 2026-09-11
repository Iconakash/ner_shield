import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/emergency/emergency_controller.dart';
import 'package:ner_shield/models/responder.dart';
import 'package:ner_shield/services/responder_service.dart';

class FakeResponderService implements ResponderService {
  FakeResponderService({
    this.responders,
    this.tasks,
    this.failOn = const <String>{},
  });
  List<Responder>? responders;
  List<ResponseTask>? tasks;
  Set<String> failOn;
  int transitionCalls = 0;
  String? lastTransitionStatus;
  String? lastTransitionTask;

  @override
  Future<List<Responder>> list({String? district, String? type}) async {
    if (failOn.contains('list')) {
      throw const NetworkException('list failed');
    }
    return responders ?? const <Responder>[];
  }

  @override
  Future<List<Responder>> nearest({
    required double lon,
    required double lat,
    int limit = 5,
  }) async {
    return (responders ?? const <Responder>[]).take(limit).toList();
  }

  @override
  Future<ResponseTask> notifyResponder(String responderId, {String? note}) async {
    return ResponseTask(
      id: 'rt-1',
      responderId: responderId,
      status: 'NOTIFIED',
    );
  }

  @override
  Future<List<ResponseTask>> myTasks() async {
    if (failOn.contains('myTasks')) {
      throw const NetworkException('myTasks failed');
    }
    return tasks ?? const <ResponseTask>[];
  }

  @override
  Future<ResponseTask> transition(
    String taskId, {
    required String status,
    String? note,
  }) async {
    transitionCalls += 1;
    lastTransitionTask = taskId;
    lastTransitionStatus = status;
    if (failOn.contains('transition')) {
      throw const NetworkException('transition failed');
    }
    return ResponseTask(id: taskId, status: status);
  }
}

void main() {
  group('Responder service + repository', () {
    test('list parses the roster', () async {
      final fake = FakeResponderService(responders: const <Responder>[
        Responder(
          id: 'r-1',
          name: 'Imphal Hospital',
          responderType: 'HEALTH_FACILITY',
          operationalStatus: 'STANDBY',
          contactMethod: 'PHONE',
        ),
      ]);
      final container = ProviderContainer(
        overrides: [responderServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result =
          await container.read(responderRepositoryProvider).list();
      expect(result.value, hasLength(1));
      expect(result.value.first.isAvailable, isTrue);
    });

    test('list failure surfaces AppException', () async {
      final fake = FakeResponderService(failOn: {'list'});
      final container = ProviderContainer(
        overrides: [responderServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      expect(
        () => container.read(responderRepositoryProvider).list(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('nearest returns live results (no caching)', () async {
      final fake = FakeResponderService(responders: const <Responder>[
        Responder(id: 'r-1', name: 'A'),
        Responder(id: 'r-2', name: 'B'),
      ]);
      final container = ProviderContainer(
        overrides: [responderServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final results = await container
          .read(responderRepositoryProvider)
          .nearest(lon: 91.78, lat: 26.14, limit: 1);
      expect(results, hasLength(1));
    });
  });

  group('ResponseTasksController', () {
    test('transition forwards to the service and reloads', () async {
      final fake = FakeResponderService(tasks: const <ResponseTask>[
        ResponseTask(id: 'rt-1', status: 'NOTIFIED', title: 'Aid drop'),
      ]);
      final container = ProviderContainer(
        overrides: [responderServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      await container.read(responseTasksProvider.future);
      final ok = await container
          .read(responseTasksProvider.notifier)
          .transition('rt-1', status: 'ACKNOWLEDGED');
      expect(ok, isTrue);
      expect(fake.transitionCalls, 1);
      expect(fake.lastTransitionStatus, 'ACKNOWLEDGED');
    });

    test('transition returns false on backend failure', () async {
      final fake = FakeResponderService(failOn: {'transition'});
      final container = ProviderContainer(
        overrides: [responderServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final ok = await container
          .read(responseTasksProvider.notifier)
          .transition('rt-1', status: 'CANCELLED');
      expect(ok, isFalse);
    });
  });

  group('responderNextStatusesFor', () {
    test('lists only valid next statuses', () {
      expect(responderNextStatusesFor('NOTIFIED'),
          containsAll(<String>['ACKNOWLEDGED', 'CANCELLED']));
      expect(responderNextStatusesFor('DISPATCHED'),
          containsAll(<String>['ON_SITE', 'CANCELLED']));
      expect(responderNextStatusesFor('RESOLVED'), isEmpty);
      expect(responderNextStatusesFor(null), isEmpty);
    });
  });

  group('responderStatusLabel', () {
    test('returns human label', () {
      expect(responderStatusLabel('NOTIFIED'), 'Notified');
      expect(responderStatusLabel('ON_SITE'), 'On site');
      expect(responderStatusLabel(null), 'Unknown');
    });
  });
}
