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
    private let apiKey = "AIzaSyCBRRt4SsDH-Tj1ckQzFIABkBehxuvC8LI"
    private init() {}
    
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
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)") else {
            completion(nil)
            return
        }
        
        // ✅ Simplified, clean and robust prompt
        let prompt = "Detect the mood of this message : '\(message)' the message can be in English, Hindi, or Hindi+English which is Hinglish. Reply with only one emoji representing the mood (like 😊, 😢, 😡, 😍, 😴, etc.)."
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let emoji = parts.first?["text"] as? String {
                    let cleanedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
                    print("✅ Detected Mood: \(cleanedEmoji)")
                    completion(cleanedEmoji)
                } else {
                    print("❌ Gemini API: Unexpected JSON format")
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
