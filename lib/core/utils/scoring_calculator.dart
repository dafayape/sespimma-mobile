class ScoringCalculator {
  static double hitungNKKPatauNPKP({
    required double nmpn,
    required double npa,
    required double nka,
  }) {
    return ((nmpn * 35) + (npa * 35) + (nka * 30)) / 100;
  }

  static double hitungNKP({required double nmpn, required double npa}) {
    return ((nmpn * 50) + (npa * 50)) / 100;
  }

  static double hitungNP({
    required double nump,
    required double nkkp,
    required double npkp,
    required double nkp,
  }) {
    return ((nump * 30) + (nkkp * 5) + (npkp * 5) + (nkp * 60)) / 100;
  }

  static double hitungNSK({
    required double keaktifan,
    required double produk,
    required double tataRuang,
  }) {
    return ((keaktifan * 60) + (produk * 20) + (tataRuang * 20)) / 100;
  }

  static double hitungNT({
    required double nam,
    required double nkm,
    required double nkp,
  }) {
    return ((nam * 40) + (nkm * 30) + (nkp * 30)) / 100;
  }

  static double hitungNA({
    required double np,
    required double nsk,
    required double nt,
  }) {
    return ((np * 60) + (nsk * 10) + (nt * 30)) / 100;
  }

  static double hitungSosiometri({
    required double totalNilai,
    required int jumlahSerdikPeleton,
  }) {
    if (jumlahSerdikPeleton == 0) return 0.0;
    return totalNilai / jumlahSerdikPeleton;
  }

  static double hitungNKU({
    required double moral,
    required double disiplin,
    required double kepemimpinan,
    required double pengendalianDiri,
    required double penampilan,
  }) {
    return ((moral * 20) +
            (disiplin * 15) +
            (kepemimpinan * 20) +
            (pengendalianDiri * 15) +
            (penampilan * 15)) /
        85;
  }

  static double hitungNK({
    required double nilaiPengamatan,
    required double nilaiSosiometri,
  }) {
    return ((nilaiPengamatan * 7) + (nilaiSosiometri * 3)) / 10;
  }

  static double hitungNKes({
    required double tesAwal,
    required double tesAkhir,
    required double statusKesehatan,
  }) {
    return (tesAwal + tesAkhir + statusKesehatan) / 3;
  }

  static double hitungNGB({
    required double ngb1,
    required double ngb2,
    required double ngb3,
    required double ngb4,
  }) {
    return (ngb1 + ngb2 + ngb3 + ngb4) / 4;
  }

  static double hitungNJas({required double nga, required double ngb}) {
    return (nga + ngb) / 2;
  }

  static double hitungNKJ({required double nKes, required double nJas}) {
    return ((nKes * 4) + (nJas * 6)) / 10;
  }

  static double hitungNAK({
    required double na,
    required double nk,
    required double nkj,
  }) {
    return ((na * 70) + (nk * 20) + (nkj * 10)) / 100;
  }

  static Map<String, dynamic> dapatkanKlasifikasi({
    required double nak,
    required double na,
    required double nk,
    required double nkj,
  }) {
    bool isLulus = (na >= 70 && nk >= 70 && nkj >= 70);
    String status = isLulus ? 'LULUS' : 'TIDAK LULUS';

    String kode = '-';
    String klasifikasi = '-';
    String range = '-';

    if (nak >= 85.01) {
      kode = 'A';
      klasifikasi = 'SANGAT MEMUASKAN (SM)';
      range = '85.01 - 100';
    } else if (nak >= 80.01) {
      kode = 'B';
      klasifikasi = 'MEMUASKAN (M)';
      range = '80.01 - 85.00';
    } else if (nak >= 75.01) {
      kode = 'C';
      klasifikasi = 'BAIK (B)';
      range = '75.01 - 80.00';
    } else if (nak >= 70.00) {
      kode = 'D';
      klasifikasi = 'CUKUP (C)';
      range = '70.00 - 75.00';
    } else {
      kode = 'E';
      klasifikasi = 'KURANG (K)';
      range = '< 70.00';
    }

    if (!isLulus) {
      status = 'TIDAK LULUS (Nilai Bidang < 70)';
    }

    return {
      'nak': nak,
      'kode': kode,
      'klasifikasi': klasifikasi,
      'range': range,
      'status': status,
      'is_lulus': isLulus,
    };
  }
}
