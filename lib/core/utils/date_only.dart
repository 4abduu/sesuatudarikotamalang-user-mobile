DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String dateToApi(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
