import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  @JsonKey(name: 'user_id')
  final String userId;

  final String name;

  @JsonKey(name: 'role_id')
  final String roleId;

  final String pokjar;

  final String nrp;
  @JsonKey(name: 'nosis', defaultValue: '-')
  final String nosis;
  final String pangkat;
  final String angkatan;
  final String agama;
  final String jabatan;

  @JsonKey(name: 'no_serdik', defaultValue: '-')
  final String noSerdik;

  @JsonKey(name: 'nik', defaultValue: '-')
  final String nik;

  @JsonKey(name: 'jabatan_senat', defaultValue: '-')
  final String jabatanSenat;

  @JsonKey(name: 'tempat_lahir', defaultValue: '-')
  final String tempatLahir;

  @JsonKey(name: 'no_handphone', defaultValue: '-')
  final String noHandphone;

  @JsonKey(name: 'pendidikan_terakhir', defaultValue: '-')
  final String pendidikanTerakhir;

  @JsonKey(name: 'alamat_lengkap', defaultValue: '-')
  final String alamatLengkap;

  @JsonKey(name: 'email', defaultValue: '-')
  final String email;

  @JsonKey(name: 'no_telepon', defaultValue: '-')
  final String noTelepon;

  @JsonKey(name: 'kelompok', defaultValue: '-')
  final String kelompok;

  @JsonKey(name: 'diktuk_awal', defaultValue: '-')
  final String diktukAwal;

  @JsonKey(name: 'tahun_diktuk', defaultValue: '-')
  final String tahunDiktuk;

  @JsonKey(name: 'personel', defaultValue: '-')
  final String personel;

  @JsonKey(name: 'satker', defaultValue: '-')
  final String satker;

  @JsonKey(name: 'tanggal_lahir', defaultValue: '1990-01-01')
  final String tanggalLahir;

  @JsonKey(name: 'eselon', defaultValue: '-')
  final String eselon;

  @JsonKey(name: 'golongan', defaultValue: '-')
  final String golongan;

  @JsonKey(name: 'is_nak_approved', defaultValue: false)
  final bool isNakApproved;

  @JsonKey(name: 'jenis_kelamin', defaultValue: '-')
  final String jenisKelamin;

  @JsonKey(name: 'nilai_akademik', defaultValue: 0.0)
  final double nilaiAkademik;

  @JsonKey(name: 'nilai_mental', defaultValue: 0.0)
  final double nilaiMental;

  @JsonKey(name: 'nilai_jasmani', defaultValue: 0.0)
  final double nilaiJasmani;

  @JsonKey(name: 'access_token')
  final String accessToken;

  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  const LoginResponse({
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
    required this.tanggalLahir,
    required this.eselon,
    required this.golongan,
    required this.isNakApproved,
    required this.nilaiAkademik,
    required this.nilaiMental,
    required this.nilaiJasmani,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
