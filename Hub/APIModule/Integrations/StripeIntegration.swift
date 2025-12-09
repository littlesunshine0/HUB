import Foundation

// MARK: - Stripe Integration
class StripeIntegration {
    static let shared = StripeIntegration()
    
    private var apiKey: String?
    private let baseURL = "https://api.stripe.com/v1"
    
    func configure(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Customers
    func createCustomer(email: String, name: String) async throws -> StripeCustomer {
        let params = ["email": email, "name": name]
        return try await post("/customers", parameters: params)
    }
    
    func getCustomer(id: String) async throws -> StripeCustomer {
        return try await get("/customers/\(id)")
    }
    
    // MARK: - Payment Intents
    func createPaymentIntent(amount: Int, currency: String = "usd", customerId: String? = nil) async throws -> StripePaymentIntent {
        var params = ["amount": "\(amount)", "currency": currency]
        if let customerId = customerId {
            params["customer"] = customerId
        }
        return try await post("/payment_intents", parameters: params)
    }
    
    func confirmPaymentIntent(id: String, paymentMethod: String) async throws -> StripePaymentIntent {
        let params = ["payment_method": paymentMethod]
        return try await post("/payment_intents/\(id)/confirm", parameters: params)
    }
    
    // MARK: - Subscriptions
    func createSubscription(customerId: String, priceId: String) async throws -> StripeSubscription {
        let params = [
            "customer": customerId,
            "items[0][price]": priceId
        ]
        return try await post("/subscriptions", parameters: params)
    }
    
    func cancelSubscription(id: String) async throws -> StripeSubscription {
        return try await delete("/subscriptions/\(id)")
    }
    
    // MARK: - Products & Prices
    func createProduct(name: String, description: String? = nil) async throws -> StripeProduct {
        var params = ["name": name]
        if let description = description {
            params["description"] = description
        }
        return try await post("/products", parameters: params)
    }
    
    func createPrice(productId: String, unitAmount: Int, currency: String = "usd", recurring: Bool = false) async throws -> StripePrice {
        var params = [
            "product": productId,
            "unit_amount": "\(unitAmount)",
            "currency": currency
        ]
        if recurring {
            params["recurring[interval]"] = "month"
        }
        return try await post("/prices", parameters: params)
    }
    
    // MARK: - Network Layer
    private func get<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint, method: "GET")
    }
    
    private func post<T: Decodable>(_ endpoint: String, parameters: [String: String]) async throws -> T {
        try await request(endpoint, method: "POST", parameters: parameters)
    }
    
    private func delete<T: Decodable>(_ endpoint: String) async throws -> T {
        try await request(endpoint, method: "DELETE")
    }
    
    private func request<T: Decodable>(_ endpoint: String, method: String, parameters: [String: String]? = nil) async throws -> T {
        guard let apiKey = apiKey else {
            throw StripeError.notConfigured
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw StripeError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        if let parameters = parameters {
            let body = parameters.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = body.data(using: .utf8)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StripeError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw StripeError.apiError(statusCode: httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - Models
struct StripeCustomer: Codable {
    let id: String
    let email: String?
    let name: String?
}

struct StripePaymentIntent: Codable {
    let id: String
    let amount: Int
    let currency: String
    let status: String
    let clientSecret: String?
    
    enum CodingKeys: String, CodingKey {
        case id, amount, currency, status
        case clientSecret = "client_secret"
    }
}

struct StripeSubscription: Codable {
    let id: String
    let status: String
    let customerId: String
    
    enum CodingKeys: String, CodingKey {
        case id, status
        case customerId = "customer"
    }
}

struct StripeProduct: Codable {
    let id: String
    let name: String
    let description: String?
}

struct StripePrice: Codable {
    let id: String
    let productId: String
    let unitAmount: Int
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case id, currency
        case productId = "product"
        case unitAmount = "unit_amount"
    }
}

enum StripeError: Error {
    case notConfigured
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
}
