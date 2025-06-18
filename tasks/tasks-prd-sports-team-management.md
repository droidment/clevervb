R## Relevant Files

- `lib/main.dart` – Flutter app entry point and provider scope setup.
- `lib/models/user.dart` – User profile data model.
- `lib/models/team.dart` – Team entity model.
- `lib/models/game.dart` – Game entity model.
- `lib/models/attendance.dart` – Attendance/fee record model.
- `lib/services/supabase_service.dart` – Centralized Supabase client wrapper.
- `lib/services/auth_service.dart` – Google authentication & user profile logic.
- `lib/services/team_service.dart` – CRUD operations for teams, roster, invitations.
- `lib/services/game_service.dart` – CRUD operations for games & RSVPs.
- `lib/services/attendance_service.dart` – Attendance check-in & fee aggregation.
- `lib/pages/team_list_page.dart` – List of user teams.
- `lib/pages/team_detail_page.dart` – Roster view & team management.
- `lib/pages/create_team_page.dart` – Create/edit team form.
- `lib/pages/game_schedule_page.dart` – Game creation form.
- `lib/pages/game_detail_page.dart` – RSVP and attendance page for a single game.
- `lib/pages/discovery_page.dart` – Nearby game search UI.
- `lib/widgets/rsvp_button.dart` – Re-usable RSVP selector widget.
- `supabase/migrations/*.sql` – Database schema & RLS policies.
- `supabase/migrations/20240101120000_create_sports_team_tables.sql` – Initial table creation migration.
- `supabase/database_schema.md` – Comprehensive database design documentation.
- `test/**` – Unit and widget tests accompanying each service/page.
- `lib/config/secrets.yaml` – Supabase credentials and app configuration.
- `lib/config/env.dart` – Environment configuration and constants.

### Notes

- Keep tests adjacent to implementation files (`*.dart` and `*_test.dart`).
- Use `flutter test` to run all tests; specify individual paths to narrow scope during development.
- Database migration files should be versioned and applied via Supabase CLI.

## Tasks

- [x] 1.0 Set up Supabase backend schema & row-level security
  - [x] 1.1 Design tables: `st_users`, `st_teams`, `st_team_members`, `st_games`, `st_rsvps`, `st_attendances`, `st_fees`.
  - [x] 1.2 Write initial SQL migration scripts to create tables & relationships.
  - [x] 1.3 Enable PostGIS extension and add `location` column to `st_games`.
  - [x] 1.4 Define row-level security (RLS) policies for each table.
  - [x] 1.5 Seed development data (sample users, teams, games).
  - [x] 1.6 Configure Supabase keys & URLs in Flutter `secrets.yaml`.

- [x] 2.0 Implement Google authentication & user profile (age ≥18)
  - [x] 2.1 Enable Google provider in Supabase Auth dashboard.
  - [x] 2.2 Integrate `google_sign_in` & `supabase_flutter` packages for login/logout.
  - [x] 2.3 After first login, collect Date of Birth; block if age <18.
  - [x] 2.4 Persist user profile in `st_users` table via `supabase_service.dart`.
  - [x] 2.5 Expose `AuthStateProvider` using Riverpod; write unit tests.
  - NOTE: Missing Google OAuth client IDs in `env.dart` configuration

- [x] 3.0 Build Team management (create team, roster, invitations)
  - [x] 3.1 Implement `Team` model & `team_service.dart` with CRUD methods.
  - [x] 3.2 Build `team_list_page.dart` and `create_team_page.dart` UIs.
  - [x] 3.3 Display roster and allow organizer to remove players in `team_detail_page.dart`.
  - [x] 3.4 Create `st_invitations` table & generate join token deep links.
  - [x] 3.5 Integrate `share_plus` to send invites via email/text/WhatsApp.
  - [x] 3.6 Add unit and widget tests for team flows.

- [x] 4.0 Develop Game scheduling & RSVP flow
  - [x] 4.1 Implement `Game` model & `game_service.dart`.
  - [ ] 4.2 Build `game_schedule_page.dart` with form fields (venue, date/time, etc.).
  - [x] 4.3 Add capacity validation (8 volleyball / 2 pickleball).
  - [ ] 4.4 Create `rsvp_button.dart` widget supporting Yes/No/Yes+Guests.
  - [x] 4.5 Record RSVP timestamps for history tracking.
  - [ ] 4.6 Tests for scheduling & RSVP limits.
  - NOTE: Service layer complete, UI components still needed

- [x] 5.0 Implement Attendance tracking & fee aggregation
  - [x] 5.1 Provide self-check-in button (enabled game start-30 min after).
  - [x] 5.2 Save attendance records in `st_attendances` table with timestamp.
  - [x] 5.3 Automatically create fee entries in `st_fees` table per attendee based on game fee.
  - [x] 5.4 Implement weekly & monthly fee aggregation queries.
  - [ ] 5.5 Build organizer view to display attendance & outstanding fees.
  - [ ] 5.6 Write unit tests for fee aggregation logic.
  - NOTE: Service layer complete, UI components still needed

- [x] 6.0 Add Game discovery, deep links & WhatsApp sharing
  - [x] 6.1 Implement PostGIS geo-search query in `game_service.dart`.
  - [x] 6.2 Build `discovery_page.dart` with filters (sport, radius, date range).
  - [x] 6.3 Configure deep links for team/game routes via `deep_link_service.dart`.
  - [x] 6.4 Integrate WhatsApp share using `share_plus` for invite links.
  - [x] 6.5 Auto-add player to roster when they join a game via deep link.
  - [x] 6.6 Tests for deep link handling & discovery filters.
  - ✅ COMPLETE: Backend, UI, sharing, and comprehensive test coverage implemented 