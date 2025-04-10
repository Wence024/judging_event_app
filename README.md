# Judge App

## Overview
The Judge App is designed to streamline the judging and tabulation process for socio-cultural events through a mobile app tailored for event organizers and judges.

## Architecture Overview
- **Architecture Style**: Client-Backend Architecture using Flutter for frontend and Firebase for backend and offline support.
- **Technology Stack**:
  - **Frontend**: Flutter mobile app (Android/iOS)
  - **Backend**: Firebase (Firestore, Authentication, Storage)
  - **Export Tools**: Syncfusion PDF or pdf library
  - **Data Sync**: Firebase offline persistence

## Data Flow
1. Organizer sets up event data and parameters.
2. Judges authenticate and input scores.
3. Scores are saved to Firestore.
4. Tabulation logic calculates rankings.
5. Export functionality generates PDF/Excel.

## Key Workflows
1. **Event Setup (Organizer)**: Create event → Add criteria (with weights) → Add contestants
2. **Judging Flow (Judge)**: Login → View assigned event → Select contestant → Score by criteria → Submit
3. **Tabulation (System Logic)**: Calculate average/weighted score across judges → Apply any deductions → Generate final rankings (in real-time) → Manual overrides available for head organizer
4. **Export Results**: Organizer triggers export → Backend formats PDF/Excel → File saved locally or to Firebase Storage

## Modules and Responsibilities
- **Authentication Module**: Firebase Auth with role-based login (Admin / Organizer / Judge)
- **Event Management Module (Organizer)**: Create/Edit/Delete events, assign judges, define criteria with weights, input contestants and numbers, set deductions or manual overrides
- **Judging Module (Judge)**: Display assigned contestants only, input scores for each criterion, submit and lock scores, optional comment per score
- **Tabulation & Result Module**: Auto-calculate weighted scores, real-time average and ranking display, PDF/Excel export, filtering (by category, judge, etc.)
- **Audit & Logging**: Log all submissions and edits, versioning of scores, time-stamped activity logs per user

## Data Model (Simplified)
- **Collections**:
  - Users: { id, name, email, role, assignedEvents }
  - Events: { id, name, date, criteria[], judges[], contestants[] }
  - Criteria: { id, name, weight, maxScore }
  - Contestants: { id, name, number, eventId }
  - Scores: { contestantId, judgeId, criteriaScores[], total, timestamp }
  - Logs: { userId, action, targetId, timestamp }
- **Offline Support**: Firebase local cache with sync when back online, conflict resolution logic: latest timestamp or judge override

## UI/UX Design Plan
- **Wireframes**:
  - Judge View: Score submission (minimal layout, big buttons)
  - Organizer View: Tabbed layout (Criteria, Contestants, Results)
  - Tabulation View: Sortable, exportable tables
- **Accessibility**: Large tap targets, high contrast/dark mode, optional voice feedback

## Development Roadmap (2.5 Weeks)
- **Days 1–3**: Setup project, auth, basic navigation, wireframes
- **Days 4–6**: Event creation, criteria input, scoring screen
- **Days 7–9**: Tabulation system, organizer views, export to PDF
- **Days 10–17**: Testing, error handling, polish, offline testing

## Testing Strategy
- **Unit Tests**: Data validation, score calculation
- **Integration Tests**: Tabulation + export logic
- **UI Tests**: Manual + automated screen validation
- **Offline Tests**: Disconnected scoring, later sync

## Performance & Scalability
- Optimized queries (Firestore indexes)
- Local caching for fast access
- Lazy loading for large contestant lists
- Expected max load: 5 events × 10 judges

## Security & Access Control
- Firebase security rules per user role
- Data partitioning: per event/user
- Read/write restrictions for judges post-submission
- Logs for every scoring/editing action

## MVP Success Criteria
- Judges can log in and score contestants
- Organizers can define events and see tabulated results
- Tabulation logic outputs accurate rankings
- Judges can't modify scores after submission
- PDF export works with basic styling

## Risks and Mitigations
- **Internet drops during scoring**: Firebase offline persistence
- **Judges make mistakes after submission**: Score lock mechanism with override by organizer
- **Data breach**: Role-based access + secure rules + audit logs

## Tools & Technologies
- **Frontend**: Flutter
- **Backend**: Firebase Firestore, Auth, Storage
- **Export**: syncfusion_flutter_pdf, pdf
- **Versioning**: GitHub
- **Design**: Figma

## Future Enhancements
- Real-time scoreboard view for audience
- Role-specific dashboards
- Web-based admin panel
- Advanced AI scoring pattern detection
- Multi-round scoring with final rankings
- SMS/email notifications

## Latest Functionality Updates

### Admin Dashboard
- **Create Participants and Judges**: Admins can create participants and judges directly from the dashboard.
- **Assign Judges to Events**: Admins can assign judges to specific events.
- **View Event Results**: Each event card includes a button to view the results of that event, leading to the tabulation screen.

### Judge Dashboard
- **Event Assignment**: Judges can view events assigned to them based on their email.
- **Scoring**: Judges can score contestants by name and submit scores.

### Tabulation Screen
- **Average Scores**: Displays the average score for each contestant across all criteria and judges.
- **Individual Submissions**: Shows detailed submissions from each judge, including scores for each criterion and comments.

### Detailed Submissions Screen
- **Judge Submissions**: Allows viewing of individual judge submissions for each event, providing transparency and detailed insights.

These updates enhance the functionality and usability of the Judge App, providing a more comprehensive tool for event management and judging.

## References
- Firebase Docs (Auth, Firestore, Security)
- Flutter Docs (Widgets, PDF generation)
- UI Design Guidelines (Material Design)

## AI Assistance
- Use AI tools to generate dummy test data, ask code-related questions, help debug Firestore or Flutter widget issues, refactor code, or generate helper functions.

## Collaborator Roles
- **Dev A**: Frontend UI + Navigation
- **Dev B**: Backend + Firebase Setup
- **Dev C**: Tabulation Logic + Exports

Collaborators can rotate or help each other based on strengths to reduce overlapping work.

## Timeline & Tasks

### Days 1–3: Setup & Wireframe
- **Dev A**: Create Flutter project scaffold, set up basic navigation
- **Dev B**: Initialize Firebase project, set up Firebase Auth & Firestore
- **Dev C**: Help plan data schema, design wireframes

### Days 4–6: Core Features – Event & Scoring
- **Dev A**: UI for event creation screen, UI for judge scoring screen
- **Dev B**: Firestore integration for saving events, criteria, and scores
- **Dev C**: Create validation logic for score inputs, save contestant data

### Days 7–9: Tabulation & Export
- **Dev A**: Organizer tabulation UI, apply UI filters
- **Dev B**: Fetch all scores and compute totals
- **Dev C**: Implement tabulation logic, PDF export

### Days 10–17: Finalization, Testing, Polish
- **Dev A**: UI improvements, add success/failure states, dark mode
- **Dev B**: Firebase security rules, offline sync setup & testing
- **Dev C**: Export formatting polish, add filters to tabulation export

Shared Tasks:
- Test full scoring-to-export flow
- Bug fixes
- Optimize loading times and syncing
- Final deployment or build release for testing

## Optional Milestones & Sync Ideas
- **End of Day 3**: Project setup working, login flows ready
- **End of Day 6**: One full judging session from event > scoring > data saved
- **End of Day 9**: Can view computed rankings + export PDF
- **End of Day 17**: MVP tested and usable

Would you like a shared task board format (e.g., Notion/Trello layout) with this info so you can plug and play with your team?