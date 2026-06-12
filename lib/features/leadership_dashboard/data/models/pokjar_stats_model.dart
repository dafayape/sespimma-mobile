import 'package:equatable/equatable.dart';

class PokjarStatsModel extends Equatable {
  final String id;
  final String namaPokjar;
  final double rataRataNilai;

  const PokjarStatsModel({
    required this.id,
    required this.namaPokjar,
    required this.rataRataNilai,
  });

  factory PokjarStatsModel.fromJson(Map<String, dynamic> json) {
    return PokjarStatsModel(
      id: json['id'] as String? ?? '',
      namaPokjar: json['nama_pokjar'] as String? ?? '',
      rataRataNilai: (json['rata_rata_nilai'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_pokjar': namaPokjar,
      'rata_rata_nilai': rataRataNilai,
    };
  }

  PokjarStatsModel copyWith({
    String? id,
    String? namaPokjar,
    double? rataRataNilai,
  }) {
    return PokjarStatsModel(
      id: id ?? this.id,
      namaPokjar: namaPokjar ?? this.namaPokjar,
      rataRataNilai: rataRataNilai ?? this.rataRataNilai,
    );
  }

  @override
  List<Object?> get props => [id, namaPokjar, rataRataNilai];
}
