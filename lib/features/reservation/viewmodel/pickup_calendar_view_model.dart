import 'package:flutter/foundation.dart';
import '../../../core/utils/date_only.dart';
import '../../../data/models/pickup_holidays_model.dart';
import '../../../data/repositories/slot_repository.dart';

class PickupCalendarViewModel extends ChangeNotifier {
  PickupCalendarViewModel(this._repository);
  final SlotRepository _repository;
  PickupHolidays _holidays = PickupHolidays.empty;
  PickupHolidays get holidays => _holidays;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _disposed = false;
  int _requestId = 0;

  Future<void> load(DateTime first, DateTime last) async {
    final id = ++_requestId;
    _errorMessage = null;
    try {
      final loaded = await _repository.getHolidays(first, last);
      if (_disposed || id != _requestId) return;
      _holidays = loaded;
    } catch (e) {
      if (_disposed || id != _requestId) return;
      _holidays = PickupHolidays.empty;
      _errorMessage = e.toString();
    }
    if (!_disposed && id == _requestId) notifyListeners();
  }

  DateTime? nextOpenDate(DateTime from, DateTime first, DateTime last) {
    var date = dateOnly(from);
    while (!date.isAfter(dateOnly(last))) {
      if (!date.isBefore(dateOnly(first)) && _holidays.infoFor(date) == null) return date;
      date = date.add(const Duration(days: 1));
    }
    return null;
  }

  @override
  void dispose() { _disposed = true; ++_requestId; super.dispose(); }
}
