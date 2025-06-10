# 🎯 KKN Quest - Petualangan Mahasiswa

> Aplikasi manajemen quest dan aktivitas untuk Kuliah Kerja Nyata (KKN) yang gamified dan interaktif

## 📋 Deskripsi Project

KKN Quest adalah aplikasi mobile yang dirancang khusus untuk membantu mahasiswa dalam mengelola aktivitas dan tugas selama periode Kuliah Kerja Nyata (KKN). Aplikasi ini menggunakan konsep gamification dengan sistem quest, XP, dan level untuk membuat pengalaman KKN menjadi lebih menarik dan terorganisir.

## 👥 Tim Pengembang

**Praktikum Teknologi dan Pemrograman Mobile IF - G**

- **123220045** - Annas Sovianto
- **123220047** - Galang Rakha Ahnanta

## ✨ Fitur Utama

### 🎮 Sistem Gamification

- **Quest System**: Buat dan kelola berbagai jenis quest (Daily, Weekly, Monthly)
- **XP & Level**: Sistem pengalaman dan level untuk memotivasi penyelesaian tugas
- **Progress Tracking**: Pantau kemajuan quest secara real-time
- **Achievement**: Raih pencapaian melalui penyelesaian quest

### 📊 Manajemen Quest

- **Kategorisasi Quest**: Quest harian, mingguan, dan bulanan
- **Deadline Management**: Pengaturan dan reminder deadline quest
- **Progress Bar**: Visualisasi progress penyelesaian quest
- **Quest Details**: Deskripsi lengkap, reward XP, dan biaya quest

### 💰 Budget Tracker

- **Budget Management**: Kelola anggaran KKN
- **Expense Tracking**: Catat pengeluaran terkait quest
- **Budget Analysis**: Analisis penggunaan budget
- **Visual Reports**: Grafik dan chart penggunaan budget

### 📝 Note Management

- **Smart Notes**: Buat dan kelola catatan dengan kategori
- **Pin Important Notes**: Tandai catatan penting
- **Search Function**: Cari catatan dengan mudah
- **Categories**: Organisasi catatan berdasarkan kategori

### 🕌 Islamic Features

- **Prayer Schedule**: Jadwal sholat berdasarkan lokasi
- **Hijri Calendar**: Kalender Hijriah terintegrasi
- **Asmaul Husna**: Tampilan nama-nama Allah
- **City Selection**: Pilih kota untuk jadwal sholat

### ❤️ Favorites System

- **Favorite Quests**: Tandai quest favorit untuk akses cepat
- **Quick Access**: Akses mudah ke quest yang sering digunakan

### 🔔 Smart Notifications

- **Deadline Reminders**: Notifikasi 15 menit sebelum deadline
- **Quest Notifications**: Reminder untuk quest yang akan berakhir
- **Smart Scheduling**: Sistem notifikasi cerdas anti-spam

## 🛠️ Teknologi yang Digunakan

### Frontend

- **Flutter 3.x** - Cross-platform mobile development
- **Dart** - Programming language
- **Material Design 3** - UI/UX design system

### Backend & Database

- **Firebase Authentication** - User authentication system
- **Cloud Firestore** - NoSQL cloud database
- **Firebase Storage** - File and media storage

### State Management & Local Storage

- **Provider/setState** - State management
- **Hive** - Local database for favorites
- **SharedPreferences** - Local preferences storage

### External APIs

- **Prayer Time API** - Islamic prayer schedule
- **Hijri Calendar API** - Islamic calendar integration

### Notifications

- **Flutter Local Notifications** - Local push notifications
- **Smart Reminder System** - Custom notification scheduling

### Additional Packages

- **animate_do** - Smooth animations
- **logger** - Advanced logging system
- **http** - HTTP client for API calls

## 📱 Screenshots & UI Features

### Compact Android Design

- ✅ Optimized untuk layar mobile Android
- ✅ Responsive design untuk berbagai ukuran layar
- ✅ Compact layout yang efisien
- ✅ Professional color scheme
- ✅ Smooth animations dan transitions

### Theme & Design

