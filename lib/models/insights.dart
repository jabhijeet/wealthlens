class PortfolioInsight {
  PortfolioInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.generatedAt,
    this.metadata,
    this.confidence = 0.8,
  });
  final String id;
  final String title;
  final String description;
  final String category; // allocation, risk, performance, opportunity, warning
  final DateTime generatedAt;
  final Map<String, dynamic>? metadata;
  final double confidence;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'generatedAt': generatedAt.toIso8601String(),
    'metadata': metadata,
    'confidence': confidence,
  };
}

class DetailedAnalysisState {
  DetailedAnalysisState({
    this.analysis = '',
    this.isGenerating = false,
    this.lastGenerated,
    this.error,
  });
  final String analysis;
  final bool isGenerating;
  final DateTime? lastGenerated;
  final String? error;

  DetailedAnalysisState copyWith({
    String? analysis,
    bool? isGenerating,
    DateTime? lastGenerated,
    String? error,
    bool clearError = false,
  }) {
    return DetailedAnalysisState(
      analysis: analysis ?? this.analysis,
      isGenerating: isGenerating ?? this.isGenerating,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
