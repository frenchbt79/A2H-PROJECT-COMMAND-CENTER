import 'package:flutter/material.dart';
import '../models/project_models.dart';

/// Default seed data for first-run experience.
/// Used when no persisted data exists in storage.
class DefaultData {
  DefaultData._();

  static final team = <TeamMember>[
    TeamMember(id: '1', name: 'Sarah Chen', role: 'Project Manager', company: 'A2H', email: 'schen@a2harchitects.com', phone: '(210) 555-2001', avatarColor: const Color(0xFF4FC3F7)),
    TeamMember(id: '2', name: 'James Rivera', role: 'Lead Architect', company: 'A2H', email: 'jrivera@a2harchitects.com', phone: '(210) 555-2002', avatarColor: const Color(0xFF81C784)),
    TeamMember(id: '3', name: 'Emily Nguyen', role: 'Structural Engineer', company: 'Thornton Tomasetti', email: 'enguyen@thorntontomasetti.com', phone: '(210) 555-3001', avatarColor: const Color(0xFFFFB74D)),
    TeamMember(id: '4', name: 'Michael Torres', role: 'MEP Coordinator', company: 'WSP', email: 'mtorres@wsp.com', phone: '(210) 555-4001', avatarColor: const Color(0xFFE57373)),
    TeamMember(id: '5', name: 'David Park', role: 'Civil Engineer', company: 'Kimley-Horn', email: 'dpark@kimley-horn.com', phone: '(210) 555-5001', avatarColor: const Color(0xFFBA68C8)),
    TeamMember(id: '6', name: 'Lisa Martinez', role: 'Landscape Architect', company: 'TBG Partners', email: 'lmartinez@tbg-inc.com', phone: '(210) 555-6001', avatarColor: const Color(0xFF4DB6AC)),
    TeamMember(id: '7', name: 'Robert Kim', role: 'Owner Representative', company: 'Baptist Health System', email: 'rkim@baptisthealthsystem.com', phone: '(210) 555-7001', avatarColor: const Color(0xFF7986CB)),
    TeamMember(id: '8', name: 'Amanda Foster', role: 'Interior Designer', company: 'A2H', email: 'afoster@a2harchitects.com', phone: '(210) 555-2003', avatarColor: const Color(0xFFF06292)),
  ];

  static final contracts = <ContractItem>[
    ContractItem(id: 'c1', title: 'Original A/E Services Agreement \u2014 Baptist Micro Hospital', type: 'Original', amount: 3200000, status: 'Executed', date: DateTime(2024, 5, 15)),
    ContractItem(id: 'c2', title: 'Amendment 01 \u2014 Expanded Imaging Suite Scope', type: 'Amendment', amount: 245000, status: 'Executed', date: DateTime(2024, 9, 10)),
    ContractItem(id: 'c3', title: 'Amendment 02 \u2014 Additional OR Suite Design', type: 'Amendment', amount: 185000, status: 'Executed', date: DateTime(2025, 1, 22)),
    ContractItem(id: 'c4', title: 'CO-001 \u2014 Foundation Redesign per Geotechnical', type: 'Change Order', amount: 92000, status: 'Pending', date: DateTime(2025, 8, 8)),
    ContractItem(id: 'c5', title: 'CO-002 \u2014 HVAC Isolation Room Modifications', type: 'Change Order', amount: 67000, status: 'Draft', date: DateTime(2025, 10, 3)),
  ];

  static final schedule = <SchedulePhase>[
    SchedulePhase(id: 's1', name: 'Schematic Design', start: DateTime(2024, 5, 1), end: DateTime(2024, 9, 15), progress: 1.0, status: 'Complete'),
    SchedulePhase(id: 's2', name: 'Design Development', start: DateTime(2024, 8, 1), end: DateTime(2025, 2, 28), progress: 1.0, status: 'Complete'),
    SchedulePhase(id: 's3', name: 'Construction Documents', start: DateTime(2025, 1, 15), end: DateTime(2025, 9, 30), progress: 0.65, status: 'In Progress'),
    SchedulePhase(id: 's4', name: 'Permitting', start: DateTime(2025, 7, 1), end: DateTime(2025, 11, 30), progress: 0.10, status: 'In Progress'),
    SchedulePhase(id: 's5', name: 'Bidding & Negotiation', start: DateTime(2025, 10, 1), end: DateTime(2026, 1, 31), progress: 0.0, status: 'Upcoming'),
    SchedulePhase(id: 's6', name: 'Construction Admin', start: DateTime(2026, 2, 1), end: DateTime(2027, 8, 31), progress: 0.0, status: 'Upcoming'),
  ];

