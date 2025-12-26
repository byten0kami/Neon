# 🔮 NEON
> *System Online. Neural Link Established.*

**Neon** is a next-generation personal life assistant built with **SwiftUI**, wrapped in a stunning **Cyberpunk/Sci-Fi interface**. It's not just a to-do list; it's a proactive digital companion that manages your schedule, monitors your habits, and interacts with you through a persistent AI personality.

---

## ⚡️ Visual Identity
Neon is designed to feel like a piece of futuristic hardware.
*   **Holographic UI**: CRT scanlines, chromatic aberration, and digital noise.
*   **Typography**: *Orbitron* for headers, *Rajdhani* for data, and *Share Tech Mono* for code.
*   **Dynamic Glow**: Elements pulse and react to interaction.
*   **Easter Eggs**: Yes, there is a flying Nyan Cat. 🐱🚀

---

## 🧩 Core Systems

### 🎮 CMD (Command Center)
The central timeline of your day.
*   **Universal Cards**: A unified interface for Tasks, Insights, Suggestions, and Events.
*   **Smart Actions**: Context-aware buttons for every item (Complete, Reschedule, Delegate).
*   **Decorators**: Visual indicators for priority, status, and type.

### 🧠 NEURAL (Neural Link)
Direct interface with the system's AI core.
*   **Context-Aware Chat**: Discuss your schedule, ask for advice, or just chat.
*   **Memory**: The AI remembers previous context to provide better assistance.
*   **Powered by OpenRouter**: Flexible integration with top-tier LLMs.

### 💊 PROTO (Bio-Kernel)
Health and habit tracking subsystem.
*   **Routine Monitoring**: Track medications, hydration, and daily protocols.
*   **Vitals**: Integration with health data (planned).

### 📊 LOG (System Logs)
Historical data and analytics.
*   **Streaks & Stats**: Visualizing your productivity and adherence.
*   **Retroactive Analysis**: See what you accomplished and when.

### ⚙️ CFG (Configuration)
System settings and personalization.
*   **Secrets Management**: Secure API key handling.
*   **Profile Customization**: Tailor the experience to your needs.

---

## 🎴 Cards System

The **Universal Timeline Card** is the core UI component that powers the CMD timeline. It's a flexible, decorator-based system that adapts its appearance and behavior based on task type and state.

### Card Types

Neon uses five distinct card types, each with its own color scheme and action buttons:

| Type | Badge | Color | Purpose | Actions |
|------|-------|-------|---------|---------|
| **TASK** | `TASK` | Lime | Standard to-do items | DONE, SKIP |
| **RMD** | `RMD` | Amber | Time-based reminders | DONE, DEFER |
| **INFO** | `INFO` | Cyan | System notifications | ACK |
| **INSIGHT** | `INSIGHT` | Purple | AI-generated suggestions | ACCEPT, KILL |
| **ASAP** | `ASAP` | Red | Urgent/critical tasks | EXECUTE |

### Card Anatomy

Each card consists of several visual layers:

```
┌─────────────────────────────────────┐
│ ● ─────────────────────────────────│  ← Timeline Connector (dot + line)
│ ┃ [BADGE] [recur]        🕐 12:30  │  ← Header (type, recurrence, time)
│ ┃ Task Title                        │  ← Title (white with glow)
│ ┃ Optional description text         │  ← Description (slate gray)
│ ┃ ─────────────────────────────────│  ← Divider
│ ┃ [✓ DONE] [→ SKIP]                │  ← Action Buttons
└─────────────────────────────────────┘
```

### Visual States

Cards adapt their appearance based on state:

- **Active**: Full color accent, glowing border, white title with glow effect
- **Completed**: Grayed out (slate), scanline overlay, reduced opacity, shows completion time
- **Deferred**: Amber clock icon, updated scheduled time
- **Overdue**: Blinking animation (opacity pulses between 1.0 and 0.5)
- **Recurring**: Shows recurrence pattern (e.g., "Daily", "Every 60 min")

### Time Display Logic

The card intelligently determines what time to display:

1. **Completed tasks**: Shows actual completion time (`completedAt`)
2. **Scheduled tasks**: Shows `scheduledTime` (one-time events)
3. **Daily recurring**: Shows `dailyTime` (e.g., "09:00")
4. **Interval recurring**: Calculates next occurrence based on `lastTriggered + intervalMinutes`
5. **Deferred tasks**: Shows new scheduled time with amber clock icon

