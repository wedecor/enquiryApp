/// Staff transition validator according to the locked graph.
bool canStaffTransition(String from, String to) {
  switch (from) {
    case 'new':
      return to == 'contacted' || to == 'cancelled';
    case 'contacted':
      return to == 'quoted' || to == 'cancelled';
    case 'quoted':
      return to == 'confirmed' || to == 'cancelled';
    case 'confirmed':
      return to == 'in_talks' || to == 'cancelled';
    case 'in_talks':
      return to == 'completed' || to == 'cancelled';
    default:
      return false; // completed/cancelled are terminal
  }
}