- 🎨 **Primary Colors**: Blue gradient (#667eea → #764ba2)
- 🎨 **Accent Colors**: Gold (#FFD700) dan Orange (#FF6B35)
- 🎨 **Quest Colors**: Orange (Daily), Blue (Weekly), Green (Monthly)
- 🎨 **Card Design**: Modern card layout dengan shadows
- 🎨 **Compact Spacing**: Optimized untuk mobile experience

## 🚀 Instalasi dan Setup

### Prerequisites

```bash
Flutter SDK >= 3.0.0
Dart SDK >= 2.17.0
Android Studio / VS Code
Firebase Project
```

### Clone Repository

```bash
git clone [repository-url]
cd project_praktpm
```

### Install Dependencies

```bash
flutter pub get
```

### Firebase Setup

1. Buat project Firebase baru
2. Enable Authentication (Email/Password)
3. Setup Cloud Firestore
4. Download `google-services.json` ke `android/app/`
5. Setup Firebase configuration

### Run Application

```bash
flutter run
```

## 📁 Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Data models
│   ├── quest_model.dart
│   ├── user_model.dart
│   ├── note_model.dart
│   └── prayer_model.dart
├── services/                 # Business logic services
│   ├── auth_service.dart
│   ├── quest_service.dart
│   ├── note_service.dart
│   ├── prayer_service.dart
│   └── notification_service.dart
├── views/                    # UI screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── auth/
│   ├── quest/
│   ├── notes/
│   └── profile/
├── widgets/                  # Reusable widgets
│   ├── quest_theme.dart
│   └── enhanced_quest_card.dart
└── utils/                    # Utility functions
    └── notification_helper.dart
```

## 🎯 Core Features Detail

### Quest Management System

```dart
// Quest Types
enum QuestType { daily, weekly, monthly }

// Quest Status
enum QuestStatus { pending, inProgress, completed }

// Features:
- Create, update, delete quests
- Progress tracking with percentage
- XP reward system
- Budget cost tracking
- Deadline management with notifications
```

### Notification System

```dart
// Smart notification features:
- 15-minute deadline reminders
- Anti-spam notification logic
- Scheduled notifications for all active quests
- Permission handling
- Background notification support
```

### Authentication & User Management

```dart
// Firebase Auth integration:
- Email/password registration
- Secure login system
- User profile management
- Password reset functionality
- Protected routes
```

## 🔒 Security Features

- ✅ Firebase Authentication
- ✅ Firestore Security Rules
- ✅ Input validation
- ✅ Error handling
- ✅ Secure data storage

## 📊 Database Schema

### Users Collection

```json
{
  "uid": "string",
  "namaLengkap": "string",
  "kodeKkn": "string",
  "email": "string",
  "xp": "number",
  "level": "number",
  "totalBudget": "number",
  "usedBudget": "number",
  "createdAt": "timestamp"
}
```

### Quests Collection

```json
{
  "id": "string",
  "title": "string",
  "description": "string",
  "type": "enum",
  "status": "enum",
  "xpReward": "number",
  "cost": "number",
  "deadline": "timestamp",
  "kodeKkn": "string",
  "progress": "number",
  "maxProgress": "number"
}
```

## 🎮 Gamification Elements

### Level System

- **Level 1-∞**: Berdasarkan total XP
- **XP per Level**: 100 XP = 1 Level
- **Progress Bar**: Visual progress ke level berikutnya

### Quest Rewards

- **Daily Quests**: 10-50 XP
- **Weekly Quests**: 50-200 XP
- **Monthly Quests**: 200-500 XP

### Achievement System

- Quest completion tracking
- Streak counters
- Progress milestones

## 🌟 Keunggulan Aplikasi

1. **User Experience**

   - Intuitive dan user-friendly interface
   - Smooth animations dan transitions
   - Responsive design untuk semua ukuran layar

2. **Performance**

   - Optimized untuk Android devices
   - Fast loading times
   - Efficient memory management

3. **Islamic Integration**

   - Prayer schedule berdasarkan lokasi
   - Hijri calendar integration
   - Islamic content (Asmaul Husna)

4. **Smart Features**

   - Intelligent notification system
   - Auto-scheduling quest reminders
   - Smart search dan filtering

5. **Scalability**
   - Modular architecture
   - Firebase scalable backend
   - Easy feature expansion

## 🤝 Kontribusi

Aplikasi ini dikembangkan sebagai project praktikum TPM. Untuk kontribusi atau saran:

1. Fork repository
2. Buat feature branch
3. Commit changes
4. Push ke branch
5. Create Pull Request

## 📄 Lisensi

Project ini dibuat untuk keperluan akademik - Praktikum Teknologi dan Pemrograman Mobile, Universitas Atma Jaya Yogyakarta.

## 📞 Kontak

- **Annas Sovianto** - 123220045
- **Galang Rakha Ahnanta** - 123220047

---

**© 2025 KKN Quest - Praktikum TPM IF-G**
