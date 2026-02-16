import 'package:flutter/material.dart';
import '../models/project_models.dart';

/// Default seed data for first-run experience.
/// Used when no persisted data exists in storage.
class DefaultData {
  DefaultData._();

  static final team = <TeamMember>[
    TeamMember(id: '1', name: 'Sarah Chen', role: 'Project Manager', company: 'Meridian Architecture', email: 'schen@meridian.com', phone: '(555) 100-2001', avatarColor: const Color(0xFF4FC3F7)),
    TeamMember(id: '2', name: 'James Rivera', role: 'Lead Architect', company: 'Meridian Architecture', email: 'jrivera@meridian.com', phone: '(555) 100-2002', avatarColor: const Color(0xFF81C784)),
    TeamMember(id: '3', name: 'Emily Nguyen', role: 'Structural Engineer', company: 'CoreStruct Engineering', email: 'enguyen@corestruct.com', phone: '(555) 200-3001', avatarColor: const Color(0xFFFFB74D)),
    TeamMember(id: '4', name: 'Michael Torres', role: 'MEP Coordinator', company: 'SystemFlow MEP', email: 'mtorres@systemflow.com', phone: '(555) 300-4001', avatarColor: const Color(0xFFE57373)),
    TeamMember(id: '5', name: 'David Park', role: 'Civil Engineer', company: 'Greystone Civil', email: 'dpark@greystone.com', phone: '(555) 400-5001', avatarColor: const Color(0xFFBA68C8)),
    TeamMember(id: '6', name: 'Lisa Martinez', role: 'Landscape Architect', company: 'GreenEdge Design', email: 'lmartinez@greenedge.com', phone: '(555) 500-6001', avatarColor: const Color(0xFF4DB6AC)),
    TeamMember(id: '7', name: 'Robert Kim', role: 'Owner Representative', company: 'Northstar Development', email: 'rkim@northstar.com', phone: '(555) 600-7001', avatarColor: const Color(0xFF7986CB)),
    TeamMember(id: '8', name: 'Amanda Foster', role: 'Interior Designer', company: 'Meridian Architecture', email: 'afoster@meridian.com', phone: '(555) 100-2003', avatarColor: const Color(0xFFF06292)),
  ];

  static final contracts = <ContractItem>[
    ContractItem(id: 'c1', title: 'Original A/E Services Agreement', type: 'Original', amount: 2450000, status: 'Executed', date: DateTime(2025, 3, 15)),
    ContractItem(id: 'c2', title: 'Amendment 01 \u2014 Expanded Scope', type: 'Amendment', amount: 185000, status: 'Executed', date: DateTime(2025, 6, 10)),
    ContractItem(id: 'c3', title: 'Amendment 02 \u2014 Additional Renderings', type: 'Amendment', amount: 45000, status: 'Executed', date: DateTime(2025, 9, 22)),
    ContractItem(id: 'c4', title: 'CO-001 \u2014 Foundation Redesign', type: 'Change Order', amount: 72000, status: 'Pending', date: DateTime(2026, 1, 8)),
    ContractItem(id: 'c5', title: 'CO-002 \u2014 HVAC Value Engineering', type: 'Change Order', amount: -38000, status: 'Draft', date: DateTime(2026, 2, 3)),
  ];

  static final schedule = <SchedulePhase>[
    SchedulePhase(id: 's1', name: 'Schematic Design', start: DateTime(2025, 3, 1), end: DateTime(2025, 7, 15), progress: 1.0, status: 'Complete'),
    SchedulePhase(id: 's2', name: 'Design Development', start: DateTime(2025, 6, 1), end: DateTime(2025, 11, 30), progress: 0.85, status: 'In Progress'),
    SchedulePhase(id: 's3', name: 'Construction Documents', start: DateTime(2025, 10, 1), end: DateTime(2026, 5, 15), progress: 0.30, status: 'In Progress'),
    SchedulePhase(id: 's4', name: 'Permitting', start: DateTime(2026, 3, 1), end: DateTime(2026, 6, 30), progress: 0.0, status: 'Upcoming'),
    SchedulePhase(id: 's5', name: 'Bidding & Negotiation', start: DateTime(2026, 5, 1), end: DateTime(2026, 7, 31), progress: 0.0, status: 'Upcoming'),
    SchedulePhase(id: 's6', name: 'Construction Admin', start: DateTime(2026, 8, 1), end: DateTime(2027, 12, 31), progress: 0.0, status: 'Upcoming'),
  ];

