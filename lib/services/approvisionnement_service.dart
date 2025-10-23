// lib/services/approvisionnement_service.dart

import 'package:dio/dio.dart';
import 'package:supermarche/models/approvisionnement.dart';
import 'package:supermarche/utils/constants.dart';

class ApprovisionnementService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: API_BASE_URL,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  Future<List<Approvisionnement>> getHistoriqueApprovisionnements({
    DateTime? dateDebut,
    DateTime? dateFin,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (dateDebut != null) {
        queryParameters['date_debut'] = dateDebut.toIso8601String();
      }
      if (dateFin != null) {
        queryParameters['date_fin'] = dateFin.toIso8601String();
      }

      final response = await _dio.get(
        '/api/approvisionnements',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => Approvisionnement.fromJson(json))
            .toList();
      } else {
        throw Exception('Réponse API invalide');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else if (e.response?.statusCode == 400) {
        final error = e.response?.data?['error'] ?? 'Requête incorrecte';
        throw Exception('Erreur : $error');
      } else {
        throw Exception('Impossible de charger les approvisionnements. Vérifiez votre connexion.');
      }
    } catch (e) {
      rethrow;
    }
  }
}