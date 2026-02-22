/// Infers building codes and standards from a US state name.
/// Data reflects typical state-level IBC/IECC adoption as of 2024-2025.
class CodeLookupService {
  CodeLookupService._();

  /// Returns inferred code entries for a US state.
  /// Each tuple: (label, value, confidence).
  static List<(String label, String value, double confidence)>
      inferCodesForState(String state) {
    final key = state.toLowerCase().trim();
    final results = <(String, String, double)>[];

    final ibc = _ibcByState[key];
    if (ibc != null) results.add(('Building Code', ibc, 0.6));

    final energy = _energyByState[key];
    if (energy != null) results.add(('Energy Code', energy, 0.6));

    final fire = _fireByState[key];
    if (fire != null) {
      results.add(('Fire Code', fire, 0.5));
    } else {
      results.add(('Fire Code', 'IFC (International Fire Code)', 0.4));
    }

    // ADA is federal — always applies
    final access = _accessByState[key];
    if (access != null) {
      results.add(('Accessibility', access, 0.8));
    } else {
      results.add(('Accessibility', 'ADA / ICC A117.1', 0.9));
    }

    return results;
  }

  static const _ibcByState = <String, String>{
    'alabama': 'IBC 2021',
    'alaska': 'IBC 2021',
    'arizona': 'IBC 2018',
    'arkansas': 'IBC 2021',
    'california': 'CBC 2022 (based on IBC 2021)',
    'colorado': 'IBC 2021',
    'connecticut': 'IBC 2021',
    'delaware': 'IBC 2018',
    'florida': 'FBC 8th Ed. (based on IBC 2021)',
    'georgia': 'IBC 2018 w/ GA Amendments',
    'idaho': 'IBC 2018',
    'illinois': 'IBC 2021',
    'indiana': 'IBC 2012',
    'iowa': 'IBC 2015',
    'kansas': 'IBC 2021',
    'kentucky': 'IBC 2018',
    'louisiana': 'IBC 2021',
    'maine': 'IBC 2021',
    'maryland': 'IBC 2021',
    'massachusetts': 'IBC 2021 (9th Ed. MA Amendments)',
    'michigan': 'IBC 2021 (MI Bldg Code)',
    'minnesota': 'IBC 2018 (MN State Bldg Code)',
    'mississippi': 'IBC 2021',
    'missouri': 'IBC 2018 (local adoption varies)',
    'montana': 'IBC 2021',
    'nebraska': 'IBC 2018',
    'nevada': 'IBC 2021',
    'new hampshire': 'IBC 2018',
    'new jersey': 'IBC 2021 (NJ UCC)',
    'new mexico': 'IBC 2021',
    'new york': 'IBC 2021 (NY State Bldg Code)',
    'north carolina': 'IBC 2018 (NC State Bldg Code)',
    'north dakota': 'IBC 2021',
    'ohio': 'IBC 2021 (OH Bldg Code)',
    'oklahoma': 'IBC 2021',
    'oregon': 'IBC 2021 (OR Structural Specialty)',
    'pennsylvania': 'IBC 2021 (PA UCC)',
    'rhode island': 'IBC 2021',
    'south carolina': 'IBC 2018',
    'south dakota': 'IBC 2021',
    'tennessee': 'IBC 2021',
    'texas': 'IBC 2021 (local adoption varies)',
    'utah': 'IBC 2021',
    'vermont': 'IBC 2021',
    'virginia': 'IBC 2021 (VA USBC)',
    'washington': 'IBC 2021 (WA State Bldg Code)',
    'west virginia': 'IBC 2021',
    'wisconsin': 'IBC 2018 (WI Commercial Code)',
    'wyoming': 'IBC 2018',
    // Abbreviated state codes
    'al': 'IBC 2021',
    'ar': 'IBC 2021',
    'az': 'IBC 2018',
    'ca': 'CBC 2022 (based on IBC 2021)',
    'co': 'IBC 2021',
    'ct': 'IBC 2021',
    'fl': 'FBC 8th Ed. (based on IBC 2021)',
    'ga': 'IBC 2018 w/ GA Amendments',
    'il': 'IBC 2021',
    'ky': 'IBC 2018',
    'la': 'IBC 2021',
    'ma': 'IBC 2021 (9th Ed. MA Amendments)',
    'md': 'IBC 2021',
    'mi': 'IBC 2021 (MI Bldg Code)',
    'mn': 'IBC 2018 (MN State Bldg Code)',
    'ms': 'IBC 2021',
    'mo': 'IBC 2018 (local adoption varies)',
    'nc': 'IBC 2018 (NC State Bldg Code)',
    'nj': 'IBC 2021 (NJ UCC)',
    'ny': 'IBC 2021 (NY State Bldg Code)',
    'oh': 'IBC 2021 (OH Bldg Code)',
    'ok': 'IBC 2021',
    'or': 'IBC 2021 (OR Structural Specialty)',
    'pa': 'IBC 2021 (PA UCC)',
    'sc': 'IBC 2018',
    'tn': 'IBC 2021',
    'tx': 'IBC 2021 (local adoption varies)',
    'va': 'IBC 2021 (VA USBC)',
    'wa': 'IBC 2021 (WA State Bldg Code)',
  };