  static final budget = <BudgetLine>[
    BudgetLine(id: 'b1', category: 'Architecture', budgeted: 1200000, spent: 620000, committed: 280000),
    BudgetLine(id: 'b2', category: 'Structural', budgeted: 380000, spent: 195000, committed: 95000),
    BudgetLine(id: 'b3', category: 'MEP Engineering', budgeted: 520000, spent: 210000, committed: 180000),
    BudgetLine(id: 'b4', category: 'Civil / Site', budgeted: 290000, spent: 145000, committed: 85000),
    BudgetLine(id: 'b5', category: 'Landscape', budgeted: 180000, spent: 72000, committed: 54000),
    BudgetLine(id: 'b6', category: 'Interior Design', budgeted: 340000, spent: 102000, committed: 136000),
    BudgetLine(id: 'b7', category: 'Renderings / Media', budgeted: 95000, spent: 45000, committed: 20000),
    BudgetLine(id: 'b8', category: 'Consultants / Other', budgeted: 150000, spent: 38000, committed: 52000),
  ];

  static final todos = <TodoItem>[
    TodoItem(id: 't1', text: 'Review SD package comments', assignee: 'Sarah Chen', dueDate: DateTime(2026, 2, 18)),
    TodoItem(id: 't2', text: 'Update civil grading plan', done: true, assignee: 'David Park', dueDate: DateTime(2026, 2, 14)),
    TodoItem(id: 't3', text: 'Coordinate MEP clash detection', assignee: 'Michael Torres', dueDate: DateTime(2026, 2, 20)),
    TodoItem(id: 't4', text: 'Submit landscape revisions', assignee: 'Lisa Martinez', dueDate: DateTime(2026, 2, 22)),
    TodoItem(id: 't5', text: 'Schedule client DD review', assignee: 'Sarah Chen', dueDate: DateTime(2026, 2, 25)),
    TodoItem(id: 't6', text: 'Finalize permit checklist', done: true, assignee: 'James Rivera', dueDate: DateTime(2026, 2, 10)),
    TodoItem(id: 't7', text: 'Update door schedule', assignee: 'Amanda Foster', dueDate: DateTime(2026, 3, 1)),
    TodoItem(id: 't8', text: 'Review structural calcs rev 2', assignee: 'Emily Nguyen', dueDate: DateTime(2026, 2, 28)),
  ];

  static final files = <ProjectFile>[
    ProjectFile(id: 'f1', name: 'SD_Floorplan_Rev3.pdf', category: 'Architectural', sizeBytes: 4500000, modified: DateTime(2026, 2, 16, 10, 30)),
    ProjectFile(id: 'f2', name: 'MEP_Coordination.pdf', category: 'MEP', sizeBytes: 3200000, modified: DateTime(2026, 2, 15, 14, 0)),
    ProjectFile(id: 'f3', name: 'Landscape_Plan_v2.pdf', category: 'Landscape', sizeBytes: 2800000, modified: DateTime(2026, 2, 14, 9, 15)),
    ProjectFile(id: 'f4', name: 'Structural_Calcs.pdf', category: 'Structural', sizeBytes: 1500000, modified: DateTime(2026, 2, 12, 16, 45)),
    ProjectFile(id: 'f5', name: 'Site_Survey_Final.pdf', category: 'Civil', sizeBytes: 8900000, modified: DateTime(2026, 2, 10, 11, 0)),
    ProjectFile(id: 'f6', name: 'Contract_Amendment_4.pdf', category: 'Admin', sizeBytes: 420000, modified: DateTime(2026, 2, 8, 13, 30)),
    ProjectFile(id: 'f7', name: 'Interior_Finish_Schedule.xlsx', category: 'Interior', sizeBytes: 980000, modified: DateTime(2026, 2, 7, 10, 0)),
    ProjectFile(id: 'f8', name: 'Rendering_Lobby_Final.png', category: 'Renderings', sizeBytes: 15600000, modified: DateTime(2026, 2, 5, 17, 20)),
  ];

