import 'package:flutter/material.dart';

/// Optimized list view with lazy loading and performance improvements
class OptimizedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget? separator;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final double cacheExtent;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.cacheExtent = 250.0,
  });

  @override
  _OptimizedListViewState<T> createState() => _OptimizedListViewState<T>();
}

class _OptimizedListViewState<T> extends State<OptimizedListView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        widget.hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    widget.onLoadMore?.call();

    // Reset loading state after a delay
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    Widget listView;

    if (widget.separator != null) {
      listView = ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        cacheExtent: widget.cacheExtent,
        itemCount: _getItemCount(),
        separatorBuilder: (context, index) => widget.separator!,
        itemBuilder: _buildItem,
      );
    } else {
      listView = ListView.builder(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        cacheExtent: widget.cacheExtent,
        itemCount: _getItemCount(),
        itemBuilder: _buildItem,
      );
    }

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        child: listView,
      );
    }

    return listView;
  }

  int _getItemCount() {
    var count = widget.items.length;
    if (widget.hasMore && widget.onLoadMore != null) {
      count += 1; // Add loading indicator
    }
    return count;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index >= widget.items.length) {
      // Loading more indicator
      return _buildLoadMoreIndicator();
    }

    return RepaintBoundary(
      child: widget.itemBuilder(context, widget.items[index], index),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized grid view with performance improvements
class OptimizedGridView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final SliverGridDelegate gridDelegate;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Widget? emptyWidget;
  final Widget? loadingWidget;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final double cacheExtent;

  const OptimizedGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.gridDelegate,
    this.padding,
    this.controller,
    this.shrinkWrap = false,
    this.physics,
    this.emptyWidget,
    this.loadingWidget,
    this.isLoading = false,
    this.onRefresh,
    this.onLoadMore,
    this.hasMore = false,
    this.cacheExtent = 250.0,
  });

  @override
  _OptimizedGridViewState<T> createState() => _OptimizedGridViewState<T>();
}

class _OptimizedGridViewState<T> extends State<OptimizedGridView<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    
    if (widget.onLoadMore != null) {
      _scrollController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        widget.hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    widget.onLoadMore?.call();

    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.items.isEmpty) {
      return widget.loadingWidget ?? _buildDefaultLoadingWidget();
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? _buildDefaultEmptyWidget();
    }

    final Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      gridDelegate: widget.gridDelegate,
      itemCount: _getItemCount(),
      itemBuilder: _buildItem,
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        child: gridView,
      );
    }

    return gridView;
  }

  int _getItemCount() {
    var count = widget.items.length;
    if (widget.hasMore && widget.onLoadMore != null) {
      count += 1;
    }
    return count;
  }

  Widget _buildItem(BuildContext context, int index) {
    if (index >= widget.items.length) {
      return _buildLoadMoreIndicator();
    }

    return RepaintBoundary(
      child: widget.itemBuilder(context, widget.items[index], index),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      alignment: Alignment.center,
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultLoadingWidget() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildDefaultEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grid_view_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No items found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
