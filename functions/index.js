const {
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");

const {
  setGlobalOptions,
} = require("firebase-functions");

const {
  initializeApp,
} = require("firebase-admin/app");

const {
  getDatabase,
} = require("firebase-admin/database");

setGlobalOptions({
  maxInstances: 5,
  region: "asia-southeast1",
});

// Firebase Admin SDK menggunakan konfigurasi
// project Firebase yang sedang digunakan.
initializeApp();

const db = getDatabase();

// ============================================================
// NORMALIZE USERNAME
// ============================================================

function normalizeUsername(username) {
  if (typeof username !== "string") {
    throw new HttpsError(
      "invalid-argument",
      "Username tidak valid.",
    );
  }

  const value = username.trim();

  if (!/^[a-zA-Z0-9_]{3,20}$/.test(value)) {
    throw new HttpsError(
      "invalid-argument",
      "Username harus 3-20 karakter, hanya huruf, angka, dan underscore.",
    );
  }

  return value.toLowerCase();
}

// ============================================================
// REGISTER USERNAME
// ============================================================

exports.registerUsername = onCall(
  async (request) => {
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "Silakan login dahulu.",
      );
    }

    const username =
        normalizeUsername(
          request.data.username,
        );

    const email =
        request.auth.token.email;

    if (
      typeof email !== "string" ||
      !email
    ) {
      throw new HttpsError(
        "failed-precondition",
        "Email akun tidak ditemukan.",
      );
    }

    const ref =
        db.ref(
          `usernames/${username}`,
        );

    const result =
        await ref.transaction(
          (current) => {
            if (current !== null) {
              return;
            }

            return {
              uid: request.auth.uid,
              email: email,
            };
          },
        );

    if (!result.committed) {
      throw new HttpsError(
        "already-exists",
        "Username sudah digunakan.",
      );
    }

    return {
      success: true,
    };
  },
);

// ============================================================
// RESOLVE USERNAME
// ============================================================

exports.resolveUsername = onCall(
  async (request) => {
    const username =
        normalizeUsername(
          request.data.username,
        );

    const snapshot =
        await db
          .ref(
            `usernames/${username}`,
          )
          .get();

    if (!snapshot.exists()) {
      throw new HttpsError(
        "not-found",
        "Username atau password salah.",
      );
    }

    const record =
        snapshot.val();

    if (
      !record ||
      typeof record.email !==
          "string" ||
      !record.email.trim() ||
      typeof record.uid !==
          "string" ||
      !record.uid.trim()
    ) {
      throw new HttpsError(
        "not-found",
        "Username atau password salah.",
      );
    }

    return {
      email: record.email,
    };
  },
);