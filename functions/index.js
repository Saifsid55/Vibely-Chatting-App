const functions = require("firebase-functions");
require("dotenv").config();
const {GoogleGenerativeAI} = require("@google/generative-ai");

// ✅ Initialize Gemini client
const apiKey = process.env.GEMINI_API_KEY;
if (!apiKey) {
  console.error("❌ Missing GEMINI_API_KEY in .env");
}

const genAI = new GoogleGenerativeAI(apiKey);
const model = genAI.getGenerativeModel({model: "gemini-2.5-flash"});

/**
 * Test Gemini AI locally to verify mood detection.
 */
async function testGemini() {
  try {
    const result = await model.generateContent(
        "Detect the mood of this message: 'I am feeling awesome today!' " +
            "Reply with one emoji only.",
    );
    console.log("✅ Gemini replied:", result.response.text());
  } catch (err) {
    console.error("❌ Error calling Gemini:", err);
  }
}

// Uncomment this to test locally
testGemini();

// ✅ Firebase callable function
/**
 * Firebase Function: Detects user mood based on message text using Gemini API.
 */
exports.detectMood = functions.https.onCall(async (data, context) => {
  try {
    const {message} = data;
    if (!message) return {error: "No message provided"};

    const prompt = `Detect the mood of this message: "${message}".
    The message could be in English, Hindi, Urdu, or Hinglish.
    Reply with only one emoji representing the mood.`;

    const result = await model.generateContent(prompt);
    return {mood: result.response.text()};
  } catch (error) {
    console.error("❌ Gemini error:", error);
    return {error: error.message};
  }
});
