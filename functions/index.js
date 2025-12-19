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
    // Validate input
    const message = (data.message || "").trim();

    if (!message) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Message text is required."
      );
    }

    // Load API key safely
    const apiKey = functions.config().gemini.key;
    if (!apiKey) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Gemini API key is not set in Firebase config."
      );
    }

    // Instantiate Gemini with API Key
    const genAI = new GoogleGenerativeAI(apiKey);

    const model = genAI.getGenerativeModel({
      model: "gemini-2.0-flash",
      safetySettings: [
        { category: "HARM_CATEGORY_DEROGATORY", threshold: "BLOCK" },
        { category: "HARM_CATEGORY_HARASSMENT", threshold: "BLOCK" },
        { category: "HARM_CATEGORY_HATE_SPEECH", threshold: "BLOCK" },
        { category: "HARM_CATEGORY_VIOLENCE", threshold: "BLOCK" },
        { category: "HARM_CATEGORY_SELF_HARM", threshold: "BLOCK" },
        { category: "HARM_CATEGORY_SEXUAL", threshold: "BLOCK" },
      ],
    });

    // Safe & compliant prompt
    const prompt = `
      You are a harmless mood signal generator.

      DO NOT infer mental health, psychological state, or personal attributes.
      DO NOT analyze personality.
      DO NOT give any advice.

      Only provide a **general chat reaction emoji** to the message below.
      For example: 😊 😂 😔 😡 😴 😍 😐 🤔

      Message: "${message}"

      Reply with **exactly one emoji** and nothing else.
    `;

    // Call the model
    const result = await model.generateContent(prompt);

    const text = result?.response?.text()?.trim() || "";

    // Extract ONLY the emoji
    const emoji = [...text]
      .filter((char) => /\p{Emoji}/u.test(char))
      .join("");

    const cleanedEmoji = emoji !== "" ? emoji : text.charAt(0);

    return { mood: cleanedEmoji };
  } catch (err) {
    console.error("❌ detectMood ERROR:", err);
    throw new functions.https.HttpsError(
      "internal",
      "Mood detection failed: " + err.message
    );
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
