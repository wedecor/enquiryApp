/// Staff transition validator according to the locked graph.
bool canStaffTransition(String from, String to) {
  switch (from) {
    case 'new':
      return to == 'in_talks' || to == 'cancelled' || to == 'not_interested';
    case 'in_talks':
      return to == 'quotation_sent' ||
          to == 'confirmed' ||
          to == 'cancelled' ||
          to == 'not_interested';
    case 'quotation_sent':
      return to == 'confirmed' || to == 'in_talks' || to == 'cancelled' || to == 'not_interested';
    case 'confirmed':
      return to == 'completed' || to == 'cancelled';
    case 'completed':
      return false; // terminal state
    case 'cancelled':
      return false; // terminal state
    case 'not_interested':
      return false; // terminal state
    default:
      return false;
  }
}