  static const _energyByState = <String, String>{
    'alabama': 'IECC 2021',
    'arkansas': 'IECC 2009',
    'california': 'Title 24 Part 6 (2022)',
    'colorado': 'IECC 2021',
    'connecticut': 'IECC 2021',
    'florida': 'FBC Energy Conservation 8th Ed.',
    'georgia': 'IECC 2015 (GA Supplements)',
    'illinois': 'IECC 2021',
    'kentucky': 'IECC 2018',
    'louisiana': 'IECC 2021',
    'maryland': 'IECC 2021',
    'massachusetts': 'IECC 2021 (Stretch Code opt.)',
    'michigan': 'IECC 2015',
    'minnesota': 'MN Energy Code (based on IECC 2018)',
    'mississippi': 'IECC 2009',
    'new jersey': 'IECC 2021 (NJ)',
    'new york': 'ECCCNYS 2020 (based on IECC 2018)',
    'north carolina': 'IECC 2018 (NC Energy Code)',
    'ohio': 'IECC 2021',
    'oregon': 'OR Energy Efficiency Specialty Code 2021',
    'pennsylvania': 'IECC 2018',
    'south carolina': 'IECC 2009',
    'tennessee': 'IECC 2021',
    'texas': 'IECC 2021 (local adoption varies)',
    'virginia': 'IECC 2021 (VA USBC)',
    'washington': 'WA State Energy Code 2021',
    // Abbreviated
    'al': 'IECC 2021',
    'ar': 'IECC 2009',
    'ca': 'Title 24 Part 6 (2022)',
    'co': 'IECC 2021',
    'fl': 'FBC Energy Conservation 8th Ed.',
    'ga': 'IECC 2015 (GA Supplements)',
    'il': 'IECC 2021',
    'ky': 'IECC 2018',
    'md': 'IECC 2021',
    'ms': 'IECC 2009',
    'nc': 'IECC 2018 (NC Energy Code)',
    'oh': 'IECC 2021',
    'pa': 'IECC 2018',
    'sc': 'IECC 2009',
    'tn': 'IECC 2021',
    'tx': 'IECC 2021 (local adoption varies)',
    'va': 'IECC 2021 (VA USBC)',
  };

  static const _fireByState = <String, String>{
    'california': 'CFC 2022 (based on IFC 2021)',
    'florida': 'FBC Fire Prevention 8th Ed.',
    'new york': 'FC of NYS 2020',
    'texas': 'IFC 2021 (local adoption varies)',
    'tennessee': 'IFC 2021',
  };

  static const _accessByState = <String, String>{
    'california': 'ADA + CBC Chapter 11B',
    'texas': 'ADA + TAS (Texas Accessibility Standards)',
    'florida': 'ADA + FBC Accessibility',
    'new york': 'ADA + NYS Bldg Code Ch. 11',
    'massachusetts': 'ADA + 521 CMR (MA AAB)',
  };
}
