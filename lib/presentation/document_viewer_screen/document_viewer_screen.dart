import '../../core/app_export.dart';

class DocumentViewerScreen extends StatefulWidget {
  final String documentId;
  final String? patientId;
  
  const DocumentViewerScreen({
    super.key,
    required this.documentId,
    this.patientId,
  });

  @override
  _DocumentViewerScreenState createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Document? _document;
  bool _isLoading = true;
  bool _showAnnotations = false;
  final List<Annotation> _annotations = [];

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate loading document
      await Future.delayed(Duration(milliseconds: 500));
      
      // Mock document data
      setState(() {
        _document = Document(
          id: widget.documentId,
          patientId: widget.patientId,
          name: 'Lab Results - Blood Work',
          type: 'Lab',
          category: 'Laboratory',
          fileUrl: 'https://example.com/document.pdf',
          fileSize: 2048576, // 2MB
          uploadDate: DateTime.now().subtract(Duration(days: 2)),
        );
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading document: $e');
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ),
      );
    }

    if (_document == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Document not found',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _document!.name,
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showAnnotations ? Icons.edit_off : Icons.edit,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showAnnotations = !_showAnnotations;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_in, color: Colors.white),
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: Icon(Icons.zoom_out, color: Colors.white),
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: Icon(Icons.share, color: Colors.white),
            onPressed: _shareDocument,
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'download', child: Text('Download')),
              PopupMenuItem(value: 'print', child: Text('Print')),
              PopupMenuItem(value: 'info', child: Text('Document Info')),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          // Document Viewer
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: _buildDocumentContent(),
            ),
          ),
          
          // Annotations Overlay
          if (_showAnnotations)
            ..._annotations.map(_buildAnnotation),
          
          // Document Info Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSlide(
              offset: _showAnnotations ? Offset.zero : Offset(0, 1),
              duration: Duration(milliseconds: 300),
              child: _buildDocumentInfoPanel(),
            ),
          ),
        ],
      ),
      floatingActionButton: _showAnnotations
          ? FloatingActionButton(
              onPressed: _addAnnotation,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.add_comment),
            )
          : null,
    );
  }

  Widget _buildDocumentContent() {
    // This would typically load the actual document content
    // For now, we'll show a placeholder
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Document Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'MEDICAL LABORATORY REPORT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'City General Hospital Laboratory',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Document Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocumentField('Patient Name:', 'John Smith'),
                  _buildDocumentField('MRN:', 'MRN001'),
                  _buildDocumentField('Date of Birth:', '03/15/1979'),
                  _buildDocumentField('Test Date:', '12/15/2024'),
                  
                  const SizedBox(height: 20),
                  
                  Text(
                    'LABORATORY RESULTS',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  _buildLabResult('Hemoglobin', '14.2 g/dL', '12.0-16.0', true),
                  _buildLabResult('White Blood Cells', '7.5 K/uL', '4.0-11.0', true),
                  _buildLabResult('Platelets', '250 K/uL', '150-450', true),
                  _buildLabResult('Glucose', '95 mg/dL', '70-100', true),
                  _buildLabResult('Cholesterol', '185 mg/dL', '<200', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabResult(String test, String value, String range, bool isNormal) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isNormal ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNormal ? Colors.green.shade200 : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              test,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isNormal ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              range,
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ),
          Icon(
            isNormal ? Icons.check_circle : Icons.warning,
            color: isNormal ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotation(Annotation annotation) {
    return Positioned(
      left: annotation.x,
      top: annotation.y,
      child: GestureDetector(
        onTap: () => _showAnnotationDialog(annotation),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.yellow.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange, width: 2),
          ),
          child: Icon(
            Icons.comment,
            size: 12,
            color: Colors.orange.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentInfoPanel() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Icon(
                _getDocumentIcon(_document!.type),
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _document!.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_document!.type} • ${_document!.formattedFileSize}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lab':
        return Icons.science;
      case 'image':
        return Icons.image;
      case 'prescription':
        return Icons.medication;
      case 'pdf':
        return Icons.picture_as_pdf;
      default:
        return Icons.description;
    }
  }

  void _zoomIn() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale < 4.0) {
      _transformationController.value = Matrix4.identity()..scale(currentScale * 1.2);
    }
  }

  void _zoomOut() {
    final currentScale = _transformationController.value.getMaxScaleOnAxis();
    if (currentScale > 0.5) {
      _transformationController.value = Matrix4.identity()..scale(currentScale * 0.8);
    }
  }

  void _shareDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document shared successfully'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'download':
        _downloadDocument();
        break;
      case 'print':
        _printDocument();
        break;
      case 'info':
        _showDocumentInfo();
        break;
    }
  }

  void _downloadDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document download started'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _printDocument() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Printing document...'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showDocumentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Document Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name:', _document!.name),
            _buildInfoRow('Type:', _document!.type),
            _buildInfoRow('Category:', _document!.category),
            _buildInfoRow('Size:', _document!.formattedFileSize),
            _buildInfoRow('Upload Date:', _formatDate(_document!.uploadDate)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addAnnotation() {
    final annotation = Annotation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      x: MediaQuery.of(context).size.width / 2,
      y: MediaQuery.of(context).size.height / 2,
      text: 'New annotation',
      timestamp: DateTime.now(),
    );

    setState(() {
      _annotations.add(annotation);
    });

    _showAnnotationDialog(annotation);
  }

  void _showAnnotationDialog(Annotation annotation) {
    final textController = TextEditingController(text: annotation.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Annotation'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter annotation text...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                annotation.text = textController.text;
              });
              Navigator.pop(context);
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Annotation model
class Annotation {
  final String id;
  double x;
  double y;
  String text;
  final DateTime timestamp;

  Annotation({
    required this.id,
    required this.x,
    required this.y,
    required this.text,
    required this.timestamp,
  });
}
