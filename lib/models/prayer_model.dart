class CitySearch {
  final String id;
  final String lokasi;

  CitySearch({required this.id, required this.lokasi});

  factory CitySearch.fromJson(Map<String, dynamic> json) {
    return CitySearch(id: json['id'].toString(), lokasi: json['lokasi']);
  }
}

class PrayerSchedule {
  final String date;
  final String tanggal;
  final String lokasi;
  final String daerah;
  final String imsak;
  final String subuh;
  final String terbit;
  final String dhuha;
  final String dzuhur;
  final String ashar;
  final String maghrib;
  final String isya;

  PrayerSchedule({
    required this.date,
    required this.tanggal,
    required this.lokasi,
    required this.daerah,
    required this.imsak,
    required this.subuh,
    required this.terbit,
    required this.dhuha,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
  });

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final jadwal = data['jadwal'];

    return PrayerSchedule(
      date: jadwal['date'] ?? '',
      tanggal: jadwal['tanggal'] ?? '',
      lokasi: data['lokasi'] ?? '',
      daerah: data['daerah'] ?? '',
      imsak: jadwal['imsak'] ?? '',
      subuh: jadwal['subuh'] ?? '',
      terbit: jadwal['terbit'] ?? '',
      dhuha: jadwal['dhuha'] ?? '',
      dzuhur: jadwal['dzuhur'] ?? '',
      ashar: jadwal['ashar'] ?? '',
      maghrib: jadwal['maghrib'] ?? '',
      isya: jadwal['isya'] ?? '',
    );
  }
}

class HijriCalendar {
  final String dayName;
  final String hijriDate;
  final String gregorianDate;
  final List<int> numbers;

  HijriCalendar({
    required this.dayName,
    required this.hijriDate,
    required this.gregorianDate,
    required this.numbers,
  });

  factory HijriCalendar.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final dateArray = List<String>.from(data['date']);
    final numArray = List<int>.from(data['num']);

    return HijriCalendar(
      dayName: dateArray[0],
      hijriDate: dateArray[1],
      gregorianDate: dateArray[2],
      numbers: numArray,
    );
  }

  // Helper getters for easier access
  String get formattedHijriDate => hijriDate;
  String get formattedGregorianDate => gregorianDate;
  String get fullDate => '$dayName, $hijriDate';
}

class RandomDua {
  final String arab;
  final String indo;
  final String judul;
  final String source;

  RandomDua({
    required this.arab,
    required this.indo,
    required this.judul,
    required this.source,
  });

  factory RandomDua.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return RandomDua(
      arab: data['arab'] ?? '',
      indo: data['indo'] ?? '',
      judul: data['judul'] ?? '',
      source: data['source'] ?? '',
    );
  }
}

class RandomAsmaul {
  final String arab;
  final int id;
  final String indo;
  final String latin;

  RandomAsmaul({
    required this.arab,
    required this.id,
    required this.indo,
    required this.latin,
  });

  factory RandomAsmaul.fromJson(Map<String, dynamic> json) {
    final data = json['data'];

    return RandomAsmaul(
      arab: data['arab'] ?? '',
      id: data['id'] ?? 0,
      indo: data['indo'] ?? '',
      latin: data['latin'] ?? '',
    );
  }
}