  static final budget = <BudgetLine>[
    BudgetLine(id: 'b1', category: 'Architecture', budgeted: 1500000, spent: 920000, committed: 340000),
    BudgetLine(id: 'b2', category: 'Structural', budgeted: 420000, spent: 280000, committed: 95000),
    BudgetLine(id: 'b3', category: 'MEP Engineering', budgeted: 680000, spent: 385000, committed: 195000),
    BudgetLine(id: 'b4', category: 'Civil / Site', budgeted: 310000, spent: 195000, committed: 72000),
    BudgetLine(id: 'b5', category: 'Landscape', budgeted: 145000, spent: 58000, committed: 42000),
    BudgetLine(id: 'b6', category: 'Interior Design', budgeted: 390000, spent: 156000, committed: 117000),
    BudgetLine(id: 'b7', category: 'Medical Equipment Planning', budgeted: 280000, spent: 112000, committed: 84000),
    BudgetLine(id: 'b8', category: 'Consultants / Other', budgeted: 175000, spent: 52000, committed: 65000),
  ];

  static final todos = <TodoItem>[
    TodoItem(id: 't1', text: 'Review ED department layout comments', assignee: 'Sarah Chen', dueDate: DateTime(2025, 10, 18)),
    TodoItem(id: 't2', text: 'Update civil grading plan for detention', done: true, assignee: 'David Park', dueDate: DateTime(2025, 10, 14)),
    TodoItem(id: 't3', text: 'Coordinate MEP medical gas routing', assignee: 'Michael Torres', dueDate: DateTime(2025, 10, 20)),
    TodoItem(id: 't4', text: 'Submit landscape irrigation revisions', assignee: 'Lisa Martinez', dueDate: DateTime(2025, 10, 22)),
    TodoItem(id: 't5', text: 'Schedule OSHPD/FGI compliance review', assignee: 'Sarah Chen', dueDate: DateTime(2025, 10, 25)),
    TodoItem(id: 't6', text: 'Finalize radiation shielding calcs', done: true, assignee: 'James Rivera', dueDate: DateTime(2025, 10, 10)),
    TodoItem(id: 't7', text: 'Update OR suite door schedule', assignee: 'Amanda Foster', dueDate: DateTime(2025, 11, 1)),
    TodoItem(id: 't8', text: 'Review structural calcs for imaging suite slab', assignee: 'Emily Nguyen', dueDate: DateTime(2025, 10, 28)),
  ];

  static final files = <ProjectFile>[
    ProjectFile(id: 'f1', name: 'ED_FloorPlan_Rev3.pdf', category: 'Architectural', sizeBytes: 5200000, modified: DateTime(2025, 10, 16, 10, 30)),
    ProjectFile(id: 'f2', name: 'MEP_MedGas_Coordination.pdf', category: 'MEP', sizeBytes: 3800000, modified: DateTime(2025, 10, 15, 14, 0)),
    ProjectFile(id: 'f3', name: 'Landscape_Plan_v2.pdf', category: 'Landscape', sizeBytes: 2800000, modified: DateTime(2025, 10, 14, 9, 15)),
    ProjectFile(id: 'f4', name: 'Structural_Foundation_Calcs.pdf', category: 'Structural', sizeBytes: 1900000, modified: DateTime(2025, 10, 12, 16, 45)),
    ProjectFile(id: 'f5', name: 'Site_Survey_Topo_Final.pdf', category: 'Civil', sizeBytes: 9200000, modified: DateTime(2025, 10, 10, 11, 0)),
    ProjectFile(id: 'f6', name: 'Contract_Amendment_02.pdf', category: 'Admin', sizeBytes: 520000, modified: DateTime(2025, 10, 8, 13, 30)),
    ProjectFile(id: 'f7', name: 'Interior_Finish_Schedule_OR.xlsx', category: 'Interior', sizeBytes: 1100000, modified: DateTime(2025, 10, 7, 10, 0)),
    ProjectFile(id: 'f8', name: 'Rendering_MainEntry_Final.png', category: 'Renderings', sizeBytes: 18200000, modified: DateTime(2025, 10, 5, 17, 20)),
  ];

