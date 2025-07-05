# SafeBite XAMPP Setup Guide

This guide will help you set up the SafeBite application with XAMPP for local development.

## Prerequisites

1. **XAMPP** - Download and install from https://www.apachefriends.org/
2. **Flutter SDK** - Make sure Flutter is installed and configured
3. **Node.js** - Download and install from https://nodejs.org/

## XAMPP Setup

### 1. Start XAMPP Services
1. Open XAMPP Control Panel
2. Start **Apache** and **MySQL** services
3. Make sure both services show green status

### 2. Create Database
1. Open your browser and go to: http://localhost/phpmyadmin
2. Click "New" to create a new database
3. Enter database name: `safebite`
4. Click "Create"

### 3. Import Database Schema
1. In phpMyAdmin, select the `safebite` database
2. Click "Import" tab
3. Choose the SQL file: `safebitRestAPI/db/safebite_db (1).sql`
4. Click "Go" to import

### 4. Verify Database Structure
Your `users` table should have these columns:
- `user_id` (int, primary key, auto increment)
- `first_name` (varchar 100)
- `last_name` (varchar 100)
- `username` (varchar 50)
- `email` (varchar 100)
- `contact_number` (varchar 20, nullable)
- `role` (enum: 'User', 'Admin')
- `account_status` (enum: 'active', 'inactive')
- `password_hash` (varchar 255)
- `created_at` (timestamp)
- `updated_at` (timestamp)

## Backend Setup (Node.js Express)

### 1. Navigate to Backend Directory
```bash
cd safebitRestAPI
```

### 2. Install Dependencies
```bash
npm install
```

### 3. Create Environment File
Create a `.env` file in the `safebitRestAPI` directory:
```
# XAMPP MySQL Configuration
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=
DB_NAME=safebite
DB_PORT=3306

# Server Configuration
PORT=3000
```

**Note:** XAMPP MySQL typically has no password by default. If you set a password, update `DB_PASSWORD`.

### 4. Start the Backend Server
```bash
# Development mode (with auto-restart)
npm run dev

# OR Production mode
npm start
```

### 5. Test Backend Connection
- Open browser: http://localhost:3000/api/test-db
- Should see: `{"success":true,"result":2}`

## Frontend Setup (Flutter)

### 1. Navigate to Flutter Project
```bash
cd flutter_application_1
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run Flutter App
```bash
flutter run
```

## Testing the Application

### 1. Test Registration
1. Open the Flutter app
2. Go to Sign Up screen
3. Fill in all required fields:
   - First Name
   - Last Name
   - Username
   - Email
   - Contact Number (optional)
   - Password
   - Confirm Password
4. Click "Sign Up"
5. Should see success message

### 2. Test Login
1. Go to Login screen
2. Enter email or username
3. Enter password
4. Click "Sign In"
5. Should navigate to home page

### 3. Verify Database
1. Go to phpMyAdmin: http://localhost/phpmyadmin
2. Select `safebite` database
3. Click on `users` table
4. Should see your registered user

## API Endpoints

Your backend provides these endpoints:

- `GET /api/test-db` - Database connection test
- `POST /api/newuser` - User registration
- `POST /api/login` - User login
- `GET /api/users` - Get all users
- `GET /api/user/:id` - Get user by ID

## Troubleshooting

### XAMPP Issues:
- **MySQL won't start:** Check if port 3306 is already in use
- **Access denied:** Make sure MySQL is running in XAMPP
- **Database not found:** Create the `safebite` database first

### Backend Issues:
- **Connection refused:** Make sure XAMPP MySQL is running
- **Access denied:** Check your `.env` file credentials
- **Port in use:** Change PORT in `.env` file

### Flutter Issues:
- **Connection error:** Make sure backend is running on port 3000
- **HTTP errors:** Check that backend URL is correct in `lib/services/user_service.dart`

## File Structure

```
flutter_application_1/
├── lib/
│   ├── services/
│   │   └── user_service.dart (connects to backend)
│   │   ├── loginscreen.dart (updated with backend integration)
│   │   ├── signupscreen.dart (updated with backend integration)
│   │   └── main.dart
│   ├── safebitRestAPI/
│   │   ├── backend/
│   │   │   ├── app.js
│   │   │   └── routes/
│   │   │   │   └── user.js (updated routes)
│   │   │   ├── db/
│   │   │   │   ├── db.js (XAMPP configuration)
│   │   │   │   └── safebite_db (1).sql
│   │   │   ├── package.json
│   │   │   └── index.js
│   │   └── XAMPP_SETUP_GUIDE.md
│   └── XAMPP_SETUP_GUIDE.md
```

## Development Commands

### Start XAMPP:
1. Open XAMPP Control Panel
2. Start Apache and MySQL

### Backend:
```bash
cd safebitRestAPI
npm run dev
```

### Frontend:
```bash
cd flutter_application_1
flutter run
```

## Security Notes

- Passwords are currently stored as plain text
- For production, implement password hashing with bcrypt
- Consider adding JWT tokens for session management
- Implement proper input validation and sanitization

## Next Steps

1. **Add password hashing** to the backend
2. **Implement JWT authentication**
3. **Add more user management features**
4. **Deploy to production servers** 