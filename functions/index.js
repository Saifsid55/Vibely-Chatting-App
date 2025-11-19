// =======================
//   IMPORTS & SETUP
// =======================
const functions = require("firebase-functions");
require("dotenv").config();
const { GoogleGenerativeAI } = require("@google/generative-ai");
const crypto = require("crypto");
const axios = require("axios");
const admin = require("firebase-admin");
admin.initializeApp();

const cloudinary = require("cloudinary").v2;

// IMPORTANT: No functions.config() usage at top level.
// Firebase 2nd-gen cannot analyze functions.config() outside a function.


// =======================
//   FIREBASE FUNCTIONS
// =======================


/**
 * Mood detection using Gemini
 */
exports.detectMood = functions.https.onCall(async (data, context) => {
  try {
    // Runtime-safe config load
    const apiKey = functions.config().gemini.key;

    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Gemini API key not found in Firebase config"
      );
    }

    const genAI = new GoogleGenerativeAI(apiKey);
    const model = genAI.getGenerativeModel({
      model: "gemini-2.5-flash",
    });

    const { message } = data;
    if (!message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Message is required"
      );
    }

    const prompt = `Detect the mood of this message: "${message}". Reply with only one emoji.`;

    const result = await model.generateContent(prompt);
    return { mood: result.response.text() };
  } catch (error) {
    console.error("❌ Gemini error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});


// =======================
//   CLOUDINARY DELETE FUNCTION (SDK VERSION)
// =======================

exports.deleteCloudinaryImage = functions.https.onCall(async (data, context) => {
  console.log("📩 Delete request:", data);

  cloudinary.config({
    cloud_name: functions.config().cloudinary.cloud_name,
    api_key: functions.config().cloudinary.api_key,
    api_secret: functions.config().cloudinary.api_secret
  });

  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be logged in");
  }

  const publicId = data.publicId;
  if (!publicId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing publicId");
  }

  try {
    console.log("🗑️ Deleting via Admin API:", publicId);

    const result = await cloudinary.api.delete_resources([publicId], {
      resource_type: "image",
      type: "upload",      // 🔥 REQUIRED FOR SIGNED UPLOADS
      invalidate: true
    });

    console.log("🟢 Cloudinary Admin API result:", result);

    return {
      success: true,
      result
    };

  } catch (error) {
    console.error("❌ Cloudinary delete error:", error);
    throw new functions.https.HttpsError("internal", error.message);
  }
});
