import 'package:flutter_bloc/flutter_bloc.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class FilterState {
  final String? selectedSymbol;
  final String? selectedSignal;
  final int selectedHours;
  final String searchQuery;

  const FilterState({
    this.selectedSymbol,
    this.selectedSignal,
    this.selectedHours = 6,
    this.searchQuery = '',
  });

  FilterState copyWith({
    String? selectedSymbol,
    String? selectedSignal,
    int? selectedHours,
    String? searchQuery,
    bool clearSymbol = false,
    bool clearSignal = false,
  }) {
    return FilterState(
      selectedSymbol: clearSymbol ? null : selectedSymbol ?? this.selectedSymbol,
      selectedSignal: clearSignal ? null : selectedSignal ?? this.selectedSignal,
      selectedHours: selectedHours ?? this.selectedHours,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────
class FilterCubit extends Cubit<FilterState> {
  FilterCubit() : super(const FilterState());

  void setSymbol(String? symbol) =>
      emit(state.copyWith(selectedSymbol: symbol, clearSymbol: symbol == null));

  void setSignal(String? signal) =>
      emit(state.copyWith(selectedSignal: signal, clearSignal: signal == null));

  void setHours(int hours) => emit(state.copyWith(selectedHours: hours));

  void setSearchQuery(String query) =>
      emit(state.copyWith(searchQuery: query));

  void clearAll() => emit(const FilterState());
}