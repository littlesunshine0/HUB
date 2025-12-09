import Foundation

// MARK: - SendGrid Integration
class SendGridIntegration {
    static let shared = SendGridIntegration()
    
    private var apiKey: String?
    private let baseURL = "https://api.sendgrid.com/v3"
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Send Email
    func sendEmail(to: String, from: String, subject: String, content: String, isHTML: Bool = false) async throws -> SendGridResponse {
        let email = SendGridEmail(
            personalizations: [
                SendGridPersonalization(to: [SendGridEmailAddress(email: to)])
            ],
            from: SendGridEmailAddress(email: from),
            subject: subject,
            content: [
                SendGridContent(type: isHTML ? "text/html" : "text/plain", value: content)
            ]
        )
        
        return try await post("/mail/send", body: email)
    }
    
    func sendTemplateEmail(to: String, from: String, templateId: String, dynamicData: [String: String]) async throws -> SendGridResponse {
        let email = SendGridTemplateEmail(
            personalizations: [
                SendGridTemplatePersonalization(
                    to: [SendGridEmailAddress(email: to)],
                    dynamicTemplateData: dynamicData
                )
            ],
            from: SendGridEmailAddress(email: from),
            templateId: templateId
        )
        
        return try await post("/mail/send", body: email)
    }
    
    func sendBulkEmail(recipients: [String], from: String, subject: String, content: String) async throws -> SendGridResponse {
        let personalizations = recipients.map { recipient in
            SendGridPersonalization(to: [SendGridEmailAddress(email: recipient)])
        }
        
        let email = SendGridEmail(
            personalizations: personalizations,
            from: SendGridEmailAddress(email: from),
            subject: subject,
            content: [SendGridContent(type: "text/plain", value: content)]
        )
        
        return try await post("/mail/send", body: email)
    }
    
    // MARK: - Marketing Campaigns
    func createContact(email: String, firstName: String? = nil, lastName: String? = nil) async throws -> SendGridContactResponse {
        let contact = SendGridContact(
            email: email,
            firstName: firstName,
            lastName: lastName
        )
        
        return try await put("/marketing/contacts", body: ["contacts": [contact]])
    }
    
    func addContactToList(contactId: String, listId: String) async throws -> SendGridResponse {
        return try await post("/marketing/lists/\(listId)/contacts", body: ["contact_ids": [contactId]])
    }
    
    // MARK: - Templates
    func createTemplate(name: String, generation: String = "dynamic") async throws -> SendGridTemplate {
        let template = SendGridTemplateCreate(name: name, generation: generation)
        return try await post("/templates", body: template)
    }
    
    func getTemplate(id: String) async throws -> SendGridTemplate {
        return try await get("/templates/\(id)")
    }
    
    // MARK: - Stats
    func getStats(startDate: String, endDate: String) async throws -> [SendGridStat] {
        return try await get("/stats?start_date=\(startDate)&end_date=\(endDate)")
    }
    
    // MARK: - Network Layer
    private func get<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint, method: "GET")
    }
    
    private func post<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint, method: "POST", body: body)
    }
    
    private func put<T: Decodable, B: Encodable>(_ endpoint: String, body: B) async throws -> T {
        try await request(endpoint, method: "PUT", body: body)
    }
    
    private func request<T: Decodable, B: Encodable>(_ endpoint: String, method: String, body: B? = nil as String?) async throws -> T {
        guard let apiKey = apiKey else {
            throw SendGridError.notConfigured
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw SendGridError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SendGridError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw SendGridError.apiError(statusCode: httpResponse.statusCode)
        }
        
        if data.isEmpty {
            return SendGridResponse(success: true) as! T
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Models
struct SendGridEmail: Codable {
    let personalizations: [SendGridPersonalization]
    let from: SendGridEmailAddress
    let subject: String
    let content: [SendGridContent]
}

struct SendGridTemplateEmail: Codable {
    let personalizations: [SendGridTemplatePersonalization]
    let from: SendGridEmailAddress
    let templateId: String
    
    enum CodingKeys: String, CodingKey {
        case personalizations, from
        case templateId = "template_id"
    }
}

struct SendGridPersonalization: Codable {
    let to: [SendGridEmailAddress]
}

struct SendGridTemplatePersonalization: Codable {
    let to: [SendGridEmailAddress]
    let dynamicTemplateData: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case to
        case dynamicTemplateData = "dynamic_template_data"
    }
}

struct SendGridEmailAddress: Codable {
    let email: String
    let name: String?
    
    init(email: String, name: String? = nil) {
        self.email = email
        self.name = name
    }
}

struct SendGridContent: Codable {
    let type: String
    let value: String
}

struct SendGridContact: Codable {
    let email: String
    let firstName: String?
    let lastName: String?
    
    enum CodingKeys: String, CodingKey {
        case email
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

struct SendGridContactResponse: Codable {
    let jobId: String?
    
    enum CodingKeys: String, CodingKey {
        case jobId = "job_id"
    }
}

struct SendGridTemplate: Codable {
    let id: String
    let name: String
    let generation: String
}

struct SendGridTemplateCreate: Codable {
    let name: String
    let generation: String
}

struct SendGridStat: Codable {
    let date: String
    let stats: [SendGridStatMetric]
}

struct SendGridStatMetric: Codable {
    let metrics: SendGridMetrics
}

struct SendGridMetrics: Codable {
    let blocks: Int
    let bounces: Int
    let clicks: Int
    let delivered: Int
    let opens: Int
    let requests: Int
}

struct SendGridResponse: Codable {
    let success: Bool
}

enum SendGridError: Error {
    case notConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
}
