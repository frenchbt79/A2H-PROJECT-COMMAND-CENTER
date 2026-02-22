/// Enriches project info with city/jurisdiction-specific building requirements.
///
/// Architecture:
/// - Pure static class — no state, no I/O
/// - Takes (city, state) → returns enrichment entries
/// - Integrates via `ProjectInfoNotifier.upsertByLabel()` with source='inferred'
/// - Works alongside CodeLookupService (state-level) to add city-level detail
class JurisdictionEnricher {
  JurisdictionEnricher._();

  /// Returns inferred jurisdiction entries for a city/state pair.
  /// Each tuple: (category, label, value, confidence).
  static List<JurisdictionEntry> enrich(String city, String state) {
    final results = <JurisdictionEntry>[];
    final cityKey = city.toLowerCase().trim();
    final stateKey = state.toLowerCase().trim();

    // Look up city-specific rules
    final cityRules = _cityRules['$cityKey, $stateKey'] ?? _cityRules[cityKey];
    if (cityRules != null) {
      results.addAll(cityRules);
    }

    // Add county/regional rules if applicable
    final regionalRules = _regionalRules[stateKey];
    if (regionalRules != null) {
      results.addAll(regionalRules);
    }

    return results;
  }

  /// Check if we have jurisdiction data for a given city/state.
  static bool hasData(String city, String state) {
    final cityKey = city.toLowerCase().trim();
    final stateKey = state.toLowerCase().trim();
    return _cityRules.containsKey('$cityKey, $stateKey') ||
           _cityRules.containsKey(cityKey) ||
           _regionalRules.containsKey(stateKey);
  }
  // ═══════════════════════════════════════════════════════════
  // CITY-SPECIFIC RULES DATABASE
  // ═══════════════════════════════════════════════════════════

