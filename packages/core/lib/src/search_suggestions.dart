import 'dart:async';

import 'chat_search.dart';

/// One account's empty global search. Failed requests retain the last data.
final class SearchSuggestionsState {
  const SearchSuggestionsState({
    this.recent = const [],
    this.top = const [],
    this.loading = false,
    this.mutating = false,
    this.recentFailed = false,
    this.topFailed = false,
    this.actionFailed = false,
  });

  final List<int> recent;
  final List<int> top;
  final bool loading;
  final bool mutating;
  final bool recentFailed;
  final bool topFailed;
  final bool actionFailed;
}

/// Own this alongside the account directory; dispose it on account replacement.
/// All mutations are acknowledged before changing the visible history. Loading
/// never writes metadata, and a busy load cannot accidentally clear history.
final class SearchSuggestionsController {
  SearchSuggestionsController(this._search);

  final ChatSearch _search;
  final _changes = StreamController<void>.broadcast(sync: true);
  Stream<void> get changes => _changes.stream;
  SearchSuggestionsState get state => _state;
  var _state = const SearchSuggestionsState();
  var _disposed = false;
  var _recentLoaded = false;

  void _set(SearchSuggestionsState state) {
    if (_disposed) return;
    _state = state;
    _changes.add(null);
  }

  Future<void> load() async {
    if (_disposed || state.loading || state.mutating) return;
    _set(
      SearchSuggestionsState(
        recent: state.recent,
        top: state.top,
        loading: true,
      ),
    );
    var recent = state.recent;
    var top = state.top;
    var recentFailed = false;
    var topFailed = false;
    await Future.wait([
      () async {
        try {
          recent = List.unmodifiable(await _search.recentChats());
          _recentLoaded = true;
        } catch (_) {
          recentFailed = true;
        }
      }(),
      () async {
        try {
          top = List.unmodifiable(await _search.topPeers());
        } catch (_) {
          topFailed = true;
        }
      }(),
    ]);
    _set(
      SearchSuggestionsState(
        recent: recent,
        top: top,
        recentFailed: recentFailed,
        topFailed: topFailed,
      ),
    );
  }

  Future<void> remove(int chatId) => _mutate(
    () => _search.removeRecentChat(chatId),
    () => state.recent.where((id) => id != chatId).toList(),
  );

  Future<void> clear() => _mutate(_search.clearRecentChats, () => []);

  Future<void> _mutate(
    Future<void> Function() operation,
    List<int> Function() result,
  ) async {
    if (_disposed || state.loading || state.mutating || !_recentLoaded) return;
    _set(
      SearchSuggestionsState(
        recent: state.recent,
        top: state.top,
        mutating: true,
        recentFailed: state.recentFailed,
        topFailed: state.topFailed,
      ),
    );
    var failed = false;
    try {
      await operation();
    } catch (_) {
      failed = true;
    }
    if (_disposed) return;
    _set(
      SearchSuggestionsState(
        recent: failed ? state.recent : List.unmodifiable(result()),
        top: state.top,
        recentFailed: state.recentFailed,
        topFailed: state.topFailed,
        actionFailed: failed,
      ),
    );
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_changes.close());
  }
}
