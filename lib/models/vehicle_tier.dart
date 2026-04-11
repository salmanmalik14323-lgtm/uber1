enum VehicleTier {
  mini('Mini', 1.0),
  sedan('Sedan', 1.15),
  suv('SUV', 1.35);

  const VehicleTier(this.label, this.fareMultiplier);
  final String label;
  final double fareMultiplier;
}
