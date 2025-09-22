## Performance Profiling — We Decor Enquiries

Run the following commands and paste outputs below each section.

### 1) APK Size / Analyze Size (Android)
```bash
flutter build apk --analyze-size
```
Paste the summary tree and sizes here.

### 2) Web Profile (optional)
```bash
flutter run -d chrome --profile
```
Open DevTools > Performance. Capture a 10s scroll session on the enquiries list and export frame stats.

Record:
- Average FPS (target ≥ 55)
- Jank count (frames > 16ms)

### 3) Cold Start Timing (Android)
Use `flutter run --profile -d <device>` and capture startup logs:
```bash
flutter run --profile -d <device> | tee qa/scripts/cold_start.log
```
Extract cold start time. Target ≤ 2.5s on a mid-range device.

### 4) Firestore Fetch p95
Enable verbose timing logs around first list fetch. Capture p95 over 20 runs on Wi‑Fi. Target ≤ 800ms.

### 5) Notes
- Ensure release/profile mode for realistic numbers.
- Close background apps; stable network.
