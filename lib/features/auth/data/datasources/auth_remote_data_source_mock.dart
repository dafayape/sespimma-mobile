import '../models/login_request.dart';
import '../models/login_response.dart';
import 'auth_remote_data_source.dart';
import 'serdik_real_data.dart';
import 'patun_real_data.dart';
import 'korsis_real_data.dart';
import 'gadik_real_data.dart';
import 'medis_real_data.dart';
import 'operator_real_data.dart';
import 'pimpinan_real_data.dart';

class AuthRemoteDataSourceMock implements AuthRemoteDataSource {
  @override
  Future<LoginResponse> login(LoginRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    const String dummyPassword = 'password123';

    if (request.password != dummyPassword) {
      throw Exception('NRP atau Password salah!');
    }

    final serdikRecord = SerdikRealData.records
        .where((r) => r['nrp'] == request.nrp)
        .firstOrNull;

    if (serdikRecord != null) {
      return LoginResponse(
        userId: 'USR-${serdikRecord['nrp']}',
        name: serdikRecord['nama_lengkap'] ?? '-',
        roleId: 'siswa',
        pokjar: serdikRecord['kelompok_kelas'] ?? '-',
        nrp: serdikRecord['nrp'] ?? '-',
        nosis: serdikRecord['no_serdik'] ?? '-',
        pangkat: serdikRecord['pangkat'] ?? '-',
        angkatan: '75',
        agama: serdikRecord['agama'] ?? '-',
        jenisKelamin: serdikRecord['jenis_kelamin'] ?? '-',
        jabatan: serdikRecord['jabatan'] ?? '-',
        tanggalLahir: serdikRecord['tanggal_lahir'] ?? '1990-01-01',
        noSerdik: serdikRecord['no_serdik'] ?? '-',
        nik: serdikRecord['nik'] ?? '-',
        jabatanSenat: serdikRecord['jabatan_senat'] ?? '-',
        tempatLahir: serdikRecord['tempat_lahir'] ?? '-',
        noHandphone: serdikRecord['no_handphone'] ?? '-',
        pendidikanTerakhir: serdikRecord['pendidikan_terakhir'] ?? '-',
        alamatLengkap: serdikRecord['alamat'] ?? '-',
        email: serdikRecord['email'] ?? '-',
        noTelepon: serdikRecord['no_telepon'] ?? '-',
        kelompok: '-',
        diktukAwal: serdikRecord['diktuk_awal'] ?? '-',
        tahunDiktuk: serdikRecord['tahun_diktuk']?.toString() ?? '-',
        personel: (serdikRecord['is_personel'] == true) ? 'Ya' : 'Tidak',
        satker: serdikRecord['satker'] ?? '-',
        eselon: '-',
        golongan: '-',
        isNakApproved: true,
        nilaiAkademik: 82.5,
        nilaiMental: 85.0,
        nilaiJasmani: 78.0,
        accessToken: 'dummy_token_siswa',
        refreshToken: 'dummy_refresh_siswa',
      );
    }

    if (request.nrp == '99999999') {
      return LoginResponse(
        userId: 'USR-EWS',
        name: 'Serdik Dummy EWS',
        roleId: 'siswa',
        pokjar: 'POKJAR II',
        nrp: '99999999',
        nosis: '2026072090',
        pangkat: 'AKP',
        angkatan: 'KE-75',
        agama: 'Kristen',
        jenisKelamin: 'Laki-laki',
        jabatan: '-',
        tanggalLahir: '1990-07-20',
        noSerdik: 'SD-EWS',
        nik: '3201012345678902',
        jabatanSenat: '-',
        tempatLahir: 'Bandung',
        noHandphone: '081234567891',
        pendidikanTerakhir: 'S1 Teknik',
        alamatLengkap: 'Jl. Asia Afrika, Bandung',
        email: 'dummy_ews@example.com',
        noTelepon: '-',
        kelompok: 'B',
        diktukAwal: 'SIP',
        tahunDiktuk: '2010',
        personel: 'Ya',
        satker: 'Polrestabes Bandung',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 65.0,
        nilaiMental: 68.0,
        nilaiJasmani: 70.0,
        accessToken: 'dummy_token_siswa_ews',
        refreshToken: 'dummy_refresh_siswa_ews',
      );
    }

    final patunRecord = PatunRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (patunRecord != null) {
      return LoginResponse(
        userId: 'USR-${patunRecord['nrp_nip']}',
        name: patunRecord['nama'] ?? '-',
        roleId: 'patun',
        pokjar: patunRecord['pokjar'] ?? '-',
        nrp: patunRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: patunRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: '-',
        jenisKelamin: '-',
        jabatan: patunRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: patunRecord['peran_pengasuhan'] ?? '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Korsis Sespimma',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_patun_real',
        refreshToken: 'dummy_refresh_patun_real',
      );
    }

    if (request.nrp == '80101234') {
      return LoginResponse(
        userId: 'USR-002',
        name: 'KOMPOL Reza Mahendra, S.T., M.M.',
        roleId: 'gadik',
        pokjar: '-',
        nrp: '80101234',
        nosis: '2026101080',
        pangkat: 'KOMPOL',
        angkatan: '-',
        agama: 'Islam',
        jenisKelamin: 'Laki-laki',
        jabatan: 'KABAG JARLAT SESPIMMA',
        tanggalLahir: '1980-10-10',
        noSerdik: '-',
        nik: '3201012345678903',
        jabatanSenat: '-',
        tempatLahir: 'Surabaya',
        noHandphone: '081234567892',
        pendidikanTerakhir: 'S2 Manajemen',
        alamatLengkap: 'Jl. Pahlawan, Surabaya',
        email: 'reza@example.com',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Sespimma Polri',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_pengajar',
        refreshToken: 'dummy_refresh_pengajar',
      );
    }

    if (request.nrp == '80102222') {
      return LoginResponse(
        userId: 'USR-PATUN',
        name: 'KOMPOL Budi Prakoso, S.I.K., M.H.',
        roleId: 'patun',
        pokjar: '-',
        nrp: '80102222',
        nosis: '2026021480',
        pangkat: 'KOMPOL',
        angkatan: '-',
        agama: 'Islam',
        jenisKelamin: 'Laki-laki',
        jabatan: 'PATUN UTAMA SESPIMMA',
        tanggalLahir: '1980-02-14',
        noSerdik: '-',
        nik: '3201012345678904',
        jabatanSenat: '-',
        tempatLahir: 'Semarang',
        noHandphone: '081234567893',
        pendidikanTerakhir: 'S2 Hukum',
        alamatLengkap: 'Jl. Pemuda, Semarang',
        email: 'budi@example.com',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Sespimma Polri',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_patun',
        refreshToken: 'dummy_refresh_patun',
      );
    }

    if (request.nrp == '80103333') {
      return LoginResponse(
        userId: 'USR-MEDIS',
        name: 'dr. Siti Aminah, Sp.PD.',
        roleId: 'medis',
        pokjar: '-',
        nrp: '80103333',
        nosis: '2026040483',
        pangkat: 'PENATA TK.I',
        angkatan: '-',
        agama: 'Islam',
        jenisKelamin: 'Perempuan',
        jabatan: 'KA POLIKLINIK SESPIMMA',
        tanggalLahir: '1983-04-04',
        noSerdik: '-',
        nik: '3201012345678905',
        jabatanSenat: '-',
        tempatLahir: 'Medan',
        noHandphone: '081234567894',
        pendidikanTerakhir: 'Spesialis Penyakit Dalam',
        alamatLengkap: 'Jl. Sudirman, Medan',
        email: 'aminah@example.com',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Tidak',
        satker: 'Sespimma Polri',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_medis',
        refreshToken: 'dummy_refresh_medis',
      );
    }

    final pimpinanRecord = PimpinanRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (pimpinanRecord != null) {
      return LoginResponse(
        userId: 'USR-${pimpinanRecord['nrp_nip']}',
        name: pimpinanRecord['nama'] ?? '-',
        roleId: 'pimpinan',
        pokjar: '-',
        nrp: pimpinanRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: pimpinanRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: '-',
        jenisKelamin: '-',
        jabatan: pimpinanRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: pimpinanRecord['peran_pengasuhan'] ?? '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Sespim Lemdiklat Polri',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_pimpinan_real',
        refreshToken: 'dummy_refresh_pimpinan_real',
      );
    }

    final operatorRecord = OperatorRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (operatorRecord != null) {
      return LoginResponse(
        userId: 'USR-${operatorRecord['nrp_nip']}',
        name: operatorRecord['nama'] ?? '-',
        roleId: 'operator',
        pokjar: '-',
        nrp: operatorRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: operatorRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: '-',
        jenisKelamin: '-',
        jabatan: operatorRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: operatorRecord['peran_pengasuhan'] ?? '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: '-',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_operator_real',
        refreshToken: 'dummy_refresh_operator_real',
      );
    }

    final korsisRecord = KorsisRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (korsisRecord != null) {
      return LoginResponse(
        userId: 'USR-${korsisRecord['nrp_nip']}',
        name: korsisRecord['nama'] ?? '-',
        roleId: 'korsis',
        pokjar: '-',
        nrp: korsisRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: korsisRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: '-',
        jenisKelamin: '-',
        jabatan: korsisRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: korsisRecord['peran_pengasuhan'] ?? '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: '-',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_korsis_real',
        refreshToken: 'dummy_refresh_korsis_real',
      );
    }

    final gadikRecord = GadikRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (gadikRecord != null) {
      return LoginResponse(
        userId: 'USR-${gadikRecord['nrp_nip']}',
        name: gadikRecord['nama'] ?? '-',
        roleId: 'gadik',
        pokjar: '-',
        nrp: gadikRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: gadikRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: gadikRecord['agama'] ?? '-',
        jenisKelamin: '-',
        jabatan: gadikRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Sespimma',
        eselon: gadikRecord['eselon'] ?? '-',
        golongan: gadikRecord['golongan'] ?? '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_gadik_real',
        refreshToken: 'dummy_refresh_gadik_real',
      );
    }

    final medisRecord = MedisRealData.records
        .where((r) => r['nrp_nip'] == request.nrp)
        .firstOrNull;

    if (medisRecord != null) {
      return LoginResponse(
        userId: 'USR-${medisRecord['nrp_nip']}',
        name: medisRecord['nama'] ?? '-',
        roleId: 'medis',
        pokjar: '-',
        nrp: medisRecord['nrp_nip'] ?? '-',
        nosis: '-',
        pangkat: medisRecord['pangkat'] ?? '-',
        angkatan: '-',
        agama: '-',
        jenisKelamin: '-',
        jabatan: medisRecord['jabatan_struktural'] ?? '-',
        tanggalLahir: '-',
        noSerdik: '-',
        nik: '-',
        jabatanSenat: medisRecord['peran_pengasuhan'] ?? '-',
        tempatLahir: '-',
        noHandphone: '-',
        pendidikanTerakhir: '-',
        alamatLengkap: '-',
        email: '-',
        noTelepon: '-',
        kelompok: '-',
        diktukAwal: '-',
        tahunDiktuk: '-',
        personel: 'Ya',
        satker: 'Sespimma',
        eselon: '-',
        golongan: '-',
        isNakApproved: false,
        nilaiAkademik: 0.0,
        nilaiMental: 0.0,
        nilaiJasmani: 0.0,
        accessToken: 'dummy_token_medis_real',
        refreshToken: 'dummy_refresh_medis_real',
      );
    }

    throw Exception('NRP tidak ada di dalam database sistem');
  }
}