### Action Buttons

Action buttons are context-aware and type-specific:

- **Positive actions** (left): Filled background, checkmark/execute icon, accent color
- **Negative actions** (right): Outlined only, dismiss/skip icon, slate gray
- **Icons**: All buttons include SF Symbols for quick recognition
- **Behavior**: Buttons are hidden for completed tasks

### Sorting & Priority

The timeline automatically sorts cards by:

1. **ASAP tasks first** (always at the top)
2. **Effective time** (earliest scheduled time)
3. **Priority level** (urgent > high > normal > low)
4. **Tasks with time** come before tasks without time

### Decorator Pattern Architecture

The card system uses the **Base + Decorator** pattern:

- **Base**: `UniversalTimelineCard` - Generic, reusable card view
- **Config**: `CardConfig` - Configuration object that defines appearance and behavior
- **Decorators**: `TimelineCardAction` - Attachable action buttons
- **Components**: `CardBadge`, `CardActionButton`, `TimelineConnector` - Reusable sub-components

This pattern allows:
- ✅ Single source of truth for card UI
- ✅ Easy addition of new card types
- ✅ Consistent styling across all cards
- ✅ Separation of presentation from business logic

### Recurring Task Behavior

Recurring tasks have special handling:

- When completed, they show a **1-second visual feedback** (marked as completed)
- After 1 second, they automatically **reset to recurring status**
- The `lastTriggered` timestamp is updated to calculate the next occurrence
- Notifications are rescheduled automatically

---

## 🛠 Architecture

The project follows a modular, scalable architecture emphasizing separation of concerns and reusability.

```text
Neon/
├── NeonTrackerApp.swift       # Application Entry Point
├── Design/                    # The "skin" of the app (Colors, Fonts, Styles)
├── Models/                    # Data logic (Tasks, Schedule, User Profile)
├── Services/                  # Business logic (AI Service, Storage)
├── Views/
│   ├── Home/                  # "CMD" Tab - The main timeline
│   ├── Chat/                  # "NEURAL" Tab - AI Interface
│   ├── Protocols/             # "BIO" Tab - Habit tracking
│   ├── History/               # "LOG" Tab - Analytics
│   ├── Settings/              # "CFG" Tab - Configuration
│   ├── Cards/                 # The core UI component system (UniversalTimelineCard)
│   └── Components/            # Shared UI elements (Scanlines, Glitch, HUD)
└── Config/                    # Configuration management
```

### Key Technical Patterns
*   **Decorator Pattern**: Used in `UniversalTimelineCard` to compose complex card UIs from simple blocks.
*   **Observable State**: Heavy use of `ObservableObject` and `Combine` for reactive UI updates.
*   **Environment Configuration**: Secure handling of API keys via `xcconfig`.

---

## 🚀 Initialization

### Prerequisites
*   Xcode 16.0+
*   iOS 17.0+
*   An API Key from [OpenRouter](https://openrouter.ai/)

### Setup Instructions

1.  **Clone the Repository**
    ```bash
    git clone https://github.com/yourusername/neon.git
    cd neon
    ```

2.  **Configure API Keys**
    *   **Local Development**:
        *   In Xcode, go to `Product` -> `Scheme` -> `Edit Scheme`.
        *   Under `Run` -> `Environment Variables`, add `OPENROUTER_API_KEY` with your key.
    *   **Production / Archiving**:
        *   Copy `Config/Secrets.template.xcconfig` to `Config/Secrets.xcconfig`.
        *   Add your key: `OPENROUTER_API_KEY = sk-or-......`
        *   *Note: `Secrets.xcconfig` is git-ignored.*

3.  **Build and Run**
    *   Select the target simulator (e.g., iPhone 15 Pro) and hit **Run (⌘R)**.

---

## 📦 Tech Stack
*   **Language**: Swift 6.0
*   **UI Framework**: SwiftUI
*   **AI Backend**: OpenRouter API (Access to GPT-4, Claude 3, etc.)
*   **Persistence**: UserDefaults & JSON (FileSystem)

---

> *End of Line.*