  static final deadlines = <Deadline>[
    Deadline(id: 'd1', label: 'CD 50% Submittal', date: DateTime(2025, 11, 15), severity: 'yellow'),
    Deadline(id: 'd2', label: 'FGI Compliance Review', date: DateTime(2025, 12, 1), severity: 'red'),
    Deadline(id: 'd3', label: 'CD 100% Submittal', date: DateTime(2026, 3, 15), severity: 'blue'),
    Deadline(id: 'd4', label: 'Permit Application', date: DateTime(2026, 4, 1), severity: 'blue'),
    Deadline(id: 'd5', label: 'Bid Package Release', date: DateTime(2026, 6, 15), severity: 'green'),
  ];

  static final rfis = <RfiItem>[
    RfiItem(id: 'r1', number: 'RFI-001', subject: 'Medical gas piping routing conflict at ED corridor ceiling', status: 'Closed', dateOpened: DateTime(2025, 4, 3), dateClosed: DateTime(2025, 4, 18), assignee: 'Michael Torres'),
    RfiItem(id: 'r2', number: 'RFI-002', subject: 'Radiation shielding thickness for CT imaging room', status: 'Closed', dateOpened: DateTime(2025, 5, 1), dateClosed: DateTime(2025, 5, 20), assignee: 'James Rivera'),
    RfiItem(id: 'r3', number: 'RFI-003', subject: 'Nurse call system head-end equipment location', status: 'Open', dateOpened: DateTime(2025, 8, 12), assignee: 'Michael Torres'),
    RfiItem(id: 'r4', number: 'RFI-004', subject: 'ADA clearances at patient room restrooms', status: 'Open', dateOpened: DateTime(2025, 9, 2), assignee: 'James Rivera'),
    RfiItem(id: 'r5', number: 'RFI-005', subject: 'Stormwater detention pond sizing per SAWS requirements', status: 'Pending', dateOpened: DateTime(2025, 9, 25), assignee: 'David Park'),
  ];

