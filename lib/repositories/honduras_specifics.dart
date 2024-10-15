List<Map<String, dynamic>> weightsHonduras = [
  {"name": "libras", "toKgFactor": 0.453592},
  {"name": "latas", "toKgFactor": 14.968536},
  {"name": "quintales", "toKgFactor": 45.3592},
  {"name": "cargas", "toKgFactor": 90.7184},
  {"name": "kg", "toKgFactor": 0.0},
  {"name": "t", "toKgFactor": 1000.0}
];

List<Map<String, dynamic>> coffeeProcessingStatesHonduras = [
  {
    "name": {"spanish": "uva", "english": "cherry"},
    "weightCorrectionFactor": 0.1823
  },
  {
    "name": {"spanish": "pergamino mojado", "english": "wet parchment"},
    "weightCorrectionFactor": 0.4185
  }, //Nasses Pergament
  {
    "name": {"spanish": "pergamino seco", "english": "dry parchment"},
    "weightCorrectionFactor": 0.8192
  }, //trockenes Pergament
  {
    "name": {"spanish": "oro", "english": "green"},
    "weightCorrectionFactor": 1
  }, //Grün
  {
    "name": {"spanish": "asada", "english": "roasted"},
    "weightCorrectionFactor": 1
  }, //geröstet
  {
    "name": {"spanish": "asada molido", "english": "ground roasted"},
    "weightCorrectionFactor": 1
  }, //geröstet gemahlen
];

List<String> coffeeReducedQualityCriteria = [
  "too much fleshy pulp mixed with depulped coffee",
  "overly fermented",
  "strange color",
  "strange odor"
];
