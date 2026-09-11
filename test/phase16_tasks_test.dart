import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ner_shield/app/providers.dart';
import 'package:ner_shield/core/errors/app_exception.dart';
import 'package:ner_shield/features/tasks/tasks_controller.dart';
import 'package:ner_shield/models/task.dart';
import 'package:ner_shield/services/tasks_service.dart';

class FakeTasksService implements TasksService {
  FakeTasksService({
    this.tasks,
    this.scenes,
    this.failOn = const <String>{},
  });
  List<TaskItem>? tasks;
  List<SatelliteEvidence>? scenes;
  Set<String> failOn;
  int transitionCalls = 0;

  @override
  Future<List<TaskItem>> mine() async {
    if (failOn.contains('mine')) throw const NetworkException('mine failed');
    return tasks ?? const <TaskItem>[];
  }

  @override
  Future<TaskItem> detail(String taskId) async {
    return TaskItem(id: taskId, status: 'IN_PROGRESS');
  }

  @override
  Future<TaskItem> transition(
    String taskId, {
    required String toStatus,
    String? note,
  }) async {
    transitionCalls += 1;
    if (failOn.contains('transition')) {
      throw const NetworkException('transition failed');
    }
    return TaskItem(id: taskId, status: toStatus);
  }

  @override
  Future<FieldMedia> fieldMediaSignedUrl({
    required String reportId,
    required String mediaId,
  }) async {
    return FieldMedia(
      id: mediaId,
      signedUrl: 'https://example.com/$mediaId',
      signedUrlExpiresAt: '2026-09-03T01:00:00Z',
    );
  }

  @override
  Future<List<SatelliteEvidence>> satelliteScenes({
    String? stateCode,
    String? districtCode,
  }) async {
    return scenes ?? const <SatelliteEvidence>[];
  }
}

void main() {
  group('Tasks service + repository', () {
    test('mine parses the payload', () async {
      final fake = FakeTasksService(tasks: const <TaskItem>[
        TaskItem(
          id: 't-1',
          title: 'Verify road blockage',
          status: 'ASSIGNED',
          priority: 'HIGH',
        ),
      ]);
      final container = ProviderContainer(
        overrides: [tasksServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final result = await container.read(tasksRepositoryProvider).mine();
      expect(result.value, hasLength(1));
      expect(result.value.first.isOpen, isTrue);
      expect(result.value.first.isHighPriority, isTrue);
    });

    test('mine failure surfaces AppException', () async {
      final fake = FakeTasksService(failOn: {'mine'});
      final container = ProviderContainer(
        overrides: [tasksServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      expect(
        () => container.read(tasksRepositoryProvider).mine(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('mediaSignedUrl is always live', () async {
      final fake = FakeTasksService();
      final container = ProviderContainer(
        overrides: [tasksServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final media = await container
          .read(tasksRepositoryProvider)
          .mediaSignedUrl(reportId: 'fr-1', mediaId: 'm-1');
      expect(media.signedUrl, contains('m-1'));
    });
  });

  group('MyTasksController', () {
    test('transition forwards and reloads', () async {
      final fake = FakeTasksService(tasks: const <TaskItem>[
        TaskItem(id: 't-1', status: 'ASSIGNED'),
      ]);
      final container = ProviderContainer(
        overrides: [tasksServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      await container.read(myTasksProvider.future);
      final ok = await container
          .read(myTasksProvider.notifier)
          .transition('t-1', toStatus: 'ACCEPTED');
      expect(ok, isTrue);
      expect(fake.transitionCalls, 1);
    });

    test('transition returns false on backend failure', () async {
      final fake = FakeTasksService(failOn: {'transition'});
      final container = ProviderContainer(
        overrides: [tasksServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);
      final ok = await container
          .read(myTasksProvider.notifier)
          .transition('t-1', toStatus: 'COMPLETED');
      expect(ok, isFalse);
    });
  });

  group('taskNextStatusesFor', () {
    test('lists only valid next statuses', () {
      expect(taskNextStatusesFor('ASSIGNED'),
          containsAll(<String>['ACCEPTED', 'CANCELLED']));
      expect(taskNextStatusesFor('IN_PROGRESS'),
          containsAll(<String>['BLOCKED', 'COMPLETED', 'CANCELLED']));
      expect(taskNextStatusesFor('COMPLETED'),
        containsAll(<String>['VERIFIED', 'CANCELLED']));
      expect(taskNextStatusesFor(null), isEmpty);
    });
  });
}
