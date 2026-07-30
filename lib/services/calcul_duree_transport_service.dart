import '../models/profil_transport.dart';

class CalculDureeTransportService {
  const CalculDureeTransportService();

  EstimationDureeTransport calculer({
    required double dureeRoutiereMinutes,
    required int nombreArrets,
    required ProfilTransport profil,
    double congestion = 0,
  }) {
    if (dureeRoutiereMinutes < 0 || nombreArrets < 0) {
      throw ArgumentError(
          'La durée et le nombre d’arrêts doivent être positifs.');
    }
    final niveauCongestion = congestion.clamp(0, 1);
    final facteurCongestion =
        1 + (profil.facteurCongestionMax - 1) * niveauCongestion;
    final arrets = nombreArrets * profil.tempsParArretMinutes;
    return EstimationDureeTransport(
      minMinutes:
          dureeRoutiereMinutes * profil.facteurDureeMin * facteurCongestion +
              profil.attenteMinMinutes +
              arrets,
      maxMinutes:
          dureeRoutiereMinutes * profil.facteurDureeMax * facteurCongestion +
              profil.attenteMaxMinutes +
              arrets,
      profilValideTerrain: profil.valideTerrain,
    );
  }
}
