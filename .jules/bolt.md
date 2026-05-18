## 2025-05-14 - Optimized Dashboard Rebuilds & Data Fetching
**Learning:** Monolithic build methods using `context.watch` on global providers cause entire screens to rebuild on any state change, even if the change is irrelevant to most widgets. This is particularly noticeable on low-end devices. Parallelizing Supabase queries and RPCs significantly reduces "Phase 2" loading time.
**Action:** Use `context.select` for specific properties and `Selector` widgets for surgical rebuilds of the UI tree. Consolidate and parallelize data fetching logic.
