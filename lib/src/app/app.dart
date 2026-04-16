import 'package:flutter/material.dart';

import '../core/network/dio_client.dart';
import '../features/board/data/board_api.dart';
import '../features/board/data/board_repository.dart';
import '../features/board/presentation/board_page.dart';
import '../shared/theme/app_theme.dart';

class KpiDriveKanbanApp extends StatelessWidget {
  const KpiDriveKanbanApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = BoardRepository(
      api: BoardApi(dio: DioClient().dio),
    );

    return MaterialApp(
      title: 'KPI Drive Kanban',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: BoardPage(repository: repository),
    );
  }
}
