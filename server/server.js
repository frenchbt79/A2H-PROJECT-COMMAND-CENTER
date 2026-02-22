/**
 * Project Command Center — Local File-System API
 * 
 * Runs on the Windows machine alongside the web server.
 * Both the desktop browser and iPhone hit this for folder scanning,
 * file opening, and project path resolution.
 * 
 * Endpoints:
 *   GET  /api/health
 *   GET  /api/scan?path=<relative>&extensions=.pdf&nameStartsWith=a&latestPerSheet=true&recursive=true
 *   GET  /api/scan-keywords?keywords=contract,scope
 *   GET  /api/root-accessible
 *   GET  /api/project-path
 *   POST /api/project-path  { "path": "I:\\2024\\24402" }
 *   POST /api/open-file     { "fullPath": "..." }
 *   POST /api/open-folder   { "fullPath": "..." }
 */

const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { execFile } = require('child_process');

const app = express();
app.use(cors());
app.use(express.json());

// ── State ────────────────────────────────────────────────
let projectPath = 'I:\\2024\\24402';

// ── Ignored files / extensions (mirrors Dart) ────────────
const IGNORED_FILES = new Set([
  'desktop.ini', '.ds_store', '.thumbs', '.spotlight-v100',
  '.trashes', '.fseventsd', '.temporaryitems',
]);
const IGNORED_EXTENSIONS = new Set([
  '.zip', '.rar', '.7z', '.tar', '.gz',
  '.dwg', '.dxf', '.sqlite', '.mdb',
]);

function isIgnored(filename) {
  const lower = filename.toLowerCase();
  if (IGNORED_FILES.has(lower)) return true;
  if (lower.startsWith('.')) return true;
  if (lower.startsWith('~$')) return true;
  const ext = path.extname(lower);
  if (IGNORED_EXTENSIONS.has(ext)) return true;
  return false;
}

// ── Sheet number extraction (mirrors Dart regex) ─────────
function sheetNumber(filename) {
  const dot = filename.lastIndexOf('.');
  const base = dot > 0 ? filename.substring(0, dot) : filename;
  const match = base.match(/^([A-Za-z]{1,3}\d[\d.\-]*[A-Za-z]?)/);
  if (match) return match[1].toLowerCase();
  return base.toLowerCase();
}

// ── Recursive file walker ────────────────────────────────
async function walkDir(dirPath, recursive = true) {
  const results = [];
  try {
    const entries = await fs.promises.readdir(dirPath, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dirPath, entry.name);
      if (entry.isDirectory() && recursive) {
        const sub = await walkDir(fullPath, true);
        results.push(...sub);
      } else if (entry.isFile() && !isIgnored(entry.name)) {
        try {
          const stat = await fs.promises.stat(fullPath);
          results.push({
            name: entry.name,
            fullPath,
            relativePath: fullPath.replace(projectPath + '\\', ''),
            sizeBytes: stat.size,
            modified: stat.mtime.toISOString(),
            extension: path.extname(entry.name),
          });
        } catch (_) { /* skip unreadable */ }
      }
    }
  } catch (_) { /* dir not accessible */ }
  return results;
}

// ── Keep latest per sheet ────────────────────────────────
function keepLatestPerSheet(files) {
  const map = new Map();
  for (const f of files) {
    const sheet = sheetNumber(f.name);
    const existing = map.get(sheet);
    if (!existing || new Date(f.modified) > new Date(existing.modified)) {
      map.set(sheet, f);
    }
  }
  return Array.from(map.values());
}

