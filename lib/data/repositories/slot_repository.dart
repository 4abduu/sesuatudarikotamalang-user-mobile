import '../../core/network/api_service.dart';
import '../../core/utils/date_only.dart';
import '../models/pickup_slot.dart';
import '../models/pickup_holidays_model.dart';

class SlotResult {
  const SlotResult({required this.slots, required this.leadMinutes});
  final List<PickupSlot> slots;
  final int leadMinutes;
}

class SlotRepository {
  SlotRepository(this._api);
  final ApiService _api;

  Future<SlotResult> getSlots(DateTime date, {int leadMinutes = 30}) async {
    final res = await _api.get('/slots', query: {'date': dateToApi(date)});
    final list = (res is Map && res['slots'] is List) ? res['slots'] as List : <dynamic>[];
    final lead = res is Map && res['leadMinutes'] is num
        ? (res['leadMinutes'] as num).toInt() : leadMinutes;
    return SlotResult(leadMinutes: lead, slots: list.whereType<Map>().map((e) =>
      PickupSlot.fromJson(Map<String, dynamic>.from(e), selectedDate: date, leadMinutes: lead)).toList());
  }

  Future<PickupHolidays> getHolidays(DateTime from, DateTime to) async {
    final res = await _api.get('/slots/holidays', query: {'from': dateToApi(from), 'to': dateToApi(to)});
    return res is Map<String, dynamic> ? PickupHolidays.fromJson(res) : PickupHolidays.empty;
  }
}
