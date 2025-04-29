# University Schedule App

A Flutter application that displays university class schedules with real-time updates, progress tracking, and offline caching.

## Features

- **Real-time Schedule Tracking**: See current/upcoming classes with countdown timers
- **Progress Indicators**: Visual progress bars showing how much of a class has passed
- **Offline Support**: Caches schedules and groups for offline access
- **Multi-day View**: Browse schedules by day of the week
- **Group Selection**: Choose from available student groups
- **Responsive UI**: Adapts to different screen sizes

## Technologies Used

- **Flutter**: Cross-platform framework
- **Supabase**: Backend service for group data
- **Shared Preferences**: Local caching
- **Intl Package**: Date/time formatting
- **Custom API Service**: For schedule data

## Installation

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio/Xcode (for mobile development)
- Supabase account (for backend)

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/BaYa06/mobile-test.git
   cd university-schedule-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure Supabase:
   - Create a `.env` file with your Supabase credentials
   - Add your Supabase URL and anon key

4. Run the app:
   ```bash
   flutter run
   ```

## Configuration

### Environment Variables

Create a `.env` file in the root directory with:

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
API_BASE_URL=your_schedule_api_url
```

### Supabase Setup

1. Create a `groups` table with a `name` column
2. Set up appropriate Row Level Security (RLS) policies

## Usage

1. **Launch the app** and select your student group from the dropdown
2. **Today's View** (default tab):
   - Shows classes for the current day
   - Displays real-time countdown/progress for each class
3. **Week View**:
   - Browse schedules by day of the week
   - Tap day buttons to switch between days
4. **Calendar View**:
   - (Future implementation) Monthly calendar with schedule integration

## Code Structure

```
lib/
├── models/
│   └── schedule.dart          # Schedule data model
├── services/
│   ├── api_service.dart       # API service for schedules
│   └── supabase_service.dart  # Supabase service for groups
├── screens/
│   └── home_screen.dart       # Main application screen
└── main.dart                  # App entry point
```

## Key Components

### Home Screen (`home_screen.dart`)

- **State Management**: Uses `StatefulWidget` for dynamic UI updates
- **Timer**: Updates UI every second for real-time progress
- **Bottom Navigation**: Three-tab interface (Today, Week, Calendar)
- **Modal Bottom Sheet**: Group selection interface

### Services

1. **SupabaseService**:
   - Manages group data retrieval
   - Handles Supabase connection

2. **ApiService**:
   - Fetches schedule data from custom API
   - Supports filtering by group and day

### Models

- **Schedule**: Data model for class information including:
  - Subject name
  - Time slot
  - Room number
  - Teacher name
  - Day of week

## API Endpoints

The app expects the following API structure:

- `GET /api/schedule?group={groupName}&day={dayName}`
  - Returns JSON array of schedule items
  - Sample response:
    ```json
    [
      {
        "subject": "Mathematics",
        "timeSlot": "09:00 - 10:30",
        "room": "A101",
        "teacher": "Dr. Smith",
        "day": "Monday"
      }
    ]
    ```

## Local Caching

The app implements two-level caching:

1. **Shared Preferences**:
   - Stores group list (`groups`)
   - Stores schedules (`schedule_$groupName$day`)

2. **Memory Cache**:
   - Maintains current schedule in state
   - Updates when new data is fetched

## Real-time Features

1. **Lesson Status**:
   - "Starts in Xm Ys" (before class)
   - "Ends in Xm Ys" (during class)
   - "Finished" (after class)

2. **Progress Bar**:
   - Visual indicator of class progress
   - Updates in real-time

## Error Handling

- Network errors fall back to cached data
- User-friendly error messages via SnackBar
- Loading indicators during data fetch

## Future Improvements

1. **Calendar Integration**:
   - Full monthly view with schedule
   - Event creation/editing

2. **Notifications**:
   - Class reminders
   - Schedule changes alerts

3. **User Accounts**:
   - Save favorite groups
   - Sync across devices

4. **Dark Mode**:
   - Theme support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

---

![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.36.43.png)
![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.36.32.png)
![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.35.23.png)
![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.35.13.png)
![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.35.02.png)
![Screenshot](https://github.com/BaYa06/mobile_test/blob/main/assets/Снимок%20экрана%202025-04-29%20в%2012.34.55.png)