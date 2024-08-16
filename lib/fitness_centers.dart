class FitnessCenter {
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  FitnessCenter({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

final List<FitnessCenter> fitnessCenters = [
  FitnessCenter(
    name: 'McFit Neukölln',
    address: 'Tempelhofer Weg 91-99, 12347 Berlin',
    latitude: 52.4771,
    longitude: 13.4133,
  ),
  FitnessCenter(
    name: 'Holmes Place Neue Welt',
    address: 'Hasenheide 109, 10967 Berlin',
    latitude: 52.4893,
    longitude: 13.4246,
  ),
  FitnessCenter(
    name: 'Fit T9 Neukölln',
    address: 'Rollbergstraße 2-8, 12053 Berlin',
    latitude: 52.4771,
    longitude: 13.4321,
  ),
  FitnessCenter(
    name: 'Fit T9 Frauenfitness',
    address: 'Neckarstraße 24-26, 12053 Berlin',
    latitude: 52.4706,
    longitude: 13.4255,
  ),
  FitnessCenter(
    name: 'Flow Motion Studio',
    address: 'Glasower Str. 60, 12051 Berlin',
    latitude: 52.4838,
    longitude: 13.4433,
  ),
  FitnessCenter(
    name: 'American Fitness',
    address: 'Hermannplatz 10, 10967 Berlin',
    latitude: 52.4891,
    longitude: 13.4248,
  ),
  FitnessCenter(
    name: 'Gym80 Sportstudio',
    address: 'Lahnstraße 52, 12055 Berlin',
    latitude: 52.4876,
    longitude: 13.4600,
  ),
];
