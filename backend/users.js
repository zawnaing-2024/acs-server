import bcrypt from 'bcrypt';

const users = [
  {
    username: 'admin',
    // hash for 'One@2025'
    passwordHash: '$2b$10$5k5rh6Q4qzM7gc3KJ2Y0TOfeV0w.zAV/QXpKZl8vGeOawxDFUY8Ia'
  }
];

export async function findUser(username) {
  return users.find(u => u.username === username);
}

export async function verifyPassword(user, password) {
  return bcrypt.compare(password, user.passwordHash);
} 