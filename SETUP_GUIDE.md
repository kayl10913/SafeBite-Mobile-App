# SafeBite Setup Guide

This guide will help you set up both the Flutter frontend and your existing Node.js Express backend for the SafeBite application.

## Prerequisites

1. **Flutter SDK** - Make sure Flutter is installed and configured
2. **Node.js** - Download and install from https://nodejs.org/
3. **MySQL** - Your backend uses MySQL database
4. **Git** - For version control

## Backend Setup (Your Existing Node.js Express)

1. **Navigate to your backend directory:**
   ```bash
   cd safebitRestAPI
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Set up your MySQL database:**
   - Make sure MySQL is running
   - Create a `.env` file in the `safebitRestAPI` directory with your database credentials:
   ```
   DB_HOST=localhost
   DB_USER=your_username
   DB_PASSWORD=your_password
   DB_NAME=your_database_name
   PORT=3000
   ```

4. **Import the database schema:**
   - Use the SQL file in `safebitRestAPI/db/safebite_db (1).sql` to create your database tables

5. **Start the server:**
   ```bash
   # Development mode (with auto-restart)
   npm run dev
   
   # OR Production mode
   npm start
   ```

6. **Verify the server is running:**
   - Open your browser and go to: http://localhost:3000/api/test-db
   - You should see: `{"success":true,"result":2}`

## Frontend Setup (Flutter)

1. **Navigate to the Flutter project root:**
   ```bash
   cd flutter_application_1
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the Flutter app:**
   ```bash
   flutter run
   ```

## API Endpoints

Your backend now provides these endpoints:

- `GET /api/test-db` - Database connection test
- `POST /api/newuser` - User registration
- `POST /api/login` - User login (newly added)
- `GET /api/users` - Get all users

## Testing the Connection

1. **Start the backend first** (make sure it's running on port 3000)
2. **Start the Flutter app**
3. **Test registration:**
   - Go to the signup screen
   - Enter a valid email and password
   - Click "Sign Up"
   - You should see a success message

4. **Test login:**
   - Go to the login screen
   - Enter the credentials you just registered
   - Click "Sign In"
   - You should be redirected to the home page

## File Structure

```
flutter_application_1/
├── lib/
│   ├── services/
│   │   └── user_service.dart (connects to your backend)
│   ├── loginscreen.dart (updated with backend integration)
│   ├── signupscreen.dart (updated with backend integration)
│   └── main.dart
├── safebitRestAPI/ (your existing backend)
│   ├── backend/
│   │   ├── app.js
│   │   └── routes/
│   │       └── user.js (updated with login endpoint)
│   ├── db/
│   │   ├── db.js
│   │   └── safebite_db (1).sql
│   ├── package.json
│   └── index.js
└── SETUP_GUIDE.md
```

## Troubleshooting

### Backend Issues:
- **Port already in use:** Change the port in your `.env` file or kill the process using port 3000
- **Database connection errors:** Check your MySQL credentials in the `.env` file
- **CORS errors:** The backend is configured to allow all origins for development

### Flutter Issues:
- **Connection refused:** Make sure the backend is running on localhost:3000
- **HTTP errors:** Check that the backend URL in `lib/services/user_service.dart` matches your backend URL
- **Dependencies:** Run `flutter pub get` to install missing packages

## Security Notes

- Passwords are currently stored as plain text in the database
- For production, you should implement password hashing using bcrypt
- Consider adding JWT tokens for session management
- Implement proper input validation and sanitization

## Next Steps

1. **Add password hashing** to the backend
2. **Implement JWT authentication**
3. **Add more user management features**
4. **Deploy to production servers**

## Development Commands

### Backend:
```bash
cd safebitRestAPI
npm run dev  # Development with auto-restart
npm start    # Production mode
```

### Frontend:
```bash
cd flutter_application_1
flutter pub get
flutter run
``` 