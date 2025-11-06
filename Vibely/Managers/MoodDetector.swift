//
//  MoodDetector.swift
//  Vibely
//
//  Created by Mohd Saif on 04/11/25.
//
import Foundation
import FirebaseFunctions

class MoodDetector {
    static let shared = MoodDetector()
    private let functions = Functions.functions()
    private init() {}
    private var apiKey: String? {
        KeychainHelper.shared.read(forKey: KeychainKeys.geminiAPIKey)
    }
    func detectMood(for message: String, completion: @escaping (String?) -> Void) {
        print("Message-->\(message)")
        functions.httpsCallable("detectMood").call(["message": message]) { result, error in
            if let error = error {
                print("❌ Mood detection error:", error.localizedDescription)
                completion(nil)
                return
            }
            
            if let data = result?.data as? [String: Any],
               let mood = data["mood"] as? String {
                completion(mood)
            } else {
                completion(nil)
            }
        }
    }
    
    func detectMoodDirect(for message: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = apiKey else {
            print("❌ API Key missing in Keychain.")
            completion(nil)
            return
        }
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            completion(nil)
            return
        }
        
        // ✅ Simplified, clean and robust prompt
        let prompt = """
        You are a mood detection assistant.
        Analyze the following message and detect the sender's mood.
        
        Message: "\(message)"
        
        The message can be in English, Hindi, or Hinglish (a mix of Hindi and English).
        
        Reply with **only one emoji** that best represents the mood.
        Do not include any words, punctuation, or explanation — only the emoji.
        Examples: 😊 😢 😡 😍 😴 😐 🤔 😂 😔 😱 etc
        """
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 15
        let session = URLSession(configuration: sessionConfig)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Gemini request failed:", error.localizedDescription)
                completion(nil)
                return
            }
            
            guard let data = data else {
                print("❌ Gemini API returned empty data.")
                completion(nil)
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]] {
                    
                    var emojiText: String?
                    
                    // Case 1: content.parts.text
                    if let content = candidates.first?["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]],
                       let text = parts.first?["text"] as? String {
                        emojiText = text
                    }
                    // Case 2: output.content.parts.text
                    else if let output = candidates.first?["output"] as? [String: Any],
                            let content = output["content"] as? [String: Any],
                            let parts = content["parts"] as? [[String: Any]],
                            let text = parts.first?["text"] as? String {
                        emojiText = text
                    }
                    
                    guard let rawEmoji = emojiText else {
                        print("❌ Gemini API: Unexpected JSON format — full response:")
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print(jsonString)
                        }
                        completion(nil)
                        return
                    }
                    
                    // ✅ Clean up
                    let emojiOnly = rawEmoji.unicodeScalars
                        .filter { $0.properties.isEmoji }
                        .map(String.init)
                        .joined()
                    
                    let cleaned = emojiOnly.trimmingCharacters(in: .whitespacesAndNewlines)
                    let moodEmoji = cleaned.isEmpty ? String(rawEmoji.prefix(1)) : cleaned
                    
                    print("✅ Detected Mood: \(moodEmoji)")
                    completion(moodEmoji)
                    
                } else {
                    print("❌ Gemini API: Invalid top-level JSON")
                    completion(nil)
                }
            } catch {
                print("❌ JSON Parsing error:", error)
                completion(nil)
            }
        }
        
        task.resume()
    }
    
}
