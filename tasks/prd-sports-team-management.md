# Sports Team Management & Game Scheduling PRD

## 1. Introduction / Overview
Local volleyball and pickleball groups currently coordinate games, attendance, and fees ad-hoc via WhatsApp. This results in scheduling confusion, incomplete rosters, and manual fee tracking. The goal is to deliver a Flutter application (using Riverpod for state management and Supabase as the backend) that lets authenticated users create teams, schedule games, invite players, track RSVPs and attendance, and record per-player fees – all while optionally integrating WhatsApp deep links for invites.

## 2. Goals
1. Reduce scheduling overhead so organizers spend **<5 min** setting up a game.
2. Achieve **≥90 %** accurate attendance records through self-check-in.
3. Log **100 %** of fees owed per game and reach **≥80 %** collection rate within the first month.
4. Fill game rosters to capacity (8 for volleyball, 2 for pickleball) in **≥70 %** of scheduled games within 3 months.

## 3. User Stories
| ID | As a… | I want to… | So that… |
|----|-------|-----------|----------|
| US-1 | Authenticated player | create a new team | I can gather friends to play. |
| US-2 | Organizer | schedule a game with venue, date/time, court, max players, fee, & guest policy | players can RSVP early. |
| US-3 | Player | RSVP **Yes / No / Yes + #Guests** | the organizer knows attendance. |
| US-4 | Player | self-check-in on game day | my attendance is recorded accurately. |
| US-5 | Organizer | see a roster with RSVP & attendance status | I can plan line-ups and payments. |
| US-6 | Organizer | record fees owed per attendee automatically | I don't need spreadsheets. |
| US-7 | Organizer | invite contacts via email or text with deep link | they can join with one tap. |
| US-8 | Player | search for nearby games by sport, radius & date | I can quickly find matches to join. |
| US-9 | System | automatically add a player who joins a game to the team roster | roster stays up-to-date. |
| US-10 | Organizer | remove inactive players or those absent 10 straight games | keep roster current. |

## 4. Functional Requirements
1. **Authentication**
   1.1 The system must support Google Sign-In and store user age (≥18 enforcement).

2. **Team Management**
   2.1 Authenticated users can create a team (default role: Organizer).  
   2.2 Teams store name, sport (volleyball/pickleball), roster list.  
   2.3 Organizers can invite players via email/text; links must deep-link into the app's join flow.  
   2.4 Only one organizer role per team; no extra roles.

3. **Game Scheduling**
   3.1 Organizers can create a game with: date/time, venue address, court #, fee amount, max players (8 or 2), guest policy (allowed? max guests per player).  
   3.2 System prevents two games for the same team at overlapping times.

4. **RSVP Flow**
   4.1 Players (and guests) can RSVP Yes, No, or Yes + guest count.  
   4.2 RSVP changes are timestamped to enable "voted in / dropped out" history.

5. **Attendance (Game Day)**
   5.1 Players self-check-in via a button available from game start time until 30 min after.  
   5.2 Attendance list updates in real-time for the organizer.

6. **Fee Tracking**
   6.1 When a game is finalized, system records fee per attendee using the game's fee amount.  
   6.2 Fees aggregate weekly & monthly for organizer reporting.  
   6.3 No in-app payment processing in this phase; data storage only.

7. **Discovery**
   7.1 Users can search public teams/games by: sport type, radius (km/mi), date range.  
   7.2 Joining a game auto-adds the user to the team roster.

8. **Roster Maintenance**
   8.1 Organizer can manually remove any player.  
   8.2 System flags & auto-removes players absent for 10 consecutive games (configurable threshold).

9. **WhatsApp Integration**
   9.1 Invite links can be shared to WhatsApp using platform-specific share sheets.  
   9.2 No chat or message syncing; WhatsApp remains external.

10. **Compliance & Restrictions**
   10.1 Users under 18 cannot create an account.

## 5. Non-Goals (Out of Scope)
* Real-time score tracking, player statistics, rankings.
* In-app payment processing (Stripe, PayPal, etc.).
* Push notifications and chat/messaging modules.
* Dark mode & WCAG accessibility refinements.
* Multiple roles (e.g., coach, assistant) or multi-organizer hierarchy.

## 6. Design Considerations (Optional)
* Follow standard Material Design widgets in Flutter.  
* Simple color palette aligning with volleyball/pickleball theme.  
* Primary navigation: bottom navigation bar (Teams, Games, Discover, Profile).

## 7. Technical Considerations (Optional)
* **Frontend:** Flutter 3.x with Riverpod for state.  
* **Backend:** Supabase Postgres (row-level security) + Supabase Auth (Google).  
* Geo-queries via Supabase PostGIS extension for nearby search.  
* Deep linking: Firebase Dynamic Links or equivalent.  
* WhatsApp share via `share_plus` package.  
* Limit concurrent writes with Supabase row locks when RSVP list nears capacity.

## 8. Success Metrics
* ≥90 % self-check-in rate for players who RSVP "Yes."
* ≥80 % fee collection rate (recorded as paid externally) within 30 days. 
* ≥70 % of scheduled games reach full roster capacity. 
* Average game setup time by organizer ≤5 minutes.

## 9. Open Questions
1. Should organizers be able to override self-check-in (e.g., mark a player absent)?
2. What happens if a player brings more guests than allowed – block or warn?  
3. Is email verification required in addition to Google OAuth?  
4. What retention policy is needed for attendance & fee records (e.g., data older than 1 year)? 