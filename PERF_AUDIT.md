# Project Dashboard — Performance Audit Report
## Date: Feb 22, 2026

### CRITICAL ISSUES FOUND

---

#### 🔴 ISSUE 1: DUPLICATE I: DRIVE SCAN (project_signals_provider.dart)
**File:** `state/project_signals_provider.dart`, lines 60-66
**Severity:** CRITICAL — doubles scan time on every refresh

`_allDrawingsForSignals` does its OWN `svc.scanFolderRecursive()` instead of 
watching the shared `allProjectFilesProvider`. This means EVERY signal 
recomputation triggers a full recursive I: drive scan.

**Fix:** Replace with derive from `allProjectFilesProvider`.

---

#### 🔴 ISSUE 2: G-SERIES PDF TEXT EXTRACTION ON MAIN THREAD
**File:** `state/folder_scan_providers.dart`, lines 1067-1200
**Severity:** HIGH — blocks UI during PDF parsing

`gSeriesCodesProvider` opens EVERY G-series PDF and extracts text on the 
main isolate. For projects with 10+ G-sheets, this can take 5-10 seconds 
and blocks all UI rendering.

**Fix:** Already cache-first, but cache check has a gap: when 
`backgroundFileDataProvider` has data, it ALWAYS re-parses. Should only 
re-parse when G-sheets actually changed.

---

#### 🔴 ISSUE 3: enrichProjectInfoProvider WATERFALL 
**File:** `state/folder_scan_providers.dart`, lines ~1435-1730
**Severity:** HIGH — sequential awaits create 3-5 second waterfall

This mega-provider does sequential:
1. await contractMetadataProvider
2. await projectDataSheetProvider (opens PDF)
3. await gSeriesCodesProvider (opens multiple PDFs)
4. await scannedSpreadsheetsProvider → parses each spreadsheet
5. HTTP geocoding call
6. JurisdictionEnricher

All sequential. Total: 3-8 seconds on first load.

**Fix:** Parallelize independent awaits.

---

#### 🟡 ISSUE 4: rootAccessibleProvider RE-CHECKS ON EVERY REFRESH
**File:** `state/folder_scan_providers.dart`, line 109
**Severity:** MEDIUM — I: drive accessibility check on every `scanRefreshProvider` bump

`ref.watch(scanRefreshProvider)` means Ctrl+R or background sync triggers 
a new `Directory.exists()` call over VPN.

**Fix:** Add `ref.keepAlive()` and only invalidate explicitly.

---

#### 🟡 ISSUE 5: projectDataSheetProvider LACKS keepAlive
**File:** `state/folder_scan_providers.dart`, line ~1230
**Severity:** MEDIUM — PDF re-parsed when navigating away and back

No `ref.keepAlive()` means the expensive PDF text extraction is discarded 
when no widget watches it, then re-runs when you return to that page.

**Fix:** Add `ref.keepAlive()`.

---

#### 🟡 ISSUE 6: EXCESSIVE debugPrint IN PRODUCTION
**File:** `state/folder_scan_providers.dart`, lines 1230-1280
**Severity:** LOW-MEDIUM — string formatting + I/O overhead

`projectDataSheetProvider` dumps 1500 chars of raw PDF text to debug 
console on every evaluation. In release builds, `debugPrint` is a no-op, 
but `toString()` and substring still execute.

**Fix:** Wrap in `assert(() { debugPrint(...); return true; }())` or 
remove entirely.

---

### FIXES APPLIED
