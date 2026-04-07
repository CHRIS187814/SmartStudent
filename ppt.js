const pptxgen = require("pptxgenjs");
const pres = new pptxgen();
pres.layout = "LAYOUT_16x9";
pres.title = "Smart Student Task Prioritizer";

// ── THEME ─────────────────────────────────────────────────────────────────
const C = {
  bg:       "0A0A1A",   // deep navy-black
  bgLight:  "111130",   // slightly lighter navy
  card:     "16163A",   // card background
  accent:   "6C63FF",   // purple
  accent2:  "00D2A0",   // teal-green
  accent3:  "FFB800",   // amber
  accent4:  "FF4757",   // red-pink
  white:    "FFFFFF",
  muted:    "8888BB",
  border:   "2A2A5A",
};

const makeShadow = () => ({ type:"outer", color:"000000", blur:12, offset:3, angle:135, opacity:0.3 });

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 1 — TITLE
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  // Left accent bar
  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:0.08, h:5.625, fill:{ color: C.accent } });

  // Decorative circles (background)
  s.addShape(pres.shapes.OVAL, { x:7.2, y:-1.0, w:4.5, h:4.5, fill:{ color: C.accent, transparency:88 }, line:{ color: C.accent, width:1 } });
  s.addShape(pres.shapes.OVAL, { x:8.0, y:2.5,  w:3.0, h:3.0, fill:{ color: C.accent2, transparency:90 }, line:{ color: C.accent2, width:1 } });

  // Tag
  s.addShape(pres.shapes.RECTANGLE, { x:0.5, y:1.0, w:2.2, h:0.32, fill:{ color: C.accent, transparency:0 }, rectRadius:0.08 });
  s.addText("ML  ×  FLUTTER  ×  FASTAPI", { x:0.5, y:1.0, w:2.2, h:0.32, fontSize:8, color: C.white, bold:true, align:"center", valign:"middle", charSpacing:2, margin:0 });

  // Title
  s.addText("Smart Student", { x:0.5, y:1.5, w:7.5, h:1.0, fontSize:52, color: C.white, bold:true, fontFace:"Trebuchet MS", margin:0 });
  s.addText("Task Prioritizer", { x:0.5, y:2.38, w:7.5, h:0.85, fontSize:52, color: C.accent, bold:true, fontFace:"Trebuchet MS", margin:0 });

  // Subtitle
  s.addText("An ML-powered mobile app that prioritizes student tasks\nusing a Random Forest model, FastAPI backend & Supabase.", {
    x:0.5, y:3.35, w:6.5, h:0.85, fontSize:13, color: C.muted, fontFace:"Calibri", lineSpacingMultiple:1.4
  });

  // Bottom strip
  s.addShape(pres.shapes.RECTANGLE, { x:0, y:5.25, w:10, h:0.375, fill:{ color: C.bgLight } });
  s.addText("chrisblessan72@gmail.com  |  ML Project  |  2025", { x:0.5, y:5.27, w:9, h:0.32, fontSize:9, color: C.muted, align:"right", valign:"middle" });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 2 — PROBLEM STATEMENT
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  // Header bar
  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("THE PROBLEM", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });

  s.addText("Students struggle to prioritize tasks effectively.", {
    x:0.5, y:1.1, w:9, h:0.65, fontSize:26, color: C.white, bold:true, fontFace:"Trebuchet MS", margin:0
  });

  // 3 problem cards
  const problems = [
    { icon:"⏰", title:"Deadline Blindness", body:"Students treat all tasks equally — ignoring approaching deadlines until it's too late." },
    { icon:"📊", title:"Weight Unawareness", body:"A 40% final exam gets the same attention as a 5% quiz, causing poor grade outcomes." },
    { icon:"🔋", title:"Effort Mismatch", body:"High-effort tasks are started too late, leading to burnout and incomplete submissions." },
  ];

  problems.forEach((p, i) => {
    const x = 0.4 + i * 3.1;
    s.addShape(pres.shapes.RECTANGLE, { x, y:2.0, w:2.85, h:2.85, fill:{ color: C.card }, line:{ color: C.border, width:1 }, shadow: makeShadow() });
    s.addShape(pres.shapes.RECTANGLE, { x, y:2.0, w:2.85, h:0.06, fill:{ color: C.accent } });
    s.addText(p.icon,  { x, y:2.1, w:2.85, h:0.6,  fontSize:28, align:"center" });
    s.addText(p.title, { x:x+0.1, y:2.72, w:2.65, h:0.45, fontSize:13, color: C.white, bold:true, align:"center", fontFace:"Trebuchet MS" });
    s.addText(p.body,  { x:x+0.12, y:3.2, w:2.62, h:1.5, fontSize:11, color: C.muted, align:"center", fontFace:"Calibri", lineSpacingMultiple:1.4 });
  });

  // Solution teaser
  s.addShape(pres.shapes.RECTANGLE, { x:0.4, y:5.0, w:9.2, h:0.38, fill:{ color: C.accent, transparency:88 }, line:{ color: C.accent, width:1 } });
  s.addText("✦  Our solution: ML-predicted priority scores that rank tasks by urgency, weight & effort in real time.", {
    x:0.5, y:5.0, w:9.0, h:0.38, fontSize:11, color: C.accent, align:"center", valign:"middle", bold:true
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 3 — TECH STACK
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("TECH STACK", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });

  s.addText("Four layers. One intelligent system.", { x:0.5, y:1.05, w:9, h:0.5, fontSize:22, color: C.white, bold:true, fontFace:"Trebuchet MS" });

  const stack = [
    { layer:"Frontend",  tech:"Flutter (Dart)",       role:"Cross-platform mobile UI — iOS & Android",   color: C.accent,  icon:"📱" },
    { layer:"Backend",   tech:"FastAPI (Python)",      role:"REST API — routes tasks through ML model",   color: C.accent2, icon:"⚡" },
    { layer:"ML Engine", tech:"Scikit-Learn",          role:"Random Forest Regressor — scores 0.0→1.0",  color: C.accent3, icon:"🧠" },
    { layer:"Database",  tech:"Supabase (PostgreSQL)", role:"Real-time DB + Auth + Row Level Security",   color: C.accent4, icon:"🗄️" },
  ];

  stack.forEach((item, i) => {
    const y = 1.7 + i * 0.92;
    // Row bg
    s.addShape(pres.shapes.RECTANGLE, { x:0.4, y, w:9.2, h:0.78, fill:{ color: C.card }, line:{ color: C.border, width:0.5 } });
    // Accent left bar
    s.addShape(pres.shapes.RECTANGLE, { x:0.4, y, w:0.06, h:0.78, fill:{ color: item.color } });
    // Icon
    s.addText(item.icon, { x:0.55, y, w:0.6, h:0.78, fontSize:20, align:"center", valign:"middle" });
    // Layer label
    s.addText(item.layer, { x:1.22, y:y+0.06, w:1.4, h:0.3, fontSize:9, color: item.color, bold:true, charSpacing:2, margin:0 });
    // Tech name
    s.addText(item.tech,  { x:1.22, y:y+0.34, w:2.6, h:0.32, fontSize:14, color: C.white, bold:true, fontFace:"Trebuchet MS", margin:0 });
    // Role
    s.addText(item.role,  { x:4.3,  y:y+0.18, w:5.1, h:0.42, fontSize:12, color: C.muted, fontFace:"Calibri", valign:"middle" });
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 4 — ML PIPELINE
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("ML PIPELINE", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });
  s.addText("From raw task input to intelligent priority score.", { x:0.5, y:1.05, w:9, h:0.45, fontSize:20, color: C.white, bold:true, fontFace:"Trebuchet MS" });

  // Pipeline steps
  const steps = [
    { n:"01", label:"Task Input",      sub:"Name · Deadline\nWeight · Effort\nCategory",      color: C.accent  },
    { n:"02", label:"Feature Eng.",    sub:"Urgency Factor\nhours_norm\ncategory_weight",      color: C.accent2 },
    { n:"03", label:"Random Forest",   sub:"200 trees\nmax_depth=12\nR²=0.97",                color: C.accent3 },
    { n:"04", label:"Priority Score",  sub:"Output: 0.0→1.0\nNudge message\nDB update",       color: C.accent4 },
  ];

  const boxW = 1.9, boxH = 2.8, startX = 0.45, y = 1.7;

  steps.forEach((st, i) => {
    const x = startX + i * 2.42;
    s.addShape(pres.shapes.RECTANGLE, { x, y, w:boxW, h:boxH, fill:{ color: C.card }, line:{ color: st.color, width:1 }, shadow: makeShadow() });
    // Top color bar
    s.addShape(pres.shapes.RECTANGLE, { x, y, w:boxW, h:0.38, fill:{ color: st.color } });
    s.addText(st.n, { x, y, w:boxW, h:0.38, fontSize:16, color: C.white, bold:true, align:"center", valign:"middle", margin:0 });
    s.addText(st.label, { x:x+0.08, y:y+0.44, w:boxW-0.16, h:0.5, fontSize:13, color: C.white, bold:true, align:"center", fontFace:"Trebuchet MS" });
    s.addText(st.sub, { x:x+0.1, y:y+1.0, w:boxW-0.2, h:1.6, fontSize:11, color: C.muted, align:"center", lineSpacingMultiple:1.5 });

    // Arrow between boxes
    if (i < 3) {
      const ax = x + boxW + 0.05;
      s.addShape(pres.shapes.LINE, { x:ax, y:y+boxH/2, w:0.45, h:0, line:{ color: st.color, width:2 } });
      s.addText("▶", { x:ax+0.3, y:y+boxH/2-0.18, w:0.22, h:0.36, fontSize:11, color: st.color, align:"center", valign:"middle" });
    }
  });

  // Formula box
  s.addShape(pres.shapes.RECTANGLE, { x:0.4, y:4.72, w:9.2, h:0.65, fill:{ color: C.bgLight }, line:{ color: C.accent, width:1 } });
  s.addText("Urgency Formula:   Priority = (0.40 × urgency_factor) + (0.25 × hours_norm) + (0.20 × effort_norm) + (0.15 × category_weight)", {
    x:0.6, y:4.74, w:8.8, h:0.6, fontSize:11, color: C.accent, align:"center", valign:"middle", bold:true, fontFace:"Consolas"
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 5 — FOLDER STRUCTURE
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("FOLDER STRUCTURE", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });

  // Left column — tree
  s.addShape(pres.shapes.RECTANGLE, { x:0.4, y:1.1, w:4.5, h:4.25, fill:{ color: C.card }, line:{ color: C.border, width:0.5 } });
  s.addShape(pres.shapes.RECTANGLE, { x:0.4, y:1.1, w:4.5, h:0.38, fill:{ color: C.accent, transparency:20 } });
  s.addText("📁  smarttask/", { x:0.55, y:1.1, w:4.3, h:0.38, fontSize:12, color: C.white, bold:true, valign:"middle", margin:0 });

  const tree = [
    "  📁 backend/",
    "    📄 main.py",
    "    📄 schema.sql",
    "    📄 requirements.txt",
    "    🔒 .env",
    "  📁 ml/",
    "    📄 train_model.py",
    "    🤖 priority_model.joblib",
    "  📁 flutter_app/lib/",
    "    📄 main.dart",
    "    📁 screens/  (4 screens)",
    "    📁 services/ (2 services)",
  ];

  s.addText(tree.join("\n"), {
    x:0.55, y:1.55, w:4.2, h:3.7, fontSize:10.5, color: C.muted, fontFace:"Consolas", lineSpacingMultiple:1.55
  });

  // Right column — descriptions
  const desc = [
    { icon:"⚡", label:"backend/main.py",          note:"FastAPI — 5 REST routes, ML inference, auth middleware" },
    { icon:"🗄️", label:"backend/schema.sql",        note:"Supabase tables: tasks, profiles + RLS policies" },
    { icon:"🧠", label:"ml/train_model.py",         note:"2000-sample synthetic data → Random Forest → .joblib" },
    { icon:"📱", label:"flutter_app/lib/main.dart", note:"App entry, dark theme, routing (login → home)" },
    { icon:"🖥️", label:"screens/",                 note:"Dashboard, TaskMaster, Analytics, Login — 4 tabs" },
    { icon:"🔌", label:"services/",                note:"ApiService (HTTP) + AuthService (token storage)" },
  ];

  desc.forEach((d, i) => {
    const y = 1.1 + i * 0.7;
    s.addShape(pres.shapes.RECTANGLE, { x:5.1, y, w:4.5, h:0.6, fill:{ color: C.card }, line:{ color: C.border, width:0.5 } });
    s.addText(d.icon,  { x:5.15, y, w:0.45, h:0.6, fontSize:14, align:"center", valign:"middle" });
    s.addText(d.label, { x:5.65, y:y+0.04, w:3.8, h:0.25, fontSize:10, color: C.accent, bold:true, fontFace:"Consolas", margin:0 });
    s.addText(d.note,  { x:5.65, y:y+0.3, w:3.8, h:0.25, fontSize:10, color: C.muted, fontFace:"Calibri", margin:0 });
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 6 — FRONTEND WORKFLOW
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("FRONTEND WORKFLOW", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });
  s.addText("Flutter — 3 Tabs + Auth Screen", { x:0.5, y:1.05, w:9, h:0.45, fontSize:20, color: C.white, bold:true, fontFace:"Trebuchet MS" });

  const tabs = [
    { name:"Login Screen", icon:"🔐", color: C.muted,   points:["Email + Password fields","Sign up / Sign in toggle","JWT token saved to SharedPreferences","Auto-redirects if token exists"] },
    { name:"Dashboard",    icon:"📊", color: C.accent,  points:["Daily Focus card (top priority task)","Weekly heatmap (Red=heavy, Green=light)","ML nudge message displayed","Pull-to-refresh re-fetches scores"] },
    { name:"Task Master",  icon:"✅", color: C.accent2, points:["Add task form with date picker","Category chips + effort slider","Real-time priority score after save","Complete / Delete actions per task"] },
    { name:"Analytics",    icon:"📈", color: C.accent3, points:["Completion rate circular chart","Category breakdown bar chart","Critical alerts (score > 0.75)","Avg priority score per category"] },
  ];

  tabs.forEach((tab, i) => {
    const x = 0.35 + (i % 2) * 4.85;
    const y = 1.65 + Math.floor(i / 2) * 1.88;
    s.addShape(pres.shapes.RECTANGLE, { x, y, w:4.55, h:1.72, fill:{ color: C.card }, line:{ color: tab.color, width:1 }, shadow: makeShadow() });
    s.addShape(pres.shapes.RECTANGLE, { x, y, w:4.55, h:0.06, fill:{ color: tab.color } });
    s.addText(tab.icon + "  " + tab.name, { x:x+0.12, y:y+0.1, w:4.3, h:0.38, fontSize:13, color: C.white, bold:true, fontFace:"Trebuchet MS", margin:0 });
    tab.points.forEach((pt, j) => {
      s.addText([{ text: pt, options: { bullet: true } }], {
        x:x+0.15, y:y+0.52+j*0.28, w:4.2, h:0.28, fontSize:10.5, color: C.muted, fontFace:"Calibri"
      });
    });
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 7 — BACKEND WORKFLOW
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("BACKEND WORKFLOW", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent2, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });
  s.addText("FastAPI — 5 Routes + ML Inference", { x:0.5, y:1.05, w:9, h:0.45, fontSize:20, color: C.white, bold:true, fontFace:"Trebuchet MS" });

  const routes = [
    { method:"POST", path:"/login",              color:"FFB800", desc:"Validates email+password via Supabase Auth → returns JWT access token" },
    { method:"POST", path:"/signup",             color:"FFB800", desc:"Creates new user in Supabase Auth → returns JWT token" },
    { method:"POST", path:"/add-task",           color:"6C63FF", desc:"Receives task → computes features → ML scores → saves to Supabase tasks table" },
    { method:"GET",  path:"/dashboard",          color:"00D2A0", desc:"Fetches all tasks → re-scores with fresh hours → returns sorted list + analytics" },
    { method:"GET",  path:"/tasks",              color:"00D2A0", desc:"Returns all user tasks ordered by priority_score descending" },
    { method:"PATCH",path:"/tasks/{id}/complete",color:"FF4757", desc:"Updates task status to Completed in the database" },
  ];

  routes.forEach((r, i) => {
    const y = 1.62 + i * 0.63;
    s.addShape(pres.shapes.RECTANGLE, { x:0.4, y, w:9.2, h:0.54, fill:{ color: C.card }, line:{ color: C.border, width:0.5 } });
    s.addShape(pres.shapes.RECTANGLE, { x:0.4, y, w:1.0, h:0.54, fill:{ color: r.color, transparency:15 } });
    s.addText(r.method, { x:0.4, y, w:1.0, h:0.54, fontSize:10, color: C.bg, bold:true, align:"center", valign:"middle", margin:0 });
    s.addText(r.path,   { x:1.5, y:y+0.04, w:2.5, h:0.25, fontSize:11, color: C.white, bold:true, fontFace:"Consolas", margin:0 });
    s.addText(r.desc,   { x:1.5, y:y+0.28, w:7.9, h:0.22, fontSize:10, color: C.muted, fontFace:"Calibri", margin:0 });
  });

  // Auth note
  s.addShape(pres.shapes.RECTANGLE, { x:0.4, y:5.4, w:9.2, h:0.32, fill:{ color: C.bgLight }, line:{ color: C.accent2, width:0.5 } });
  s.addText("🔒  All routes except /login and /signup require:   Authorization: Bearer <JWT token>   (validated via Supabase Auth)", {
    x:0.5, y:5.41, w:9.0, h:0.3, fontSize:10, color: C.accent2, align:"center", valign:"middle", fontFace:"Consolas"
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 8 — FULL SYSTEM ARCHITECTURE
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("SYSTEM ARCHITECTURE", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent3, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });
  s.addText("Client → Server → ML → Database flow.", { x:0.5, y:1.05, w:9, h:0.4, fontSize:18, color: C.white, bold:true, fontFace:"Trebuchet MS" });

  // 4 layer boxes
  const layers = [
    { label:"Flutter App",     sub:"iOS / Android",              color: C.accent,  icon:"📱", x:0.3  },
    { label:"FastAPI Server",  sub:"uvicorn · Python",           color: C.accent2, icon:"⚡", x:2.85 },
    { label:"ML Model",        sub:"Random Forest .joblib",      color: C.accent3, icon:"🧠", x:5.4  },
    { label:"Supabase",        sub:"PostgreSQL + Auth",          color: C.accent4, icon:"🗄️", x:7.95 },
  ];

  layers.forEach((l) => {
    s.addShape(pres.shapes.RECTANGLE, { x:l.x, y:1.58, w:2.3, h:2.2, fill:{ color: C.card }, line:{ color: l.color, width:1.5 }, shadow: makeShadow() });
    s.addShape(pres.shapes.RECTANGLE, { x:l.x, y:1.58, w:2.3, h:0.06, fill:{ color: l.color } });
    s.addText(l.icon,  { x:l.x, y:1.68, w:2.3, h:0.65, fontSize:26, align:"center" });
    s.addText(l.label, { x:l.x+0.08, y:2.38, w:2.14, h:0.4,  fontSize:13, color: C.white, bold:true, align:"center", fontFace:"Trebuchet MS" });
    s.addText(l.sub,   { x:l.x+0.08, y:2.78, w:2.14, h:0.32, fontSize:10, color: C.muted, align:"center" });
  });

  // Arrows between layers — drawn below the boxes
  const arrowData = [
    { x:2.62, label:"HTTP REST",      color: C.accent  },
    { x:5.18, label:"Feature Vectors", color: C.accent2 },
    { x:7.72, label:"Read / Write",    color: C.accent3 },
  ];
  arrowData.forEach(a => {
    s.addShape(pres.shapes.LINE, { x:a.x, y:2.68, w:0.2, h:0, line:{ color: a.color, width:2 } });
    s.addText("▶", { x:a.x+0.02, y:2.52, w:0.22, h:0.32, fontSize:13, color: a.color, align:"center", valign:"middle" });
    s.addText(a.label, { x:a.x-0.28, y:3.95, w:0.8, h:0.28, fontSize:8, color: a.color, align:"center" });
  });

  // Data flow steps
  const flows = [
    "1  User opens app → Login screen → JWT token issued by Supabase",
    "2  User adds task → Flutter sends POST /add-task → FastAPI runs ML inference",
    "3  ML model outputs priority score (0–1) + nudge message → saved to Supabase",
    "4  GET /dashboard → fresh scores re-calculated → sorted task list returned to Flutter",
    "5  Alerts fire when score > 0.85 AND status = Pending → push notification",
  ];

  s.addShape(pres.shapes.RECTANGLE, { x:0.3, y:3.92, w:9.4, h:1.5, fill:{ color: C.bgLight }, line:{ color: C.border, width:0.5 } });

  flows.forEach((f, i) => {
    s.addText(f, { x:0.45, y:3.98 + i*0.275, w:9.1, h:0.27, fontSize:10.5, color: i===0 ? C.white : C.muted, fontFace:"Calibri" });
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 9 — ALERT SYSTEM + DATASET
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:1.0, fill:{ color: C.bgLight } });
  s.addText("ALERT SYSTEM  &  DATASET", { x:0.5, y:0, w:9, h:1.0, fontSize:11, color: C.accent4, bold:true, align:"left", valign:"middle", charSpacing:3, margin:0 });

  // Left — Alert System
  s.addShape(pres.shapes.RECTANGLE, { x:0.3, y:1.1, w:4.55, h:4.3, fill:{ color: C.card }, line:{ color: C.accent4, width:1 } });
  s.addShape(pres.shapes.RECTANGLE, { x:0.3, y:1.1, w:4.55, h:0.42, fill:{ color: C.accent4, transparency:15 } });
  s.addText("🔔  Alert System", { x:0.42, y:1.1, w:4.3, h:0.42, fontSize:14, color: C.white, bold:true, valign:"middle", fontFace:"Trebuchet MS" });

  const alerts = [
    { type:"🚨 Critical",    rule:"score > 0.85 AND Pending",            action:"Push notification every 2 hours" },
    { type:"⚡ Contextual",  rule:"10:00 AM = peak focus time",           action:"Suggests tackling top task now" },
    { type:"⏱️ Buffer",      rule:"24h before ML-predicted completion",   action:"Early warning before actual deadline" },
  ];

  alerts.forEach((a, i) => {
    const y = 1.68 + i * 1.22;
    s.addShape(pres.shapes.RECTANGLE, { x:0.45, y, w:4.25, h:1.08, fill:{ color: C.bgLight }, line:{ color: C.border, width:0.5 } });
    s.addText(a.type,   { x:0.55, y:y+0.06, w:4.0, h:0.28, fontSize:12, color: C.accent4, bold:true, margin:0 });
    s.addText("Rule: " + a.rule, { x:0.55, y:y+0.36, w:4.0, h:0.24, fontSize:10, color: C.muted, margin:0 });
    s.addText("→ " + a.action,  { x:0.55, y:y+0.6,  w:4.0, h:0.24, fontSize:10, color: C.white, margin:0 });
  });

  // Right — Dataset
  s.addShape(pres.shapes.RECTANGLE, { x:5.15, y:1.1, w:4.55, h:4.3, fill:{ color: C.card }, line:{ color: C.accent3, width:1 } });
  s.addShape(pres.shapes.RECTANGLE, { x:5.15, y:1.1, w:4.55, h:0.42, fill:{ color: C.accent3, transparency:15 } });
  s.addText("📊  Training Dataset", { x:5.27, y:1.1, w:4.3, h:0.42, fontSize:14, color: C.white, bold:true, valign:"middle", fontFace:"Trebuchet MS" });

  s.addText("Current: Synthetic Data", { x:5.27, y:1.65, w:4.2, h:0.32, fontSize:12, color: C.accent3, bold:true });
  s.addText("2,000 programmatically generated records\nusing NumPy random distributions.\nR² = 0.97  |  RMSE ≈ 0.03", {
    x:5.27, y:1.98, w:4.2, h:0.75, fontSize:10.5, color: C.muted, lineSpacingMultiple:1.5
  });

  s.addText("Upgrade Path: Real-World Data", { x:5.27, y:2.88, w:4.2, h:0.32, fontSize:12, color: C.accent2, bold:true });
  const datasets = [
    "UCI Student Performance (649 students)",
    "Open University Analytics (32K students)",
    "Kaggle Student Habits Dataset (1K records)",
  ];
  datasets.forEach((d, i) => {
    s.addText([{ text: d, options: { bullet: true } }], {
      x:5.27, y:3.26+i*0.36, w:4.2, h:0.34, fontSize:10.5, color: C.muted
    });
  });

  s.addShape(pres.shapes.RECTANGLE, { x:5.27, y:4.42, w:4.1, h:0.7, fill:{ color: C.bgLight }, line:{ color: C.accent2, width:0.5 } });
  s.addText("Real data would capture genuine\nstudent urgency patterns & behaviors.", {
    x:5.35, y:4.44, w:3.95, h:0.65, fontSize:10, color: C.accent2, align:"center", valign:"middle", lineSpacingMultiple:1.4
  });
}

// ══════════════════════════════════════════════════════════════════════════
// SLIDE 10 — THANK YOU
// ══════════════════════════════════════════════════════════════════════════
{
  const s = pres.addSlide();
  s.background = { color: C.bg };

  s.addShape(pres.shapes.OVAL, { x:3.0, y:-1.5, w:7.0, h:7.0, fill:{ color: C.accent, transparency:93 }, line:{ color: C.accent, width:0.5 } });
  s.addShape(pres.shapes.OVAL, { x:-2.0, y:2.0, w:5.0, h:5.0, fill:{ color: C.accent2, transparency:94 }, line:{ color: C.accent2, width:0.5 } });
  s.addShape(pres.shapes.RECTANGLE, { x:0, y:0, w:10, h:0.06, fill:{ color: C.accent } });
  s.addShape(pres.shapes.RECTANGLE, { x:0, y:5.565, w:10, h:0.06, fill:{ color: C.accent2 } });

  s.addText("Thank You", { x:1, y:1.3, w:8, h:1.2, fontSize:56, color: C.white, bold:true, align:"center", fontFace:"Trebuchet MS" });
  s.addText("Smart Student Task Prioritizer", { x:1, y:2.45, w:8, h:0.5, fontSize:18, color: C.accent, align:"center", fontFace:"Trebuchet MS" });

  // Summary pills
  const pills = ["Flutter", "FastAPI", "Random Forest", "Supabase", "ML-Powered"];
  pills.forEach((p, i) => {
    const pw = 1.5, totalW = pills.length * pw + (pills.length-1)*0.18;
    const sx = (10 - totalW)/2 + i*(pw+0.18);
    s.addShape(pres.shapes.RECTANGLE, { x:sx, y:3.15, w:pw, h:0.38, fill:{ color: C.bgLight }, line:{ color: C.border, width:0.5 } });
    s.addText(p, { x:sx, y:3.15, w:pw, h:0.38, fontSize:10, color: C.muted, align:"center", valign:"middle", bold:true });
  });

  s.addText("Built in 1 day  ·  Full-stack ML mobile application", {
    x:1, y:3.75, w:8, h:0.38, fontSize:13, color: C.muted, align:"center"
  });

  // QR / contact box
  s.addShape(pres.shapes.RECTANGLE, { x:3.0, y:4.3, w:4.0, h:0.85, fill:{ color: C.card }, line:{ color: C.accent, width:1 } });
  s.addText("chrisblessan72@gmail.com", { x:3.0, y:4.3, w:4.0, h:0.85, fontSize:13, color: C.accent, align:"center", valign:"middle", bold:true });
}

// ── WRITE FILE ────────────────────────────────────────────────────────────
pres.writeFile({ fileName: "/home/claude/ppt/SmartStudent_Presentation.pptx" })
  .then(() => console.log("✅ Done: SmartStudent_Presentation.pptx"))
  .catch(e => console.error("Error:", e));