  static const _cityRules = <String, List<JurisdictionEntry>>{
    // ── Connecticut ──
    'new haven, connecticut': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of New Haven Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'New Haven Building Official', 0.7),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'City Plan Commission', 0.65),
      JurisdictionEntry('Jurisdiction', 'Historic Review', 'New Haven Historic District Commission (if applicable)', 0.5),
      JurisdictionEntry('Jurisdiction', 'Fire Marshal', 'New Haven Fire Marshal', 0.7),
    ],
    'hartford, connecticut': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Hartford Dept of Development Services', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Hartford Building Official', 0.7),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'Hartford Planning & Zoning Commission', 0.65),
    ],
    'stamford, connecticut': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Stamford Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Stamford Building Official', 0.7),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'Stamford Zoning Board', 0.65),
    ],
    'bridgeport, connecticut': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Bridgeport Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Bridgeport Building Official', 0.7),
    ],
    'waterbury, connecticut': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Waterbury Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Waterbury Building Official', 0.7),
    ],
    // ── New York ──
    'new york, new york': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'NYC Dept of Buildings (DOB)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'NYC DOB — Borough Office', 0.9),
      JurisdictionEntry('Jurisdiction', 'Code Override', 'NYC Building Code (overrides NYS)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'NYC Dept of City Planning', 0.85),
      JurisdictionEntry('Jurisdiction', 'Landmarks Review', 'NYC Landmarks Preservation Commission (if applicable)', 0.6),
      JurisdictionEntry('Jurisdiction', 'Fire Marshal', 'FDNY Bureau of Fire Prevention', 0.9),
      JurisdictionEntry('Codes & Standards', 'Building Code', 'NYC Building Code 2022 (not IBC)', 0.9),
      JurisdictionEntry('Codes & Standards', 'Energy Code', 'NYC Energy Conservation Code (NYCECC)', 0.9),
    ],
    'yonkers, new york': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Yonkers Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Yonkers Building Inspector', 0.7),
    ],
    'white plains, new york': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of White Plains Building Department', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'White Plains Building Inspector', 0.7),
    ],
    // ── New Jersey ──
    'newark, new jersey': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Newark Division of Construction Codes', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Newark Construction Official', 0.7),
    ],
    'jersey city, new jersey': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Jersey City Division of Construction Code', 0.7),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Jersey City Construction Official', 0.7),
    ],
    // ── Massachusetts ──
    'boston, massachusetts': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Boston Inspectional Services Dept (ISD)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Boston Building Commissioner', 0.9),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'Boston Planning & Development Agency (BPDA)', 0.85),
      JurisdictionEntry('Jurisdiction', 'Historic Review', 'Boston Landmarks Commission (if applicable)', 0.6),
      JurisdictionEntry('Codes & Standards', 'Energy Code', 'MA Stretch Code (mandatory in Boston)', 0.85),
    ],
    // ── Pennsylvania ──
    'philadelphia, pennsylvania': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Philadelphia Dept of Licenses & Inspections (L&I)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Philadelphia L&I', 0.9),
      JurisdictionEntry('Jurisdiction', 'Code Override', 'Philadelphia Building Code (local amendments to PA UCC)', 0.8),
      JurisdictionEntry('Jurisdiction', 'Zoning Authority', 'Philadelphia City Planning Commission', 0.85),
      JurisdictionEntry('Jurisdiction', 'Historic Review', 'Philadelphia Historical Commission (if applicable)', 0.6),
    ],    // ── California ──
    'los angeles, california': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'LA Dept of Building & Safety (LADBS)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'LADBS Plan Check', 0.9),
      JurisdictionEntry('Jurisdiction', 'Code Override', 'City of LA Building Code (LABC)', 0.85),
      JurisdictionEntry('Jurisdiction', 'Seismic Zone', 'ASCE 7 Risk Category per LADBS', 0.8),
    ],
    'san francisco, california': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'SF Dept of Building Inspection (DBI)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'SF DBI Plan Review', 0.9),
      JurisdictionEntry('Jurisdiction', 'Code Override', 'SF Building Code (SFBC)', 0.85),
    ],
    // ── Illinois ──
    'chicago, illinois': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Chicago Dept of Buildings (DOB)', 0.9),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Chicago DOB Plan Review', 0.9),
      JurisdictionEntry('Jurisdiction', 'Code Override', 'Chicago Building Code (not IBC — Chicago Municipal Code Ch. 14A-14X)', 0.9),
      JurisdictionEntry('Codes & Standards', 'Building Code', 'Chicago Building Code (Municipal Code)', 0.9),
    ],
    // ── Texas ──
    'houston, texas': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Houston Public Works — Building Code Enforcement', 0.8),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Houston Building Official', 0.8),
      JurisdictionEntry('Jurisdiction', 'Zoning Note', 'Houston has no zoning — deed restrictions apply', 0.9),
    ],
    'dallas, texas': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Dallas Building Inspection Division', 0.8),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Dallas Building Official', 0.8),
    ],
    'austin, texas': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'Austin Development Services Dept', 0.8),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Austin Building Official', 0.8),
    ],
    // ── Florida ──
    'miami, florida': [
      JurisdictionEntry('Jurisdiction', 'Building Dept', 'City of Miami Building Department', 0.8),
      JurisdictionEntry('Jurisdiction', 'Permit Authority', 'Miami Building Official', 0.8),
      JurisdictionEntry('Jurisdiction', 'Wind Zone', 'HVHZ (High-Velocity Hurricane Zone)', 0.9),
    ],
  };

  // ═══════════════════════════════════════════════════════════
  // REGIONAL/STATE-LEVEL SUPPLEMENTAL RULES
  // ═══════════════════════════════════════════════════════════

  static const _regionalRules = <String, List<JurisdictionEntry>>{
    'connecticut': [
      JurisdictionEntry('Jurisdiction', 'State Agency', 'CT Dept of Administrative Services — Office of State Building Inspector', 0.6),
      JurisdictionEntry('Jurisdiction', 'Permit Process', 'Local Building Official issues permits (home rule state)', 0.5),
    ],
    'new york': [
      JurisdictionEntry('Jurisdiction', 'State Agency', 'NYS Dept of State — Division of Building Standards and Codes', 0.6),
    ],
    'new jersey': [
      JurisdictionEntry('Jurisdiction', 'State Agency', 'NJ DCA — Division of Codes and Standards', 0.6),
      JurisdictionEntry('Jurisdiction', 'Permit Process', 'Local Construction Official (NJ UCC)', 0.5),
    ],
    'california': [
      JurisdictionEntry('Jurisdiction', 'State Agency', 'CA Building Standards Commission', 0.6),
      JurisdictionEntry('Jurisdiction', 'Seismic Design', 'CBC Chapter 16 — Seismic Design per ASCE 7', 0.7),
    ],
    'florida': [
      JurisdictionEntry('Jurisdiction', 'State Agency', 'FL Building Commission', 0.6),
      JurisdictionEntry('Jurisdiction', 'Wind Design', 'FBC Wind Design per ASCE 7 — check HVHZ applicability', 0.7),
    ],
    'texas': [
      JurisdictionEntry('Jurisdiction', 'Permit Process', 'Local jurisdiction — no statewide building code mandate', 0.6),
    ],
  };
}

/// A single jurisdiction enrichment entry.
class JurisdictionEntry {
  final String category;
  final String label;
  final String value;
  final double confidence;

  const JurisdictionEntry(this.category, this.label, this.value, this.confidence);
}