  static final deadlines = <Deadline>[
    Deadline(id: 'd1', label: 'SD Submittal', date: DateTime(2026, 3, 15), severity: 'green'),
    Deadline(id: 'd2', label: 'DD Milestone', date: DateTime(2026, 4, 2), severity: 'yellow'),
    Deadline(id: 'd3', label: 'CD Review', date: DateTime(2026, 5, 10), severity: 'red'),
    Deadline(id: 'd4', label: 'Permit Set', date: DateTime(2026, 6, 1), severity: 'blue'),
    Deadline(id: 'd5', label: 'Bid Package', date: DateTime(2026, 7, 15), severity: 'blue'),
  ];

  static final rfis = <RfiItem>[
    RfiItem(id: 'r1', number: 'RFI-001', subject: 'Foundation footing depth at grid B-4', status: 'Closed', dateOpened: DateTime(2025, 11, 3), dateClosed: DateTime(2025, 11, 18), assignee: 'Emily Nguyen'),
    RfiItem(id: 'r2', number: 'RFI-002', subject: 'Exterior cladding material substitution', status: 'Closed', dateOpened: DateTime(2025, 12, 1), dateClosed: DateTime(2025, 12, 20), assignee: 'James Rivera'),
    RfiItem(id: 'r3', number: 'RFI-003', subject: 'MEP routing conflict at Level 3 corridor', status: 'Open', dateOpened: DateTime(2026, 1, 12), assignee: 'Michael Torres'),
    RfiItem(id: 'r4', number: 'RFI-004', subject: 'ADA compliance \u2014 restroom clearances', status: 'Open', dateOpened: DateTime(2026, 1, 28), assignee: 'James Rivera'),
    RfiItem(id: 'r5', number: 'RFI-005', subject: 'Stormwater retention basin sizing', status: 'Pending', dateOpened: DateTime(2026, 2, 5), assignee: 'David Park'),
  ];

