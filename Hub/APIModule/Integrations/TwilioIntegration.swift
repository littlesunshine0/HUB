import Foundation

// MARK: - Twilio Integration
class TwilioIntegration {
    static let shared = TwilioIntegration()
    
    private var accountSid: String?
    private var authToken: String?
    private var fromNumber: String?
    private let baseURL = "https://api.twilio.com/2010-04-01"
    
    func configure(accountSid: String, authToken: String, fromNumber: String) {
        self.accountSid = accountSid
        self.authToken = authToken
        self.fromNumber = fromNumber
    }
    
    // MARK: - SMS
    func sendSMS(to: String, body: String) async throws -> TwilioMessage {
        guard let fromNumber = fromNumber else {
            throw TwilioError.notConfigured
        }
        
        let params = [
            "To": to,
            "From": fromNumber,
            "Body": body
        ]
        
        return try await post("/Accounts/\(accountSid!)/Messages.json", parameters: params)
    }
    
    func sendMMS(to: String, body: String, mediaUrl: String) async throws -> TwilioMessage {
        guard let fromNumber = fromNumber else {
            throw TwilioError.notConfigured
        }
        
        let params = [
            "To": to,
            "From": fromNumber,
            "Body": body,
            "MediaUrl": mediaUrl
        ]
        
        return try await post("/Accounts/\(accountSid!)/Messages.json", parameters: params)
    }
    
    func getMessage(sid: String) async throws -> TwilioMessage {
        return try await get("/Accounts/\(accountSid!)/Messages/\(sid).json")
    }
    
    // MARK: - Voice
    func makeCall(to: String, twimlUrl: String) async throws -> TwilioCall {
        guard let fromNumber = fromNumber else {
            throw TwilioError.notConfigured
        }
        
        let params = [
            "To": to,
            "From": fromNumber,
            "Url": twimlUrl
        ]
        
        return try await post("/Accounts/\(accountSid!)/Calls.json", parameters: params)
    }
    
    func getCall(sid: String) async throws -> TwilioCall {
        return try await get("/Accounts/\(accountSid!)/Calls/\(sid).json")
    }
    
    // MARK: - Verify (2FA)
    func sendVerificationCode(to: String, channel: String = "sms") async throws -> TwilioVerification {
        let params = [
            "To": to,
            "Channel": channel
        ]
        
        return try await post("/Accounts/\(accountSid!)/Verify/Services/default/Verifications.json", parameters: params)
    }
    
    func checkVerificationCode(to: String, code: String) async throws -> TwilioVerificationCheck {
        let params = [
            "To": to,
            "Code": code
        ]
        
        return try await post("/Accounts/\(accountSid!)/Verify/Services/default/VerificationCheck.json", parameters: params)
    }
    
    // MARK: - Network Layer
    private func get<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint, method: "GET")
    }
    
    private func post<T: Decodable>(_ endpoint: String, parameters: [String: String]) async throws -> T {
        try await request(endpoint, method: "POST", parameters: parameters)
    }
    
    private func request<T: Decodable>(_ endpoint: String, method: String, parameters: [String: String]? = nil) async throws -> T {
        guard let accountSid = accountSid, let authToken = authToken else {
            throw TwilioError.notConfigured
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw TwilioError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        let credentials = "\(accountSid):\(authToken)".data(using: .utf8)!.base64EncodedString()
        request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if let parameters = parameters {
            let body = parameters.map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? $0.value)" }.joined(separator: "&")
            request.httpBody = body.data(using: .utf8)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TwilioError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TwilioError.apiError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Models
struct TwilioMessage: Codable {
    let sid: String
    let status: String
    let to: String
    let from: String
    let body: String
    let dateCreated: String?
    
    enum CodingKeys: String, CodingKey {
        case sid, status, to, from, body
        case dateCreated = "date_created"
    }
}

struct TwilioCall: Codable {
    let sid: String
    let status: String
    let to: String
    let from: String
    let duration: String?
}

struct TwilioVerification: Codable {
    let sid: String
    let status: String
    let to: String
    let channel: String
}

struct TwilioVerificationCheck: Codable {
    let sid: String
    let status: String
    let valid: Bool
}

enum TwilioError: Error {
    case notConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
}