// ── Format file size ─────────────────────────────────────
function sizeLabel(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1048576) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1048576).toFixed(1)} MB`;
}

// ═══════════════════════════════════════════════════════════
// ROUTES
// ═══════════════════════════════════════════════════════════

app.get('/api/health', (req, res) => {
  res.json({ ok: true, projectPath, timestamp: new Date().toISOString() });
});

app.get('/api/project-path', (req, res) => {
  res.json({ path: projectPath });
});

app.post('/api/project-path', (req, res) => {
  if (req.body.path) {
    projectPath = req.body.path;
  }
  res.json({ path: projectPath });
});

app.get('/api/root-accessible', async (req, res) => {
  try {
    await fs.promises.access(projectPath);
    res.json({ accessible: true });
  } catch {
    res.json({ accessible: false });
  }
});

// Main scan endpoint — mirrors FolderScanService.scanFolder / scanFolderRecursive
app.get('/api/scan', async (req, res) => {
  const relativePath = req.query.path || '';
  const extensions = req.query.extensions ? req.query.extensions.split(',') : [];
  const nameStartsWith = req.query.nameStartsWith || null;
  const nameContains = req.query.nameContains || null;
  const latestPerSheet = req.query.latestPerSheet === 'true';
  const recursive = req.query.recursive !== 'false'; // default true

  const fullDir = path.join(projectPath, relativePath);

  try {
    await fs.promises.access(fullDir);
  } catch {
    return res.json({ files: [], error: `Path not accessible: ${fullDir}` });
  }

  let files = await walkDir(fullDir, recursive);

  // Extension filter
  if (extensions.length > 0) {
    const extSet = new Set(extensions.map(e => e.toLowerCase()));
    files = files.filter(f => extSet.has(f.extension.toLowerCase()));
  }

  // Name starts-with filter (case-insensitive)
  if (nameStartsWith) {
    const prefix = nameStartsWith.toLowerCase();
    files = files.filter(f => f.name.toLowerCase().startsWith(prefix));
  }

  // Name contains filter
  if (nameContains) {
    const needle = nameContains.toLowerCase();
    files = files.filter(f => f.name.toLowerCase().includes(needle));
  }

  // Latest per sheet
  if (latestPerSheet) {
    files = keepLatestPerSheet(files);
  }

  // Add sheet number and size label to each file
  files = files.map(f => ({
    ...f,
    sheet: sheetNumber(f.name),
    sizeLabel: sizeLabel(f.sizeBytes),
  }));

  // Sort by modified desc
  files.sort((a, b) => new Date(b.modified) - new Date(a.modified));

  res.json({ files, count: files.length });
});

// Keyword scan — mirrors FolderScanService.scanByKeywords
app.get('/api/scan-keywords', async (req, res) => {
  const keywords = req.query.keywords ? req.query.keywords.split(',') : [];
  if (keywords.length === 0) return res.json({ files: [], count: 0 });

  try {
    await fs.promises.access(projectPath);
  } catch {
    return res.json({ files: [], error: 'Project root not accessible' });
  }

  let files = await walkDir(projectPath, true);
  files = files.filter(f => {
    const lower = f.name.toLowerCase();
    return keywords.some(kw => lower.includes(kw.toLowerCase()));
  });

  files = files.map(f => ({
    ...f,
    sizeLabel: sizeLabel(f.sizeBytes),
  }));

  files.sort((a, b) => new Date(b.modified) - new Date(a.modified));
  res.json({ files, count: files.length });
});

// Open file (Windows only — desktop convenience)
app.post('/api/open-file', (req, res) => {
  const { fullPath } = req.body;
  if (!fullPath) return res.status(400).json({ error: 'fullPath required' });
  execFile('cmd', ['/c', 'start', '', fullPath], (err) => {
    res.json({ ok: !err, error: err?.message });
  });
});

// Open containing folder in Explorer
app.post('/api/open-folder', (req, res) => {
  const { fullPath } = req.body;
  if (!fullPath) return res.status(400).json({ error: 'fullPath required' });
  execFile('explorer', ['/select,', fullPath], (err) => {
    res.json({ ok: !err, error: err?.message });
  });
});

// Count all files in project
app.get('/api/count-files', async (req, res) => {
  try {
    const files = await walkDir(projectPath, true);
    res.json({ count: files.length });
  } catch {
    res.json({ count: 0 });
  }
});

// ── Start server ─────────────────────────────────────────
const PORT = process.env.PORT || 3456;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`\n  ╔══════════════════════════════════════════╗`);
  console.log(`  ║  Project Command Center — File API       ║`);
  console.log(`  ║  http://localhost:${PORT}                  ║`);
  console.log(`  ║  Project: ${projectPath.substring(0, 28).padEnd(28)} ║`);
  console.log(`  ║  LAN: http://0.0.0.0:${PORT} (iPhone)      ║`);
  console.log(`  ╚══════════════════════════════════════════╝\n`);
});