  static final drawingSheets = <DrawingSheet>[
    DrawingSheet(id: 'ds1', sheetNumber: 'A-001', title: 'Cover Sheet & Drawing Index', discipline: 'Architectural', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 10), status: 'Current'),
    DrawingSheet(id: 'ds2', sheetNumber: 'A-101', title: 'First Floor Plan', discipline: 'Architectural', phase: 'CD', revision: 3, lastRevised: DateTime(2026, 2, 14), status: 'Current'),
    DrawingSheet(id: 'ds3', sheetNumber: 'A-102', title: 'Second Floor Plan', discipline: 'Architectural', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 12), status: 'In Progress'),
    DrawingSheet(id: 'ds4', sheetNumber: 'A-201', title: 'Exterior Elevations', discipline: 'Architectural', phase: 'DD', revision: 4, lastRevised: DateTime(2026, 1, 28), status: 'Current'),
    DrawingSheet(id: 'ds5', sheetNumber: 'A-301', title: 'Building Sections', discipline: 'Architectural', phase: 'DD', revision: 2, lastRevised: DateTime(2026, 1, 15), status: 'Current'),
    DrawingSheet(id: 'ds6', sheetNumber: 'A-501', title: 'Wall Sections & Details', discipline: 'Architectural', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 2, 8), status: 'In Progress'),
    DrawingSheet(id: 'ds7', sheetNumber: 'C-001', title: 'Cover Sheet', discipline: 'Civil', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 1, 20), status: 'Current'),
    DrawingSheet(id: 'ds8', sheetNumber: 'C-101', title: 'Grading & Drainage Plan', discipline: 'Civil', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 5), status: 'Current'),
    DrawingSheet(id: 'ds9', sheetNumber: 'C-102', title: 'Utility Plan', discipline: 'Civil', phase: 'DD', revision: 3, lastRevised: DateTime(2026, 1, 18), status: 'Current'),
    DrawingSheet(id: 'ds10', sheetNumber: 'C-103', title: 'Erosion Control Plan', discipline: 'Civil', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 2, 1), status: 'Review'),
    DrawingSheet(id: 'ds11', sheetNumber: 'L-001', title: 'Cover Sheet', discipline: 'Landscape', phase: 'DD', revision: 1, lastRevised: DateTime(2025, 12, 15), status: 'Current'),
    DrawingSheet(id: 'ds12', sheetNumber: 'L-101', title: 'Landscape Plan', discipline: 'Landscape', phase: 'DD', revision: 2, lastRevised: DateTime(2026, 1, 22), status: 'Current'),
    DrawingSheet(id: 'ds13', sheetNumber: 'L-102', title: 'Irrigation Plan', discipline: 'Landscape', phase: 'DD', revision: 1, lastRevised: DateTime(2026, 1, 10), status: 'In Progress'),
    DrawingSheet(id: 'ds14', sheetNumber: 'M-001', title: 'Cover Sheet & Schedules', discipline: 'Mechanical', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 1, 25), status: 'Current'),
    DrawingSheet(id: 'ds15', sheetNumber: 'M-101', title: 'HVAC Floor Plan Level 1', discipline: 'Mechanical', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 8), status: 'Current'),
    DrawingSheet(id: 'ds16', sheetNumber: 'M-201', title: 'Ductwork Details', discipline: 'Mechanical', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 2, 3), status: 'In Progress'),
    DrawingSheet(id: 'ds17', sheetNumber: 'E-001', title: 'Cover Sheet & Panel Schedules', discipline: 'Electrical', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 1, 28), status: 'Current'),
    DrawingSheet(id: 'ds18', sheetNumber: 'E-101', title: 'Lighting Plan Level 1', discipline: 'Electrical', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 6), status: 'Current'),
    DrawingSheet(id: 'ds19', sheetNumber: 'E-102', title: 'Power Plan Level 1', discipline: 'Electrical', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 2, 2), status: 'Review'),
    DrawingSheet(id: 'ds20', sheetNumber: 'P-001', title: 'Cover Sheet & Fixture Schedule', discipline: 'Plumbing', phase: 'CD', revision: 1, lastRevised: DateTime(2026, 1, 30), status: 'Current'),
    DrawingSheet(id: 'ds21', sheetNumber: 'P-101', title: 'Plumbing Plan Level 1', discipline: 'Plumbing', phase: 'CD', revision: 2, lastRevised: DateTime(2026, 2, 9), status: 'Current'),
  ];

  static final phaseDocuments = <PhaseDocument>[
    PhaseDocument(id: 'pd1', name: 'SD_Package_Narrative.pdf', phase: 'SD', docType: 'Report', source: 'Architect', sizeBytes: 2400000, modified: DateTime(2025, 7, 10), status: 'Current', revision: 2),
    PhaseDocument(id: 'pd2', name: 'SD_Floor_Plans.pdf', phase: 'SD', docType: 'Drawing', source: 'Architect', sizeBytes: 8100000, modified: DateTime(2025, 7, 8), status: 'Current', revision: 3),
    PhaseDocument(id: 'pd3', name: 'DD_Specifications_Outline.pdf', phase: 'DD', docType: 'Specification', source: 'Architect', sizeBytes: 3200000, modified: DateTime(2025, 11, 20), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd4', name: 'DD_MEP_Coordination_Report.pdf', phase: 'DD', discipline: 'MEP', docType: 'Report', source: 'Consultant', sizeBytes: 1800000, modified: DateTime(2025, 11, 15), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd5', name: 'CD_Arch_Set_50pct.pdf', phase: 'CD', discipline: 'Architectural', docType: 'Drawing', source: 'Architect', sizeBytes: 24500000, modified: DateTime(2026, 1, 30), status: 'Under Review', revision: 1),
    PhaseDocument(id: 'pd6', name: 'CD_Structural_Calcs.pdf', phase: 'CD', discipline: 'Structural', docType: 'Report', source: 'Consultant', sizeBytes: 5600000, modified: DateTime(2026, 2, 5), status: 'Draft', revision: 0),
    PhaseDocument(id: 'pd7', name: 'CD_Spec_Div_08_Openings.pdf', phase: 'CD', docType: 'Specification', source: 'Architect', sizeBytes: 980000, modified: DateTime(2026, 2, 10), status: 'Current', revision: 2),
    PhaseDocument(id: 'pd8', name: 'Geotechnical_Report.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 12300000, modified: DateTime(2025, 2, 20), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd9', name: 'Existing_As_Builts.pdf', phase: '', docType: 'Drawing', source: 'Client', sizeBytes: 18700000, modified: DateTime(2025, 1, 15), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd10', name: 'Owner_Programming_Requirements.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 3100000, modified: DateTime(2025, 1, 10), status: 'Current', revision: 1),
    PhaseDocument(id: 'pd11', name: 'Survey_Boundary_Topo.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 9800000, modified: DateTime(2025, 2, 5), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd12', name: 'Environmental_Phase1.pdf', phase: '', docType: 'Report', source: 'Client', sizeBytes: 4200000, modified: DateTime(2025, 3, 1), status: 'Current', revision: 0),
    PhaseDocument(id: 'pd13', name: 'Site_Photo_North_Elevation.jpg', phase: '', docType: 'Submittal', source: 'Architect', sizeBytes: 5400000, modified: DateTime(2025, 4, 12), status: 'Current'),
    PhaseDocument(id: 'pd14', name: 'Site_Photo_South_View.jpg', phase: '', docType: 'Submittal', source: 'Architect', sizeBytes: 4800000, modified: DateTime(2025, 4, 12), status: 'Current'),
    PhaseDocument(id: 'pd15', name: 'Existing_Interior_Lobby.png', phase: '', docType: 'Submittal', source: 'Client', sizeBytes: 3200000, modified: DateTime(2025, 3, 18), status: 'Current'),
    PhaseDocument(id: 'pd16', name: 'Material_Mockup_Facade.jpg', phase: 'DD', docType: 'Submittal', source: 'Architect', sizeBytes: 6100000, modified: DateTime(2025, 10, 5), status: 'Current'),
    PhaseDocument(id: 'pd17', name: 'Construction_Progress_Jan.png', phase: '', docType: 'Submittal', source: 'Contractor', sizeBytes: 7200000, modified: DateTime(2026, 1, 31), status: 'Current'),
  ];

  static final printSets = <PrintSet>[
    PrintSet(id: 'ps1', title: '50% DD Set', type: 'Progress', date: DateTime(2025, 9, 15), sheetCount: 42, distributedTo: 'Owner, MEP Consultant', status: 'Distributed'),
    PrintSet(id: 'ps2', title: '100% DD Set', type: 'Progress', date: DateTime(2025, 11, 30), sheetCount: 68, distributedTo: 'Owner, All Consultants', status: 'Distributed'),
    PrintSet(id: 'ps3', title: '50% CD Set', type: 'Progress', date: DateTime(2026, 1, 28), sheetCount: 85, distributedTo: 'Owner, All Consultants, Contractor', status: 'Distributed'),
    PrintSet(id: 'ps4', title: 'SD Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2025, 7, 15), sheetCount: 24, distributedTo: 'Owner, City Planning', status: 'Distributed', sealedBy: 'James Rivera, RA'),
    PrintSet(id: 'ps5', title: 'DD Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2025, 12, 1), sheetCount: 68, distributedTo: 'Owner, Building Department', status: 'Distributed', sealedBy: 'James Rivera, RA'),
    PrintSet(id: 'ps6', title: 'Foundation Package \u2014 Sealed', type: 'Signed/Sealed', date: DateTime(2026, 2, 10), sheetCount: 18, distributedTo: 'Contractor, Building Dept', status: 'Pending', sealedBy: 'Emily Nguyen, PE'),
  ];

  static final renderings = <RenderingItem>[
    RenderingItem(id: 'rn1', title: 'Main Entry \u2014 Daytime', viewType: 'Exterior', created: DateTime(2025, 10, 15), status: 'Final', sizeBytes: 18500000, placeholderColor: const Color(0xFF1B4F72)),
    RenderingItem(id: 'rn2', title: 'Main Entry \u2014 Night', viewType: 'Exterior', created: DateTime(2025, 10, 20), status: 'Final', sizeBytes: 16200000, placeholderColor: const Color(0xFF0D2137)),
    RenderingItem(id: 'rn3', title: 'Aerial View \u2014 Northwest', viewType: 'Aerial', created: DateTime(2025, 11, 5), status: 'Client Review', sizeBytes: 22100000, placeholderColor: const Color(0xFF2E5A3A)),
    RenderingItem(id: 'rn4', title: 'Lobby Interior', viewType: 'Interior', created: DateTime(2026, 1, 12), status: 'Draft', sizeBytes: 14800000, placeholderColor: const Color(0xFF4A3728)),
    RenderingItem(id: 'rn5', title: 'Courtyard Detail', viewType: 'Detail', created: DateTime(2026, 2, 1), status: 'In Progress', sizeBytes: 8400000, placeholderColor: const Color(0xFF2C3E50)),
  ];

  static final asis = <AsiItem>[
    AsiItem(id: 'a1', number: 'ASI-001', subject: 'Revised lobby floor finish \u2014 change from porcelain to terrazzo', status: 'Issued', dateIssued: DateTime(2025, 12, 5), affectedSheets: 'A-101, A-501', issuedBy: 'James Rivera'),
    AsiItem(id: 'a2', number: 'ASI-002', subject: 'Add roof access hatch at grid D-6', status: 'Issued', dateIssued: DateTime(2026, 1, 10), affectedSheets: 'A-102, S-201', issuedBy: 'James Rivera'),
    AsiItem(id: 'a3', number: 'ASI-003', subject: 'Relocate electrical panel EP-2 per field condition', status: 'Issued', dateIssued: DateTime(2026, 1, 28), affectedSheets: 'E-101, E-102', issuedBy: 'Sarah Chen'),
    AsiItem(id: 'a4', number: 'ASI-004', subject: 'Revised grading at south parking area', status: 'Draft', dateIssued: DateTime(2026, 2, 12), affectedSheets: 'C-101, L-101', issuedBy: 'David Park'),
  ];

  static final spaceRequirements = <SpaceRequirement>[
    SpaceRequirement(id: 'sp1', roomName: 'Main Lobby', department: 'Public', programmedSF: 2400, designedSF: 2550, adjacency: 'Reception, Elevator Core', notes: 'Double-height ceiling required'),
    SpaceRequirement(id: 'sp2', roomName: 'Conference Room A', department: 'Admin', programmedSF: 600, designedSF: 580, adjacency: 'Executive Suite, Break Room'),
    SpaceRequirement(id: 'sp3', roomName: 'Conference Room B', department: 'Admin', programmedSF: 400, designedSF: 420, adjacency: 'Open Office'),
    SpaceRequirement(id: 'sp4', roomName: 'Open Office', department: 'Operations', programmedSF: 4800, designedSF: 4650, adjacency: 'Break Room, Restrooms', notes: '48 workstations minimum'),
    SpaceRequirement(id: 'sp5', roomName: 'Executive Suite', department: 'Admin', programmedSF: 1200, designedSF: 1180, adjacency: 'Conference Room A, Reception'),
    SpaceRequirement(id: 'sp6', roomName: 'Break Room / Kitchen', department: 'Support', programmedSF: 800, designedSF: 850, adjacency: 'Open Office, Restrooms'),
    SpaceRequirement(id: 'sp7', roomName: 'Server Room', department: 'IT', programmedSF: 300, designedSF: 320, adjacency: 'Electrical Room', notes: 'Dedicated HVAC, raised floor'),
    SpaceRequirement(id: 'sp8', roomName: 'Loading Dock', department: 'Service', programmedSF: 600, designedSF: 600, adjacency: 'Storage, Service Corridor'),
    SpaceRequirement(id: 'sp9', roomName: 'Restrooms (per floor)', department: 'Support', programmedSF: 500, designedSF: 520, adjacency: 'Break Room, Open Office', notes: 'ADA compliant'),
    SpaceRequirement(id: 'sp10', roomName: 'Storage / Janitor', department: 'Service', programmedSF: 200, designedSF: 180, adjacency: 'Loading Dock'),
  ];

  static final projectInfo = <ProjectInfoEntry>[
    ProjectInfoEntry(id: 'pi1', category: 'General', label: 'Project Name', value: 'Northstar Office Complex'),
    ProjectInfoEntry(id: 'pi2', category: 'General', label: 'Project Number', value: '2025-0847'),
    ProjectInfoEntry(id: 'pi3', category: 'General', label: 'Project Address', value: '1200 Commerce Blvd, Austin, TX 78701'),
    ProjectInfoEntry(id: 'pi4', category: 'General', label: 'Client', value: 'Northstar Development LLC'),
    ProjectInfoEntry(id: 'pi5', category: 'General', label: 'Architect of Record', value: 'Meridian Architecture'),
    ProjectInfoEntry(id: 'pi6', category: 'Codes & Standards', label: 'Building Code', value: 'IBC 2021'),
    ProjectInfoEntry(id: 'pi7', category: 'Codes & Standards', label: 'Energy Code', value: 'ASHRAE 90.1-2019'),
    ProjectInfoEntry(id: 'pi8', category: 'Codes & Standards', label: 'Fire Code', value: 'IFC 2021'),
    ProjectInfoEntry(id: 'pi9', category: 'Codes & Standards', label: 'Accessibility', value: 'ADA / TAS 2012'),
    ProjectInfoEntry(id: 'pi10', category: 'Zoning', label: 'Zoning Classification', value: 'C-2 Commercial'),
    ProjectInfoEntry(id: 'pi11', category: 'Zoning', label: 'FAR (Allowed / Designed)', value: '3.0 / 2.4'),
    ProjectInfoEntry(id: 'pi12', category: 'Zoning', label: 'Max Height', value: '85 ft (6 stories)'),
    ProjectInfoEntry(id: 'pi13', category: 'Zoning', label: 'Setbacks (F/S/R)', value: "15' / 10' / 20'"),
    ProjectInfoEntry(id: 'pi14', category: 'Site', label: 'Parcel Number', value: '04-2847-0012'),
    ProjectInfoEntry(id: 'pi15', category: 'Site', label: 'Lot Size', value: '2.8 acres (121,968 SF)'),
    ProjectInfoEntry(id: 'pi16', category: 'Site', label: 'Existing Use', value: 'Vacant / Previously C-store'),
  ];
}
