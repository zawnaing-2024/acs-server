const users = [
  {
    username: 'admin',
    password: 'One@2025'
  }
];

export async function findUser(username) {
  return users.find(u => u.username === username);
}

export async function verifyPassword(user, password) {
  // Plain text comparison (TEMPORARY). Replace with bcrypt in production.
  return password === user.password;
} 