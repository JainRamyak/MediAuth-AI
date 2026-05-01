# MediAuth AI — Progress Report

> Track your build progress here. Check off items as you complete them.

---

## Current Status

| Phase                     | Status         |
| ------------------------- | -------------- |
| Repo & Infrastructure     | 🟡 In Progress |
| Database & Prompts        | ⬜ Not Started |
| Agents 1–3 + LangGraph    | ⬜ Not Started |
| Agents 4–7 + Orchestrator | ⬜ Not Started |
| Frontend UI               | 🟡 In Progress |
| Testing                   | ⬜ Not Started |
| Deployment & Submission   | ⬜ Not Started |

---

## Day 1 Progress

### Phase 1A — Repository & Infrastructure

- [x] Create GitHub repository
- [x] Initialize frontend with Flutter (`mediauth_flutter`)
- [ ] Initialize backend (run commands from `build_plan.md`)
- [ ] Create `.env.example`
- [ ] Verify `/health` endpoint works (`http://localhost:8000/health`)
- [ ] Set up `docker-compose.yml`
- [ ] Confirm Docker container runs cleanly

### Phase 1B — Database & Prompt Config

- [ ] SQLAlchemy models defined (`Patient`, `AuthRequest`, `AuditLog`, `Claim`)
- [ ] Database tables created / migrations run
- [ ] `intake_prompt.yaml` created
- [ ] `medical_analysis_prompt.yaml` created
- [ ] `policy_prompt.yaml` created
- [ ] `justification_prompt.yaml` created
- [ ] `appeal_prompt.yaml` created
- [ ] `submission_prompt.yaml` created
- [ ] `claims_prompt.yaml` created

### Phase 1C — Agents 1–3 + LangGraph Skeleton

- [ ] Agent 1 (Intake) — accepts input, extracts patient profile to JSON
- [ ] Agent 2 (Medical Analysis) — assigns ICD-10/CPT codes, outputs clinical
      summary
- [ ] Agent 3 (Policy Intelligence) — ChromaDB set up, RAG working, gaps flagged
- [ ] LangGraph state machine wiring Agents 1 → 2 → 3
- [ ] Patient intake API tested end-to-end via Postman

---

## Day 2 Progress

### Phase 2A — Agents 4–7 + Orchestrator

- [ ] Agent 4 (Justification Writer) — generates clinical narrative letter
- [ ] Agent 5 (Submission & Monitor) — submits request, polls status, triggers
      appeal on denial
- [ ] Agent 6 (Denial & Appeal) — parses denial, writes counter-appeal, loops up
      to 3 levels
- [ ] Agent 7 (Claims Validation) — scans billing codes, assigns risk score
- [ ] Orchestrator — full state machine wired, branching logic complete, audit
      log active
- [ ] Human-in-the-loop escalation trigger working

### Phase 2B — Frontend UI (Flutter)

- [x] Patient Intake Form (`s05_treatment_request.dart`) complete
- [x] Authorization Status Dashboard (`s03_dashboard.dart`) complete
- [x] Prompt Editor page (`s13_prompt_editor.dart`) — reviewers can view/edit
      YAML prompts from UI
- [ ] Agent Pipeline Visualizer (`s07_agent_pipeline.dart`) — real-time agent
      progress
- [ ] Frontend connected to backend API

### Phase 2C — Testing

- [ ] pytest unit tests written (at least 1 per agent)
- [ ] Postman collection created with API integration tests
- [ ] Both test types confirmed passing

### Phase 2D — Deployment & Submission

- [ ] Backend deployed to Render.com
- [ ] Frontend deployed to Render.com or Vercel
- [ ] Live deployment URL confirmed accessible
- [ ] `README.md` written with setup instructions
- [ ] `architecture.png` added to repo
- [ ] Demo video recorded
- [ ] GitHub repo submitted

---

## Notes & Blockers

> Use this section to jot down issues, decisions made, or things to come back
> to.

```
[Date / Time] — Note here
```

---

## Quick Reference — What's Done vs What's Next

| # | Agent                      | Built? | Tested? |
| - | -------------------------- | ------ | ------- |
| 1 | Intake & History Agent     | ⬜     | ⬜      |
| 2 | Medical Analysis Agent     | ⬜     | ⬜      |
| 3 | Policy Intelligence Agent  | ⬜     | ⬜      |
| 4 | Justification Writer Agent | ⬜     | ⬜      |
| 5 | Submission & Monitor Agent | ⬜     | ⬜      |
| 6 | Denial & Appeal Agent      | ⬜     | ⬜      |
| 7 | Claims Validation Agent    | ⬜     | ⬜      |
| — | Master Orchestrator        | ⬜     | ⬜      |
