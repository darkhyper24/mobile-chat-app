# ZC Chat App - Comprehensive Project Report

## Table of Contents

1. [Project Overview](#project-overview)
2. [Target Users](#target-users)
3. [Application Features](#application-features)
4. [Technology Stack](#technology-stack)
5. [Architecture & Project Structure](#architecture--project-structure)
6. [Database Schema](#database-schema)
7. [Key Implementation Details](#key-implementation-details)

---

## Project Overview

**ZC Chat App** is a modern, full-featured mobile chat application developed specifically for students at **Zewail City University**. The application provides a seamless communication platform enabling students to connect with each other through direct messaging and group conversations.

### Purpose

The primary purpose of the ZC Chat App is to facilitate communication among university students by providing:

-   Real-time messaging capabilities
-   Friend management system
-   Group chat functionality
-   Location sharing features
-   User profile customization

### Key Objectives

-   Create a user-friendly messaging platform for university students
-   Enable real-time communication with instant message delivery
-   Provide secure authentication and data management
-   Support both one-on-one and group conversations
-   Allow users to share their location with friends

---

## Target Users

**Primary Audience:** Students at Zewail City University

### User Personas

1. **University Students** - Primary users who need to communicate with classmates, study groups, and friends
2. **Study Groups** - Students organizing collaborative learning sessions through group chats
3. **Campus Communities** - Students forming communities around shared interests

### User Needs Addressed

-   Quick and easy messaging between classmates
-   Organization of study groups and project teams
-   Sharing locations for campus meetups
-   Maintaining connections within the university community

---

## Application Features

### 1. Authentication System

#### User Registration (Sign Up)

-   **Email-based registration** with password protection
-   **User profile creation** during signup including:
    -   First name and last name
    -   Email address (used as primary identifier)
    -   Phone number
    -   Gender selection (Male/Female/Other)
    -   Password with confirmation validation
-   **Automatic username generation** from email prefix
-   **Secure token storage** using Flutter Secure Storage
-   **Form validation** for all input fields

#### User Login

-   **Email and password authentication**
-   **Persistent session management** with automatic token refresh
-   **Secure credential storage** for session persistence
-   **Animated login interface** with smooth transitions
-   **Error handling** with user-friendly error messages
-   **Password visibility toggle** for user convenience

#### Session Management

-   **Automatic authentication state detection**
-   **Secure token storage** using FlutterSecureStorage
-   **Sign out functionality** with complete session cleanup

---

### 2. Direct Messaging (One-on-One Chat)

#### Chat Features

-   **Real-time message delivery** using Supabase Realtime WebSocket connections
-   **Message bubble UI** with distinct styling for sent/received messages
-   **Timestamp display** for each message
-   **Date separators** between messages from different days
-   **Auto-scroll to latest messages** with smart scroll behavior
-   **Pull-to-refresh** for loading previous messages
-   **Infinite scroll pagination** for message history

#### Message Types

-   **Text messages** with full emoji support
-   **Location sharing** with Google Maps integration
    -   One-tap location sharing
    -   Clickable location links that open in Google Maps

#### Chat Interface

-   **User avatar display** with profile picture or initials
-   **Online status indicators**
-   **Typing area** with multi-line support (up to 4 lines)
-   **Send button** with loading animation
-   **View profile option** from chat header

#### Real-time Features

-   **Broadcast messaging** via WebSocket channels
-   **Instant message synchronization** across devices
-   **Smart auto-scroll** based on user position in chat

---

### 3. Group Chat System

#### Group Creation

-   **Create new groups** with custom names
-   **Group description** (optional)
-   **Group image upload** with image picker
-   **Add initial members** from friends list
-   **Automatic admin assignment** for group creator

#### Group Messaging

-   **Real-time group messaging** with WebSocket broadcast
-   **Sender identification** with names and avatars
-   **Message grouping** by sender for cleaner UI
-   **Location sharing** within groups
-   **Same features as direct messaging** (timestamps, date separators, etc.)

#### Group Management (Admin Features)

-   **Edit group name and description**
-   **Change group image**
-   **Add new members** from friends list
-   **Remove members** from group
-   **Promote members to admin**
-   **Demote admins to regular members**
-   **Delete group** (admin only)

#### Group Membership

-   **View all group members**
-   **See member roles** (Admin/Member badges)
-   **Leave group** functionality
-   **Admin transfer warning** when last admin tries to leave

---

### 4. Friends Management System

#### Friend Discovery

-   **User search** by username, first name, or last name
-   **Search results** with user avatars and usernames
-   **Existing relationship indicators** (Friends, Pending, etc.)

#### Friend Requests

-   **Send friend requests** to other users
-   **View pending received requests** with accept/decline options
-   **View sent requests** (pending status)
-   **Request status tracking** (pending, accepted, declined)
-   **Duplicate request prevention**

#### Friends List

-   **View all friends** with profile pictures
-   **Search/filter friends** by name or username
-   **Quick message button** to start conversation
-   **Remove friend** with confirmation dialog
-   **Horizontal scroll friends section** on home page

#### Request Management

-   **Accept friend requests** - automatically creates friendship
-   **Decline friend requests** - marks request as declined
-   **Request counter badge** on Friends tab

---

### 5. User Profile Management

#### Profile Information

-   **View and edit profile fields:**
    -   First name
    -   Last name
    -   About/Bio section
    -   Phone number
-   **Read-only fields:**
    -   Email address
    -   Username

#### Profile Picture

-   **Upload profile picture** from device gallery
-   **Image compression** (max 1024x1024, 85% quality)
-   **Cloud storage** in Supabase Storage bucket
-   **Automatic old image cleanup** when uploading new picture
-   **Fallback to initials** when no picture is set

#### Profile UI

-   **Inline editing** with save/edit toggle buttons
-   **Animated profile picture** with camera icon overlay
-   **Real-time profile updates** across the app
-   **Loading indicators** during save operations

---

### 6. Settings & Preferences

#### Appearance Settings

-   **Dark theme toggle** with system-wide application
-   **Light theme** (default)
-   **Theme persistence** using SharedPreferences
-   **Smooth theme transitions** throughout the app

#### App Information

-   **About dialog** with app version
-   **App icon and branding display**
-   **Version information** fetched dynamically

#### Account Actions

-   **Logout functionality** with confirmation dialog
-   **Complete session cleanup** on logout
-   **Navigation to login screen** after logout

---

### 7. Home Page & Navigation

#### Conversations Overview

-   **Direct Messages tab** - List of all one-on-one conversations
-   **Groups tab** - List of all group conversations
-   **Tab switching** with animated transitions
-   **Search functionality** for filtering conversations

#### Conversation Cards

-   **User/Group avatar** with profile picture or initials
-   **Last message preview** with truncation
-   **Timestamp** (Today shows time, otherwise shows date)
-   **Unread message counter** badge

#### Friends Section

-   **Horizontal scrollable friends list**
-   **Quick access** to start conversations
-   **"See all" link** to full friends page

#### Bottom Navigation

-   **Messages** - Home/conversations screen
-   **Friends** - Friends management
-   **Settings** - App settings
-   **Profile** - User profile page

---

### 8. Location Sharing

#### GPS Integration

-   **Permission handling** for location access
-   **Current location retrieval** using Geolocator
-   **Error handling** for disabled location services
-   **Permission request flow** for denied permissions

#### Location Messages

-   **Google Maps URL generation** from coordinates
-   **Special location message UI** with map icon
-   **Clickable links** that open in external browser
-   **Works in both direct and group chats**

---

### 9. User Interface & Experience

#### Design System

-   **Material Design 3** compliance
-   **Purple accent color** (Primary: #6750A4)
-   **Consistent typography** and spacing
-   **Rounded corners** throughout the app

#### Animations

-   **Page transitions** with fade and slide effects
-   **Button press animations** with scale feedback
-   **Message bubble entrance animations**
-   **Loading state animations**
-   **Tab switching animations**
-   **Search bar animations**
-   **Profile picture tap animations**

#### Responsive Design

-   **Safe area handling** for notches and system bars
-   **Keyboard-aware layouts**
-   **Scroll handling** for long content
-   **Adaptive layouts** for different screen sizes

#### Accessibility

-   **Semantic labels** for screen readers
-   **Color contrast** compliance
-   **Touch target sizing** (minimum 48dp)

---

## Technology Stack

### Framework & Language

| Technology  | Version | Purpose                         |
| ----------- | ------- | ------------------------------- |
| **Flutter** | ^3.9.2+ | Cross-platform mobile framework |
| **Dart**    | ^3.9.2  | Programming language            |

### Backend & Database

| Technology            | Purpose                                      |
| --------------------- | -------------------------------------------- |
| **Supabase**          | Backend-as-a-Service (BaaS)                  |
| **Supabase Auth**     | User authentication                          |
| **Supabase Database** | PostgreSQL database                          |
| **Supabase Storage**  | File/image storage                           |
| **Supabase Realtime** | WebSocket connections for real-time features |

### State Management

| Package      | Version | Purpose                   |
| ------------ | ------- | ------------------------- |
| **Provider** | ^6.1.1  | State management solution |

### Core Dependencies

| Package                  | Version | Purpose                         |
| ------------------------ | ------- | ------------------------------- |
| `supabase_flutter`       | ^2.0.0  | Supabase Flutter SDK            |
| `flutter_dotenv`         | ^5.1.0  | Environment variable management |
| `flutter_secure_storage` | ^9.0.0  | Secure credential storage       |
| `provider`               | ^6.1.1  | State management                |
| `shared_preferences`     | ^2.2.2  | Local preferences storage       |

### Feature-Specific Dependencies

| Package              | Version | Purpose                      |
| -------------------- | ------- | ---------------------------- |
| `image_picker`       | ^1.0.7  | Image selection from gallery |
| `geolocator`         | ^14.0.2 | GPS location services        |
| `permission_handler` | ^12.0.1 | Runtime permission handling  |
| `url_launcher`       | ^6.3.2  | External URL opening         |
| `package_info_plus`  | ^8.0.0  | App version information      |

### UI Dependencies

| Package           | Version | Purpose         |
| ----------------- | ------- | --------------- |
| `cupertino_icons` | ^1.0.8  | iOS-style icons |

### Development Dependencies

| Package         | Version | Purpose            |
| --------------- | ------- | ------------------ |
| `flutter_test`  | SDK     | Widget testing     |
| `flutter_lints` | ^5.0.0  | Code linting rules |

---

## Architecture & Project Structure

### Project Architecture

The application follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                      UI Layer                           │
│  (Screens, Widgets, Animations)                        │
├─────────────────────────────────────────────────────────┤
│                   Provider Layer                        │
│  (State Management, Business Logic)                    │
├─────────────────────────────────────────────────────────┤
│                   Service Layer                         │
│  (API Calls, Data Processing)                          │
├─────────────────────────────────────────────────────────┤
│                    Data Layer                           │
│  (Models, Database Connection)                         │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure

```
lib/
├── main.dart                    # App entry point, MultiProvider setup
├── database/
│   └── db.dart                  # Supabase database singleton
├── models/
│   ├── users.dart               # User data model
│   ├── messages.dart            # Message data model
│   ├── group.dart               # Group data model
│   ├── group_members.dart       # Group membership model
│   ├── friends.dart             # Friend relationship model
│   └── friend_request.dart      # Friend request model
├── providers/
│   ├── auth_provider.dart       # Authentication state
│   ├── chat_provider.dart       # Direct messaging state
│   ├── friends_provider.dart    # Friends management state
│   ├── group_provider.dart      # Group chat state
│   └── theme_provider.dart      # Theme/appearance state
├── services/
│   ├── auth_service.dart        # Authentication API calls
│   ├── message_service.dart     # Direct messaging API
│   ├── friend_service.dart      # Friends API calls
│   ├── group_service.dart       # Group management API
│   ├── user_service.dart        # User profile API
│   └── location_service.dart    # GPS/location services
└── ui/
    ├── login.dart               # Login screen
    ├── signup.dart              # Registration screen
    ├── home.dart                # Main home screen
    ├── chat.dart                # Direct chat screen
    ├── group_chat.dart          # Group chat screen
    ├── friends.dart             # Friends management screen
    ├── profile.dart             # User profile screen
    ├── user_profile.dart        # Other user's profile view
    ├── settings.dart            # Settings screen
    ├── create_group.dart        # Group creation screen
    ├── group_settings.dart      # Group settings screen
    └── widgets/                 # Reusable UI components
```

### State Management Pattern

The app uses **Provider** for state management with dedicated providers for each feature:

1. **AuthProvider** - Manages authentication state, current user, login/logout
2. **ChatProvider** - Handles direct messaging, conversations, real-time updates
3. **FriendsProvider** - Manages friend lists, requests, user search
4. **GroupProvider** - Controls group chats, members, group messages
5. **ThemeProvider** - Handles theme switching and persistence

---

## Database Schema

### Users Table

| Column       | Type      | Description                |
| ------------ | --------- | -------------------------- |
| user_id      | UUID (PK) | Unique user identifier     |
| email        | String    | User email address         |
| firstname    | String?   | First name                 |
| lastname     | String?   | Last name                  |
| username     | String?   | Display username           |
| profile_pic  | String?   | Profile picture URL        |
| bio          | String?   | User bio/about             |
| phone_number | String?   | Phone number               |
| gender       | String?   | Gender                     |
| created_at   | DateTime  | Account creation timestamp |

### Messages Table

| Column      | Type       | Description                        |
| ----------- | ---------- | ---------------------------------- |
| message_id  | UUID (PK)  | Unique message identifier          |
| sender_id   | UUID (FK)  | Reference to sender user           |
| receiver_id | UUID? (FK) | Reference to receiver (DM)         |
| group_id    | UUID? (FK) | Reference to group (group message) |
| message     | String?    | Message content                    |
| image       | String?    | Image attachment URL               |
| created_at  | DateTime   | Message timestamp                  |

### Group Table

| Column      | Type      | Description              |
| ----------- | --------- | ------------------------ |
| group_id    | UUID (PK) | Unique group identifier  |
| name        | String?   | Group name               |
| description | String?   | Group description        |
| image       | String?   | Group avatar URL         |
| created_at  | DateTime  | Group creation timestamp |

### Group Members Table

| Column     | Type      | Description                  |
| ---------- | --------- | ---------------------------- |
| id         | UUID (PK) | Unique membership identifier |
| group_id   | UUID (FK) | Reference to group           |
| user_id    | UUID (FK) | Reference to user            |
| role       | String    | Member role (admin/member)   |
| created_at | DateTime  | Join timestamp               |

### Friends Table

| Column     | Type      | Description                   |
| ---------- | --------- | ----------------------------- |
| id         | UUID (PK) | Unique friendship identifier  |
| user_id    | UUID (FK) | First user in friendship      |
| friend_id  | UUID (FK) | Second user in friendship     |
| created_at | DateTime  | Friendship creation timestamp |

### Friend Request Table

| Column      | Type      | Description                                |
| ----------- | --------- | ------------------------------------------ |
| id          | UUID (PK) | Unique request identifier                  |
| sender_id   | UUID (FK) | User who sent request                      |
| receiver_id | UUID (FK) | User who received request                  |
| status      | String    | Request status (pending/accepted/declined) |
| created_at  | DateTime  | Request timestamp                          |

---

## Key Implementation Details

### Real-time Messaging Implementation

The app uses **Supabase Realtime** with WebSocket broadcast channels:

1. **Direct Messages**: Uses pair-topic channels (`dm:{userId1}-{userId2}`) for private conversations
2. **Group Messages**: Uses group-topic channels (`group:{groupId}:messages`) for group broadcasts
3. **Message Flow**:
    - Message is inserted into database
    - Broadcast sent via WebSocket channel
    - All subscribed clients receive the message instantly

### Security Features

1. **Secure Token Storage**: Using `flutter_secure_storage` for auth tokens
2. **Environment Variables**: Sensitive config stored in `.env` file
3. **Private Channels**: Realtime channels configured as private
4. **Input Validation**: Form validation on all user inputs

### Image Upload Flow

1. User selects image from gallery via `image_picker`
2. Image is compressed (max 1024x1024, 85% quality)
3. Image uploaded to Supabase Storage bucket
4. Public URL generated and saved to database
5. Old images are cleaned up automatically

### Offline Considerations

-   Messages are fetched from database on app start
-   Real-time subscriptions reconnect automatically
-   Theme preferences persisted locally with `shared_preferences`
-   Auth tokens stored securely for session persistence

---

## Platform Support

The app is configured to run on:

-   ✅ **Android**
-   ✅ **iOS**
-   ✅ **Web**
-   ✅ **Windows**
-   ✅ **macOS**
-   ✅ **Linux**

---

## Version Information

-   **App Version**: 1.0.0+1
-   **Flutter SDK**: ^3.9.2
-   **Dart SDK**: ^3.9.2

---

## Summary

ZC Chat App is a comprehensive, full-featured mobile messaging application built with Flutter and powered by Supabase. It provides students at Zewail City University with a modern, intuitive platform for communication featuring:

-   **Secure authentication** with email/password
-   **Real-time direct and group messaging** with instant delivery
-   **Complete friend management** with requests and search
-   **Group chat capabilities** with admin controls
-   **Location sharing** via Google Maps integration
-   **Profile customization** with photo uploads
-   **Dark/Light theme support** with persistence
-   **Cross-platform compatibility** (mobile, web, desktop)

The application demonstrates modern mobile development best practices including clean architecture, state management with Provider, real-time data synchronization, and responsive UI design with smooth animations.
