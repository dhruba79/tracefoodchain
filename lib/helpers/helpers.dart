import 'package:trace_foodchain_app/repositories/honduras_specifics.dart';

List<Map<String, dynamic>> getProcessingStates(String country) {
    if (country.toLowerCase() == 'honduras') {
      return coffeeProcessingStatesHonduras;
    }
    return [
      {
        "name": {"english": "cherry"},
        "weightCorrectionFactor": 0.1823
      },
      {
        "name": {"english": "dry parchment"},
        "weightCorrectionFactor": 0.8192
      },
      {
        "name": {"english": "green"},
        "weightCorrectionFactor": 1
      },
      {
        "name": {"english": "roasted"},
        "weightCorrectionFactor": 1
      },
      {
        "name": {"english": "ground roasted"},
        "weightCorrectionFactor": 1
      },
    ];
  }


    List<String> getQualityReductionCriteria(String country) {
    if (country.toLowerCase() == 'honduras') {
      return coffeeReducedQualityCriteria;
    }
    return [
      "too much fleshy pulp mixed with depulped coffee",
      "overly fermented",
      "strange color",
      "strange odor",
    ];
  }