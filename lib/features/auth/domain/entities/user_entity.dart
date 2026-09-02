import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String name;
  final String roleId;
  final String pokjar;
  final String nrp;
  final String nosis;
  final String pangkat;
  final String angkatan;
  final String agama;
  final String jenisKelamin;
  final String jabatan;
  final String? tanggalLahir;
  final String? umur;
  final bool? isNakApproved;
  final String? profilePhoto;
  final String noSerdik;
  final String nik;
  final String jabatanSenat;
  final String tempatLahir;
  final String noHandphone;
  final String pendidikanTerakhir;
  final String alamatLengkap;
  final String email;
  final String noTelepon;
  final String kelompok;
  final String diktukAwal;
  final String tahunDiktuk;
  final String personel;
  final String satker;
  final String eselon;
  final String golongan;
  final double nilaiAkademik;
  final double nilaiMental;
  final double nilaiJasmani;
  final String? serdikId;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.roleId,
    required this.pokjar,
    required this.nrp,
    required this.nosis,
    required this.pangkat,
    required this.angkatan,
    required this.agama,
    required this.jenisKelamin,
    required this.jabatan,
    this.tanggalLahir,
    this.umur,
    this.isNakApproved,
    this.profilePhoto,
    required this.noSerdik,
    required this.nik,
    required this.jabatanSenat,
    required this.tempatLahir,
    required this.noHandphone,
    required this.pendidikanTerakhir,
    required this.alamatLengkap,
    required this.email,
    required this.noTelepon,
    required this.kelompok,
    required this.diktukAwal,
    required this.tahunDiktuk,
    required this.personel,
    required this.satker,
    required this.eselon,
    required this.golongan,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    this.serdikId,
  });

  String get displayUmur {
    if (umur != null && umur!.trim().isNotEmpty) return umur!;

    if (tanggalLahir != null) {
      try {
        final birthDate = DateTime.parse(tanggalLahir!);
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        return age.toString();
      } catch (_) {
        return '41';
      }
    }
    return '41';
  }

  String get displayJenisKelamin {
    final jk = jenisKelamin.trim().toLowerCase();
    if (jk == 'male' || jk == 'l' || jk == 'laki-laki' || jk == 'pria') {
      return 'Laki-laki';
    }
    if (jk == 'female' || jk == 'p' || jk == 'perempuan' || jk == 'wanita') {
      return 'Perempuan';
    }
    return jenisKelamin.isEmpty ? '-' : jenisKelamin;
  }

  String get displayGolongan {
    if (golongan != '-' && golongan.trim().isNotEmpty) {
      return golongan;
    }
    if (tanggalLahir != null && tanggalLahir!.isNotEmpty && tanggalLahir != '-') {
      try {
        final birthDate = DateTime.parse(tanggalLahir!);
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month ||
            (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        if (age <= 30) return 'GOL I';
        if (age <= 40) return 'GOL II';
        return 'GOL III';
      } catch (_) {
        return '-';
      }
    }
    return '-';
  }

  String get displayPersonel {
    final p = personel.trim().toUpperCase();
    if (p == 'TRUE' || p == '1' || p == 'YA' || p == 'YES') {
      return 'YA';
    }
    return 'TIDAK';
  }

  String get displayJabatanSenat {
    final j = jabatanSenat.trim();
    if (j.isEmpty || j == '-' || j.toUpperCase() == 'TIDAK ADA') {
      if (roleId == 'patun') return 'Perwira Penuntun';
      if (roleId == 'korsis') return 'Anggota Korsis';
      if (roleId == 'pimpinan') return 'Penanggung Jawab';
      return 'Tidak Ada';
    }
    return j;
  }

  UserEntity copyWith({
    String? userId,
    String? name,
    String? roleId,
    String? pokjar,
    String? nrp,
    String? nosis,
    String? pangkat,
    String? angkatan,
    String? agama,
    String? jenisKelamin,
    String? jabatan,
    String? tanggalLahir,
    String? umur,
    bool? isNakApproved,
    String? profilePhoto,
    bool clearProfilePhoto = false,
    String? noSerdik,
    String? nik,
    String? jabatanSenat,
    String? tempatLahir,
    String? noHandphone,
    String? pendidikanTerakhir,
    String? alamatLengkap,
    String? email,
    String? noTelepon,
    String? kelompok,
    String? diktukAwal,
    String? tahunDiktuk,
    String? personel,
    String? satker,
    String? eselon,
    String? golongan,
    double? nilaiAkademik,
    double? nilaiMental,
    double? nilaiJasmani,
    String? serdikId,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      roleId: roleId ?? this.roleId,
      pokjar: pokjar ?? this.pokjar,
      nrp: nrp ?? this.nrp,
      nosis: nosis ?? this.nosis,
      pangkat: pangkat ?? this.pangkat,
      angkatan: angkatan ?? this.angkatan,
      agama: agama ?? this.agama,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      jabatan: jabatan ?? this.jabatan,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      umur: umur ?? this.umur,
      isNakApproved: isNakApproved ?? this.isNakApproved,
      profilePhoto: clearProfilePhoto
          ? null
          : (profilePhoto ?? this.profilePhoto),
      noSerdik: noSerdik ?? this.noSerdik,
      nik: nik ?? this.nik,
      jabatanSenat: jabatanSenat ?? this.jabatanSenat,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      noHandphone: noHandphone ?? this.noHandphone,
      pendidikanTerakhir: pendidikanTerakhir ?? this.pendidikanTerakhir,
      alamatLengkap: alamatLengkap ?? this.alamatLengkap,
      email: email ?? this.email,
      noTelepon: noTelepon ?? this.noTelepon,
      kelompok: kelompok ?? this.kelompok,
      diktukAwal: diktukAwal ?? this.diktukAwal,
      tahunDiktuk: tahunDiktuk ?? this.tahunDiktuk,
      personel: personel ?? this.personel,
      satker: satker ?? this.satker,
      eselon: eselon ?? this.eselon,
      golongan: golongan ?? this.golongan,
      nilaiAkademik: nilaiAkademik ?? this.nilaiAkademik,
      nilaiMental: nilaiMental ?? this.nilaiMental,
      nilaiJasmani: nilaiJasmani ?? this.nilaiJasmani,
      serdikId: serdikId ?? this.serdikId,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    roleId,
    pokjar,
    nrp,
    nosis,
    pangkat,
    angkatan,
    agama,
    jenisKelamin,
    jabatan,
    tanggalLahir,
    umur,
    isNakApproved,
    profilePhoto,
    noSerdik,
    nik,
    jabatanSenat,
    tempatLahir,
    noHandphone,
    pendidikanTerakhir,
    alamatLengkap,
    email,
    noTelepon,
    kelompok,
    diktukAwal,
    tahunDiktuk,
    personel,
    satker,
    eselon,
    golongan,
    nilaiAkademik,
    nilaiMental,
    nilaiJasmani,
    serdikId,
  ];
}
