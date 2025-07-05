# SafeBite Mobile App

A Flutter-based mobile application for food safety monitoring and analysis. SafeBite helps users track food quality, detect spoilage, and maintain food safety standards through sensor data analysis and real-time monitoring.

## 🍽️ About SafeBite

SafeBite is a comprehensive food safety monitoring application that combines sensor technology with mobile app functionality to help users:

- **Monitor Food Quality**: Track food items and their safety status
- **Analyze Sensor Data**: View detailed analytics and trends
- **Receive Notifications**: Get alerts about food safety issues
- **Manage User Profiles**: Personalize your food safety experience

## ✨ Features

### 🔐 Authentication & User Management
- **Secure Login/Registration**: Email and username-based authentication
- **Password Recovery**: Forgot password functionality with OTP verification
- **Session Management**: Persistent login sessions
- **User Profiles**: Personalized user experience

### 📊 Analytics & Monitoring
- **Real-time Data Visualization**: Interactive charts and graphs
- **Food Safety Analytics**: Track spoilage patterns and trends
- **Monthly Reports**: Comprehensive monthly analysis
- **Risk Assessment**: Food risk scoring and alerts

### 🔔 Notifications
- **Real-time Alerts**: Instant notifications for food safety issues
- **Customizable Settings**: Personalized notification preferences
- **Status Updates**: Track food item status changes

### 🎨 Modern UI/UX
- **Dark Theme**: Eye-friendly dark interface
- **Responsive Design**: Works on various screen sizes
- **Intuitive Navigation**: Easy-to-use interface
- **Material Design**: Following Google's Material Design principles

## 🛠️ Technology Stack

### Frontend
- **Flutter**: Cross-platform mobile development framework
- **Dart**: Programming language
- **fl_chart**: Data visualization library
- **http**: HTTP client for API communication
- **shared_preferences**: Local data storage

### Backend Integration
- **Node.js/Express**: RESTful API server
- **MySQL**: Database management
- **JWT**: Authentication tokens
- **bcrypt**: Password hashing

## 📱 Screenshots

The app features a modern, dark-themed interface with:
- Splash screen with SafeBite branding
- Login/Registration screens
- Home dashboard with analytics
- Detailed analysis pages
- User profile management
- Notification center

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (3.8.1 or higher)
2. **Android Studio** or **VS Code**
3. **Android Emulator** or **Physical Device**
4. **Node.js** (for backend)
5. **MySQL** (for database)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/safebite-mobile-app.git
   cd safebite-mobile-app
   ```

2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

3. **Set up the backend** (see [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed instructions)
   ```bash
   cd safebitRestAPI
   npm install
   ```

4. **Configure environment**
   - Create `.env` file in backend directory
   - Set up MySQL database
   - Import database schema

5. **Run the application**
   ```bash
   # Start backend (in backend directory)
   npm run dev
   
   # Start Flutter app (in project root)
   flutter run
   ```

## 📁 Project Structure

```
safebite-mobile-app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── loginscreen.dart          # Login screen
│   ├── signupscreen.dart         # Registration screen
│   ├── forgot_password_screen.dart # Password recovery
│   ├── reset_password_screen.dart # Password reset
│   ├── otp_screen.dart           # OTP verification
│   ├── pages/
│   │   ├── home.dart             # Main dashboard
│   │   ├── analysis.dart         # Analytics page
│   │   ├── profile.dart          # User profile
│   │   └── notification.dart     # Notifications
│   └── services/
│       ├── user_service.dart     # User management
│       ├── session_service.dart  # Session handling
│       ├── notification_service.dart # Notifications
│       └── analytics_service.dart # Analytics
├── android/                      # Android configuration
├── ios/                         # iOS configuration
├── web/                         # Web configuration
├── test/                        # Unit tests
├── pubspec.yaml                 # Dependencies
├── SETUP_GUIDE.md              # Detailed setup guide
└── README.md                   # This file
```

## 🔧 Configuration

### Backend Configuration

Create a `.env` file in the backend directory:

```env
DB_HOST=localhost
DB_USER=your_username
DB_PASSWORD=your_password
DB_NAME=safebite_db
PORT=3000
JWT_SECRET=your_jwt_secret
```

### API Endpoints

The app communicates with these backend endpoints:

- `POST /api/newuser` - User registration
- `POST /api/login` - User authentication
- `GET /api/users` - Get user data
- `POST /api/sessions` - Session management
- `GET /api/analytics` - Analytics data
- `GET /api/notifications` - User notifications

## 🧪 Testing

### Running Tests
```bash
flutter test
```

### Manual Testing
1. **Authentication Flow**
   - Test user registration
   - Test login functionality
   - Test password recovery

2. **Data Visualization**
   - Verify charts render correctly
   - Test data filtering
   - Check responsive design

3. **Notifications**
   - Test notification delivery
   - Verify notification settings

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

If you encounter any issues:

1. Check the [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions
2. Review the troubleshooting section in the setup guide
3. Open an issue on GitHub with detailed error information

## 🔮 Future Enhancements

- [ ] Push notifications
- [ ] Offline mode support
- [ ] Multi-language support
- [ ] Advanced analytics
- [ ] Social features
- [ ] Integration with IoT devices

## 📊 Performance

- **App Size**: Optimized for mobile devices
- **Loading Time**: Fast startup with splash screen
- **Memory Usage**: Efficient resource management
- **Battery Life**: Optimized for extended use

## 🔒 Security

- Secure authentication with JWT tokens
- Password hashing with bcrypt
- Input validation and sanitization
- Secure API communication
- Session management

---

**Made with ❤️ using Flutter**

For more information, check out the [SETUP_GUIDE.md](SETUP_GUIDE.md) for detailed setup instructions.
