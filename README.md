# 🐔 Poultry Tracker

A mobile-first farm management system for Kenyan poultry farmers. Track egg production, mortality rates, feed consumption, and vaccination schedules. Built with Flutter for offline-first functionality in rural areas.

## 🎯 Problem Statement

Kenya has over 3 million small-scale poultry farmers who struggle with:
- Manual record-keeping leading to data loss
- Missed vaccination schedules causing bird mortality
- Lack of production insights for better decision-making
- Difficulty tracking profitability across batches

## 🚀 Features (Planned)

### Phase 1 (Current - Week 1) ✅
- [x] Basic egg counter with increment/decrement
- [x] Clean, intuitive UI
- [ ] Date-based records

### Phase 2 (Weeks 2-4)
- [ ] Batch management (add/view chicken batches)
- [ ] Daily records (mortality, feed consumption)
- [ ] Firebase integration for cloud sync
- [ ] Offline-first architecture

### Phase 3 (Weeks 5-8)
- [ ] Dashboard with analytics
- [ ] Vaccination reminders & schedules
- [ ] Production forecasting
- [ ] Charts and trend visualization

### Phase 4 (Weeks 9-12)
- [ ] M-Pesa payment integration
- [ ] Multi-farm support
- [ ] Export reports (PDF/Excel)
- [ ] Swahili language support

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Firestore, Authentication, Cloud Functions)
- **State Management:** Provider/Riverpod
- **Local Storage:** Hive/SQLite
- **Payments:** M-Pesa Daraja API

## 📱 Target Platform

- Primary: Android (90%+ market share in Kenya)
- Secondary: iOS
- Offline-first design for rural areas with poor connectivity

## 🎓 About This Project

Built as a learning project by a 4th-year Information Technology student at The Technical University of Kenya. This app addresses real problems faced by Kenyan poultry farmers while demonstrating full-stack mobile development skills.

## 📈 Development Timeline

- **Week 1:** Flutter basics & project setup ✅
- **Weeks 2-4:** Core features (batch management, daily records)
- **Weeks 5-8:** Advanced features (analytics, reminders)
- **Weeks 9-12:** Polish, testing, farmer feedback

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (3.24+)
- Android Studio / VS Code
- Firebase account (for backend)

### Installation
```bash
# Clone the repository
git clone https://github.com/lemayian23/poultry_tracker.git

# Navigate to project directory
cd poultry_tracker

# Get dependencies
flutter pub get

# Run the app
flutter run