  static final drawingSheets = <DrawingSheet>[
    DrawingSheet(id: 'ds1', sheetNumber: 'A-001', title: 'Cover Sheet & Drawing Index', discipline: 'Architectural', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 10), status: 'Current'),
    DrawingSheet(id: 'ds2', sheetNumber: 'A-101', title: 'First Floor Plan \u2014 ED & Imaging', discipline: 'Architectural', phase: 'CD', revision: 3, lastRevised: DateTime(2025, 10, 14), status: 'Current'),
    DrawingSheet(id: 'ds3', sheetNumber: 'A-102', title: 'First Floor Plan \u2014 OR & Patient Rooms', discipline: 'Architectural', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 12), status: 'In Progress'),
    DrawingSheet(id: 'ds4', sheetNumber: 'A-201', title: 'Exterior Elevations', discipline: 'Architectural', phase: 'DD', revision: 4, lastRevised: DateTime(2025, 8, 28), status: 'Current'),
    DrawingSheet(id: 'ds5', sheetNumber: 'A-301', title: 'Building Sections', discipline: 'Architectural', phase: 'DD', revision: 2, lastRevised: DateTime(2025, 7, 15), status: 'Current'),
    DrawingSheet(id: 'ds6', sheetNumber: 'A-501', title: 'Wall Sections & Infection Control Details', discipline: 'Architectural', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 8), status: 'In Progress'),
    DrawingSheet(id: 'ds7', sheetNumber: 'C-001', title: 'Cover Sheet', discipline: 'Civil', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 8, 20), status: 'Current'),
    DrawingSheet(id: 'ds8', sheetNumber: 'C-101', title: 'Grading & Drainage Plan', discipline: 'Civil', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 5), status: 'Current'),
    DrawingSheet(id: 'ds9', sheetNumber: 'C-102', title: 'Utility Plan \u2014 Water & Sewer', discipline: 'Civil', phase: 'DD', revision: 3, lastRevised: DateTime(2025, 8, 18), status: 'Current'),
    DrawingSheet(id: 'ds10', sheetNumber: 'C-103', title: 'Erosion Control & SWPPP', discipline: 'Civil', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 9, 1), status: 'Review'),
    DrawingSheet(id: 'ds11', sheetNumber: 'L-001', title: 'Cover Sheet', discipline: 'Landscape', phase: 'DD', revision: 1, lastRevised: DateTime(2025, 5, 15), status: 'Current'),
    DrawingSheet(id: 'ds12', sheetNumber: 'L-101', title: 'Landscape & Healing Garden Plan', discipline: 'Landscape', phase: 'DD', revision: 2, lastRevised: DateTime(2025, 8, 22), status: 'Current'),
    DrawingSheet(id: 'ds13', sheetNumber: 'L-102', title: 'Irrigation Plan', discipline: 'Landscape', phase: 'DD', revision: 1, lastRevised: DateTime(2025, 7, 10), status: 'In Progress'),
    DrawingSheet(id: 'ds14', sheetNumber: 'M-001', title: 'Cover Sheet & Equipment Schedules', discipline: 'Mechanical', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 8, 25), status: 'Current'),
    DrawingSheet(id: 'ds15', sheetNumber: 'M-101', title: 'HVAC Floor Plan \u2014 Level 1', discipline: 'Mechanical', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 8), status: 'Current'),
    DrawingSheet(id: 'ds16', sheetNumber: 'M-201', title: 'Medical Gas Piping & Details', discipline: 'Mechanical', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 3), status: 'In Progress'),
    DrawingSheet(id: 'ds17', sheetNumber: 'E-001', title: 'Cover Sheet & Panel Schedules', discipline: 'Electrical', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 8, 28), status: 'Current'),
    DrawingSheet(id: 'ds18', sheetNumber: 'E-101', title: 'Lighting Plan \u2014 Level 1', discipline: 'Electrical', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 6), status: 'Current'),
    DrawingSheet(id: 'ds19', sheetNumber: 'E-102', title: 'Power & Nurse Call Plan \u2014 Level 1', discipline: 'Electrical', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 2), status: 'Review'),
    DrawingSheet(id: 'ds20', sheetNumber: 'P-001', title: 'Cover Sheet & Fixture Schedule', discipline: 'Plumbing', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 8, 30), status: 'Current'),
    DrawingSheet(id: 'ds21', sheetNumber: 'P-101', title: 'Medical Gas & Plumbing Plan \u2014 Level 1', discipline: 'Plumbing', phase: 'CD', revision: 2, lastRevised: DateTime(2025, 10, 9), status: 'Current'),
    DrawingSheet(id: 'ds22', sheetNumber: 'FP-001', title: 'Cover Sheet & General Notes', discipline: 'Fire Protection', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 8, 25), status: 'Current'),
    DrawingSheet(id: 'ds23', sheetNumber: 'FP-101', title: 'Sprinkler Plan \u2014 Level 1', discipline: 'Fire Protection', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 3), status: 'In Progress'),
    DrawingSheet(id: 'ds24', sheetNumber: 'FP-102', title: 'Sprinkler Plan \u2014 Level 2', discipline: 'Fire Protection', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 5), status: 'In Progress'),
    DrawingSheet(id: 'ds25', sheetNumber: 'FP-201', title: 'Sprinkler Riser Diagram', discipline: 'Fire Protection', phase: 'CD', revision: 1, lastRevised: DateTime(2025, 10, 7), status: 'Review'),
  ];

  static final phaseDocuments = <PhaseDocument>[
    PhaseDocument(id: 'pd1', name: 'SD_Package_Narrative.pdf', phase: 'SD', docType: 'Report', source: 'Architect', sizeBytes: 2800000, modified: DateTime(2024, 9, 10), status: 'Current', revision: 2),
    PhaseDocument(id: 'pd2', name: 'SD_Floor_Plans_Hospital.pdf', phase: 'SD', docType: 'Drawing', source: 'Architect', sizeBytes: 9500000, modified: DateTime(2024, 9, 8), status: 'Current', revision: 3),
    PhaseDocument(id: 'pd3', name: 'DD_Specifications_Outline.pdf', phase: 'DD', docType: 'Specification', source: 'Architect', sizeBytes: 4100000, modified: DateTime(2025, 2, 20), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd4', name: 'DD_MEP_MedGas_Report.pdf', phase: 'DD', discipline: 'MEP', docType: 'Report', source: 'Consultant', sizeBytes: 2200000, modified: DateTime(2025, 2, 15), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd5', name: 'CD_Arch_Set_50pct.pdf', phase: 'CD', discipline: 'Architectural', docType: 'Drawing', source: 'Architect', sizeBytes: 28500000, modified: DateTime(2025, 8, 30), status: 'Under Review', revision: 1),
    PhaseDocument(id: 'pd6', name: 'CD_Structural_Foundation_Calcs.pdf', phase: 'CD', discipline: 'Structural', docType: 'Report', source: 'Consultant', sizeBytes: 6200000, modified: DateTime(2025, 9, 5), status: 'Draft', revision: 0),
    PhaseDocument(id: 'pd7', name: 'CD_Spec_Div_11_Medical_Equipment.pdf', phase: 'CD', docType: 'Specification', source: 'Architect', sizeBytes: 1200000, modified: DateTime(2025, 10, 10), status: 'Current', revision: 2),
    PhaseDocument(id: 'pd8', name: 'Geotechnical_Report.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 14500000, modified: DateTime(2024, 3, 20), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd9', name: 'ALTA_Survey.pdf', phase: '', docType: 'Drawing', source: 'Client', sizeBytes: 22100000, modified: DateTime(2024, 2, 15), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd10', name: 'Baptist_Programming_Requirements.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 4500000, modified: DateTime(2024, 1, 10), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd11', name: 'Survey_Boundary_Topo.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 11200000, modified: DateTime(2024, 3, 5), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd12', name: 'Environmental_Phase1.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 4800000, modified: DateTime(2024, 4, 1), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd13', name: 'Site_Photo_Street_View.jpg', phase: '', docType: 'Submittal', source: 'Architect', sizeBytes: 5800000, modified: DateTime(2024, 5, 12), status: 'Current'),
    PhaseDocument(id: 'pd14', name: 'Site_Photo_South_Parcel.jpg', phase: '', docType: 'Submittal', source: 'Architect', sizeBytes: 5200000, modified: DateTime(2024, 5, 12), status: 'Current'),
    PhaseDocument(id: 'pd15', name: 'Aerial_Drone_Survey.png', phase: '', docType: 'Submittal', source: 'Client', sizeBytes: 8400000, modified: DateTime(2024, 4, 18), status: 'Current'),
    PhaseDocument(id: 'pd16', name: 'Material_Mockup_Facade.jpg', phase: 'DD', docType: 'Submittal', source: 'Architect', sizeBytes: 6800000, modified: DateTime(2025, 1, 5), status: 'Current'),
    PhaseDocument(id: 'pd17', name: 'FGI_Compliance_Checklist.pdf', phase: '', docType: 'Report', source: 'Architect', sizeBytes: 1800000, modified: DateTime(2025, 9, 30), status: 'Current'),
  ];

  static final printSets = <PrintSet>[
    PrintSet(id: 'ps1', title: '50% DD Set', type: 'Progress', date: DateTime(2024, 12, 15), sheetCount: 48, distributedTo: 'Baptist Health, MEP Consultant', status: 'Distributed'),
    PrintSet(id: 'ps2', title: '100% DD Set', type: 'Progress', date: DateTime(2025, 2, 28), sheetCount: 74, distributedTo: 'Baptist Health, All Consultants', status: 'Distributed'),
    PrintSet(id: 'ps3', title: '50% CD Set', type: 'Progress', date: DateTime(2025, 8, 28), sheetCount: 92, distributedTo: 'Baptist Health, All Consultants, GC', status: 'Distributed'),
    PrintSet(id: 'ps4', title: 'SD Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2024, 9, 15), sheetCount: 28, distributedTo: 'Baptist Health, City of San Antonio', status: 'Distributed', sealedBy: 'James Rivera, RA'),
    PrintSet(id: 'ps5', title: 'DD Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2025, 3, 1), sheetCount: 74, distributedTo: 'Baptist Health, TDSHS', status: 'Distributed', sealedBy: 'James Rivera, RA'),
    PrintSet(id: 'ps6', title: 'Foundation Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2025, 10, 10), sheetCount: 22, distributedTo: 'GC, City of San Antonio', status: 'Pending', sealedBy: 'Emily Nguyen, PE'),
  ];

  static final renderings = <RenderingItem>[
    RenderingItem(id: 'rn1', title: 'Main Entry \u2014 Daytime', viewType: 'Exterior', created: DateTime(2025, 2, 15), status: 'Final', sizeBytes: 21500000, placeholderColor: const Color(0xFF1B4F72)),
    RenderingItem(id: 'rn2', title: 'Emergency Department Drop-off', viewType: 'Exterior', created: DateTime(2025, 2, 20), status: 'Final', sizeBytes: 18800000, placeholderColor: const Color(0xFF0D2137)),
    RenderingItem(id: 'rn3', title: 'Aerial View \u2014 Northwest', viewType: 'Aerial', created: DateTime(2025, 3, 5), status: 'Client Review', sizeBytes: 24200000, placeholderColor: const Color(0xFF2E5A3A)),
    RenderingItem(id: 'rn4', title: 'Patient Room Interior', viewType: 'Interior', created: DateTime(2025, 7, 12), status: 'Draft', sizeBytes: 16400000, placeholderColor: const Color(0xFF4A3728)),
    RenderingItem(id: 'rn5', title: 'Healing Garden Courtyard', viewType: 'Detail', created: DateTime(2025, 9, 1), status: 'In Progress', sizeBytes: 9800000, placeholderColor: const Color(0xFF2C3E50)),
  ];

  static final asis = <AsiItem>[
    AsiItem(id: 'a1', number: 'ASI-001', subject: 'Revised ED trauma bay layout \u2014 enlarged from 2 to 3 bays', status: 'Issued', dateIssued: DateTime(2025, 5, 5), affectedSheets: 'A-101, M-101, E-101', issuedBy: 'James Rivera'),
    AsiItem(id: 'a2', number: 'ASI-002', subject: 'Add lead-lined wall at CT imaging room per radiation physicist', status: 'Issued', dateIssued: DateTime(2025, 7, 10), affectedSheets: 'A-102, A-501', issuedBy: 'James Rivera'),
    AsiItem(id: 'a3', number: 'ASI-003', subject: 'Relocate emergency generator pad per fire marshal comments', status: 'Issued', dateIssued: DateTime(2025, 8, 28), affectedSheets: 'C-101, E-001', issuedBy: 'Sarah Chen'),
    AsiItem(id: 'a4', number: 'ASI-004', subject: 'Revised nurse call system head-end location', status: 'Draft', dateIssued: DateTime(2025, 10, 12), affectedSheets: 'E-102, A-102', issuedBy: 'Michael Torres'),
  ];

  static final spaceRequirements = <SpaceRequirement>[
    SpaceRequirement(id: 'sp1', roomName: 'Emergency Department', department: 'Clinical', programmedSF: 4800, designedSF: 5100, adjacency: 'Imaging, Ambulance Bay', notes: 'Includes 3 trauma bays, 8 treatment bays'),
    SpaceRequirement(id: 'sp2', roomName: 'Imaging Suite', department: 'Diagnostic', programmedSF: 2400, designedSF: 2550, adjacency: 'ED, Patient Rooms', notes: 'CT, X-ray, Ultrasound'),
    SpaceRequirement(id: 'sp3', roomName: 'Laboratory', department: 'Diagnostic', programmedSF: 1200, designedSF: 1150, adjacency: 'Pharmacy, ED'),
    SpaceRequirement(id: 'sp4', roomName: 'Pharmacy', department: 'Support', programmedSF: 800, designedSF: 820, adjacency: 'Laboratory, Nursing Station'),
    SpaceRequirement(id: 'sp5', roomName: 'Operating Room Suite', department: 'Surgical', programmedSF: 3200, designedSF: 3350, adjacency: 'Pre-Op, PACU, Central Sterile', notes: '2 OR suites with pre-op/PACU'),
    SpaceRequirement(id: 'sp6', roomName: 'Patient Rooms (8)', department: 'Inpatient', programmedSF: 2800, designedSF: 2720, adjacency: 'Nursing Station, Support', notes: '8 private rooms @ 350 SF each'),
    SpaceRequirement(id: 'sp7', roomName: 'Nursing Station', department: 'Clinical', programmedSF: 600, designedSF: 640, adjacency: 'Patient Rooms, Pharmacy', notes: 'Central monitoring capability'),
    SpaceRequirement(id: 'sp8', roomName: 'Lobby / Registration', department: 'Public', programmedSF: 1800, designedSF: 1900, adjacency: 'ED Entrance, Admin', notes: 'Includes waiting, registration, triage'),
    SpaceRequirement(id: 'sp9', roomName: 'Support / MEP', department: 'Service', programmedSF: 2400, designedSF: 2500, adjacency: 'Loading Dock, Electrical', notes: 'Medical gas storage, electrical, IT/MDF'),
    SpaceRequirement(id: 'sp10', roomName: 'Administration', department: 'Admin', programmedSF: 1200, designedSF: 1180, adjacency: 'Lobby, Break Room'),
  ];

  static final projectInfo = <ProjectInfoEntry>[
    ProjectInfoEntry(id: 'pi1', category: 'General', label: 'Project Name', value: ''),
    ProjectInfoEntry(id: 'pi2', category: 'General', label: 'Project Number', value: ''),
    ProjectInfoEntry(id: 'pi3', category: 'General', label: 'Project Address', value: ''),
    ProjectInfoEntry(id: 'pi4', category: 'General', label: 'Client', value: ''),
    ProjectInfoEntry(id: 'pi5', category: 'General', label: 'Architect of Record', value: 'A2H'),
    ProjectInfoEntry(id: 'pi6', category: 'Codes & Standards', label: 'Building Code', value: ''),
    ProjectInfoEntry(id: 'pi7', category: 'Codes & Standards', label: 'Energy Code', value: ''),
    ProjectInfoEntry(id: 'pi8', category: 'Codes & Standards', label: 'Fire Code', value: ''),
    ProjectInfoEntry(id: 'pi9', category: 'Codes & Standards', label: 'Accessibility', value: ''),
    ProjectInfoEntry(id: 'pi10', category: 'Codes & Standards', label: 'Healthcare Guidelines', value: ''),
    ProjectInfoEntry(id: 'pi11', category: 'Zoning', label: 'Zoning Classification', value: ''),
    ProjectInfoEntry(id: 'pi12', category: 'Zoning', label: 'FAR (Allowed / Designed)', value: ''),
    ProjectInfoEntry(id: 'pi13', category: 'Zoning', label: 'Max Height', value: ''),
    ProjectInfoEntry(id: 'pi14', category: 'Zoning', label: 'Setbacks (F/S/R)', value: ''),
    ProjectInfoEntry(id: 'pi15', category: 'Site', label: 'Parcel Number', value: ''),
    ProjectInfoEntry(id: 'pi16', category: 'Site', label: 'Lot Size', value: ''),
    ProjectInfoEntry(id: 'pi17', category: 'Site', label: 'Existing Use', value: ''),
    ProjectInfoEntry(id: 'pi18', category: 'Site', label: 'Latitude', value: ''),
    ProjectInfoEntry(id: 'pi19', category: 'Site', label: 'Longitude', value: ''),
    ProjectInfoEntry(id: 'pi20', category: 'Site', label: 'City', value: ''),
    ProjectInfoEntry(id: 'pi21', category: 'Site', label: 'Elevation', value: ''),
    ProjectInfoEntry(id: 'pi22', category: 'Site', label: 'UTM Zone', value: ''),
  ];

  static final changeOrders = <ChangeOrder>[
    ChangeOrder(id: 'co1', number: 'CO-001', description: 'Foundation redesign \u2014 additional piers at imaging suite per geotechnical recommendation for MRI vibration isolation', amount: 92000, status: 'Approved', dateSubmitted: DateTime(2025, 6, 15), dateResolved: DateTime(2025, 8, 8), initiatedBy: 'Emily Nguyen', reason: 'Field Condition'),
    ChangeOrder(id: 'co2', number: 'CO-002', description: 'HVAC isolation room modifications \u2014 add negative pressure capability to 4 ED treatment bays', amount: 67000, status: 'Approved', dateSubmitted: DateTime(2025, 7, 10), dateResolved: DateTime(2025, 10, 3), initiatedBy: 'Michael Torres', reason: 'Code Requirement'),
    ChangeOrder(id: 'co3', number: 'CO-003', description: 'Add third trauma bay to ED per Baptist Health revised programming', amount: 145000, status: 'Pending', dateSubmitted: DateTime(2025, 9, 5), initiatedBy: 'Robert Kim', reason: 'Owner Request'),
    ChangeOrder(id: 'co4', number: 'CO-004', description: 'Upgraded lobby finish materials \u2014 healing garden visual connection and wayfinding', amount: 78000, status: 'Pending', dateSubmitted: DateTime(2025, 9, 20), initiatedBy: 'Amanda Foster', reason: 'Owner Request'),
    ChangeOrder(id: 'co5', number: 'CO-005', description: 'Emergency generator upsizing from 500kW to 750kW per code review', amount: 34000, status: 'Pending', dateSubmitted: DateTime(2025, 10, 14), initiatedBy: 'Michael Torres', reason: 'Code Requirement'),
  ];

  static final submittals = <SubmittalItem>[
    SubmittalItem(id: 'sub1', number: 'SUB-001', title: 'Structural Steel Shop Drawings', specSection: '05 12 00', status: 'Approved', dateSubmitted: DateTime(2025, 5, 15), dateReturned: DateTime(2025, 6, 2), submittedBy: 'GC \u2014 Bartlett Cocke', assignedTo: 'Emily Nguyen'),
    SubmittalItem(id: 'sub2', number: 'SUB-002', title: 'Medical Gas Piping System', specSection: '22 62 00', status: 'Approved as Noted', dateSubmitted: DateTime(2025, 6, 8), dateReturned: DateTime(2025, 7, 5), submittedBy: 'GC \u2014 Bartlett Cocke', assignedTo: 'Michael Torres'),
    SubmittalItem(id: 'sub3', number: 'SUB-003', title: 'Radiation Shielding \u2014 CT & X-Ray Rooms', specSection: '13 49 00', status: 'Approved', dateSubmitted: DateTime(2025, 7, 12), dateReturned: DateTime(2025, 7, 28), submittedBy: 'GC \u2014 Bartlett Cocke', assignedTo: 'James Rivera'),
    SubmittalItem(id: 'sub4', number: 'SUB-004', title: 'Nurse Call System', specSection: '27 52 23', status: 'Revise & Resubmit', dateSubmitted: DateTime(2025, 8, 20), dateReturned: DateTime(2025, 9, 8), submittedBy: 'Low Voltage Sub \u2014 Convergint', assignedTo: 'Michael Torres'),
    SubmittalItem(id: 'sub5', number: 'SUB-005', title: 'Emergency Generator & ATS', specSection: '26 32 13', status: 'Pending', dateSubmitted: DateTime(2025, 9, 1), submittedBy: 'GC \u2014 Bartlett Cocke', assignedTo: 'Michael Torres'),
    SubmittalItem(id: 'sub6', number: 'SUB-006', title: 'Fire Sprinkler Shop Drawings', specSection: '21 13 13', status: 'Pending', dateSubmitted: DateTime(2025, 9, 15), submittedBy: 'FP Sub \u2014 SimplexGrinnell', assignedTo: 'James Rivera'),
    SubmittalItem(id: 'sub7', number: 'SUB-007', title: 'Interior Wall Protection & Handrails', specSection: '10 26 00', status: 'Pending', dateSubmitted: DateTime(2025, 10, 10), submittedBy: 'GC \u2014 Bartlett Cocke', assignedTo: 'Amanda Foster'),
  ];
}
