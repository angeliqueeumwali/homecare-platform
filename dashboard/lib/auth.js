const TOKEN_KEY = "homecare_admin_token";

export function getToken() {
  if (typeof window === "undefined") return null;
  try {
    return window.localStorage.getItem(TOKEN_KEY);
  } catch {
    return null;
  }
}

export function setToken(token) {
  window.localStorage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  window.localStorage.removeItem(TOKEN_KEY);
}

export function getStoredUser() {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(`${TOKEN_KEY}:user`);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function setStoredUser(user) {
  window.localStorage.setItem(`${TOKEN_KEY}:user`, JSON.stringify(user));
}

export function clearStoredUser() {
  window.localStorage.removeItem(`${TOKEN_KEY}:user`);
}
