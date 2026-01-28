import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/session_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/session_history_card_widget.dart';

class SessionHistory extends StatefulWidget {
  const SessionHistory({super.key});

  @override
  State<SessionHistory> createState() => _SessionHistoryState();
}

class _SessionHistoryState extends State<SessionHistory> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  List<Map<String, dynamic>> _allSessions = [];
  List<Map<String, dynamic>> _filteredSessions = [];
  String _searchQuery = '';
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadSessions();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreSessions();
    }
  }

  Future<void> _loadSessions() async {
    setState(() => _isLoading = true);

    try {
      final sessions = await SessionService.instance.getUserSessions(
        limit: 100,
        orderBy: 'created_at',
        ascending: false,
      );

      setState(() {
        _allSessions = sessions;
        _filteredSessions = sessions;
        _hasMore = sessions.length >= 100;
      });
    } catch (error) {
      print('Error loading sessions: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load sessions'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreSessions() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final lastSession = _allSessions.last;
      final lastDate = DateTime.parse(lastSession['created_at']).toLocal();

      final moreSessions = await SessionService.instance.getUserSessions(
        limit: 50,
        endDate: lastDate,
        orderBy: 'created_at',
        ascending: false,
      );

      setState(() {
        _allSessions.addAll(moreSessions);
        _applyFiltersAndSort();
        _hasMore = moreSessions.length >= 50;
      });
    } catch (error) {
      print('Error loading more sessions: $error');
    } finally {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await _loadSessions();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFiltersAndSort();
    });
  }

  void _onSortChanged(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _applyFiltersAndSort();
    });
  }

  void _applyFiltersAndSort() {
    var filtered = _allSessions.where((session) {
      if (_searchQuery.isEmpty) return true;

      final location = (session['location'] as String).toLowerCase();
      final notes = (session['notes'] as String? ?? '').toLowerCase();
      final date =
          DateTime.parse(session['created_at']).toLocal().toString().toLowerCase();
      final mood = (session['mood'] as String? ?? '').toLowerCase();
      final temperature =
          (session['temperature']?.toString() ?? '').toLowerCase();

      return location.contains(_searchQuery) ||
          notes.contains(_searchQuery) ||
          date.contains(_searchQuery) ||
          mood.contains(_searchQuery) ||
          temperature.contains(_searchQuery);
    }).toList();

    // Sort sessions
    switch (_sortBy) {
      case 'newest':
        filtered.sort(
          (a, b) => DateTime.parse(
            b['created_at'],
          ).toLocal().compareTo(DateTime.parse(a['created_at']).toLocal()),
        );
        );
        break;
      case 'oldest':
        filtered.sort(
          (a, b) => DateTime.parse(
            a['created_at'],
          ).toLocal().compareTo(DateTime.parse(b['created_at']).toLocal()),
        );
        );
        break;
      case 'duration':
        filtered.sort(
          (a, b) => (b['duration'] as int).compareTo(a['duration'] as int),
        );
        break;
      case 'temperature':
        filtered.sort(
          (a, b) =>
              (a['temperature'] as int).compareTo(b['temperature'] as int),
        );
        break;
    }

    setState(() {
      _filteredSessions = filtered;
    });
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sort By',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2.h),
                  _buildSortOption('Newest First', 'newest'),
                  _buildSortOption('Oldest First', 'oldest'),
                  _buildSortOption('Longest Duration', 'duration'),
                  _buildSortOption('Coldest Temperature', 'temperature'),
                  SizedBox(height: 2.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String title, String value) {
    final isSelected = _sortBy == value;

    return ListTile(
      title: Text(title),
      trailing: isSelected
          ? CustomIconWidget(
              iconName: 'check',
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        _onSortChanged(value);
      },
    );
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    // Temperature is already stored in Fahrenheit - no conversion needed
    final temperature = session['temperature'] as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 2.h),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 3.h),
                    _buildDetailRow(
                      'Location',
                      session['location'] as String,
                    ),
                    _buildDetailRow(
                      'Date',
                      _formatDetailDate(
                        DateTime.parse(session['created_at']).toLocal(),
                      ),
                    ),
                    _buildDetailRow(
                      'Duration',
                      '${session['duration']} seconds',
                    ),
                    _buildDetailRow(
                      'Temperature',
                      '$temperature°F',
                    ),
                    if (session['pre_mood'] != null)
                      _buildDetailRow(
                        'Pre-Mood',
                        session['pre_mood'] as String,
                      ),
                    if (session['post_mood'] != null)
                      _buildDetailRow(
                        'Post-Mood',
                        session['post_mood'] as String,
                      ),
                    if (session['notes'] != null &&
                        (session['notes'] as String).isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        'Notes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          session['notes'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 25.w,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDetailDate(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Future<void> _deleteSession(Map<String, dynamic> session) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Session'),
        content: Text(
          'Are you sure you want to delete this session from ${session['location']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorLight,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await SessionService.instance.deleteSession(session['id']);
        await _loadSessions(); // Refresh data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session deleted successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.successLight,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete session: $error'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.errorLight,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Session History',
        showBackButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'filter_list',
              color: colorScheme.onSurface,
              size: 24,
            ),
            onPressed: _showFilterMenu,
            tooltip: 'Sort & Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: EdgeInsets.all(4.w),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by location, mood, temp, date...',
                prefixIcon: CustomIconWidget(
                  iconName: 'search',
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.borderLight,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
            ),
          ),

          // Sessions list
          Expanded(
            child: RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: _handleRefresh,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surface,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: colorScheme.primary,
                      ),
                    )
                  : _filteredSessions.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.only(bottom: 2.h),
                          itemCount: _filteredSessions.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _filteredSessions.length) {
                              return Padding(
                                padding: EdgeInsets.all(2.h),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colorScheme.primary,
                                  ),
                                ),
                              );
                            }

                            final session = _filteredSessions[index];
                            return SessionHistoryCardWidget(
                              session: session,
                              onTap: () => _viewSessionDetails(session),
                              onDelete: () => _deleteSession(session),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'history',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 48,
          ),
          SizedBox(height: 2.h),
          Text(
            _searchQuery.isEmpty ? 'No Sessions Yet' : 'No Matching Sessions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isEmpty
                ? 'Your session history will appear here'
                : 'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
