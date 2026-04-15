import 'package:go_router/go_router.dart';
import 'screens/main_shell.dart';
import 'screens/folder_view.dart';
import 'screens/composer_screen.dart';
import 'screens/search_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/demo_preview_screen.dart';
import 'screens/other_profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MainShell(),
      routes: [
        GoRoute(
          path: 'folder/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final name = state.uri.queryParameters['name'] ?? 'Folder';
            return FolderView(folderId: id, folderName: name);
          },
        ),
        GoRoute(
          path: 'compose',
          builder: (context, state) {
            final folderId = state.uri.queryParameters['folderId'] ?? state.uri.queryParameters['initialFolderId'];
            final postId = state.uri.queryParameters['postId'];
            final parentId = state.uri.queryParameters['parentId'];
            return ComposerScreen(initialFolderId: folderId, postId: postId, parentId: parentId);
          },
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: 'profile/view/:name',
          builder: (context, state) {
            final name = state.pathParameters['name']!;
            return OtherProfileScreen(authorName: name);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
