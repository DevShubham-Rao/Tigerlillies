import Foundation

// All purchases and website entries are local demo records. No real money or store API is involved.
enum ProductCategory: String, Codable, CaseIterable, Identifiable {
    case flowers = "Flowers"
    case coffee = "Coffee"
    case plants = "Plants & Gifts"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .flowers: return "camera.macro"; case .coffee: return "cup.and.saucer"; case .plants: return "leaf" }
    }
}

struct CatalogProduct: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var details: String
    var price: Double
    var category: ProductCategory
    var isAvailable: Bool = true
    var customizable: Bool = true
    var isFeatured: Bool = false
}

struct CartLine: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var productID: String
    var title: String
    var unitPrice: Double
    var quantity: Int
    var preferences: String
    var subtotal: Double { unitPrice * Double(quantity) }
}

enum OrderStatus: String, Codable, CaseIterable, Identifiable {
    case placed, accepted, preparing, ready, completed, cancelled
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .placed: return "clock"
        case .accepted: return "checkmark.circle"
        case .preparing: return "hands.sparkles"
        case .ready: return "bell.badge"
        case .completed: return "checkmark.seal.fill"
        case .cancelled: return "xmark.circle"
        }
    }
    var isEditable: Bool { self == .placed }
}

struct StoreOrder: Codable, Identifiable {
    var id: UUID = UUID()
    var placedAt: Date = Date()
    var requestedPickup: Date
    var customerName: String
    var lines: [CartLine]
    var instructions: String
    var status: OrderStatus = .placed
    var rewardPointsIssued: Int = 0
    var discount: Double = 0
    var total: Double { max(0, lines.reduce(0) { $0 + $1.subtotal } - discount) }
    var shortID: String { String(id.uuidString.prefix(6)).uppercased() }
}

enum NoteKind: String, Codable { case order, reward, message, announcement }
struct AppNotice: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var title: String
    var body: String
    var kind: NoteKind
    var read: Bool = false
}

struct ChatMessage: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var sender: String // "customer" or "shop" in this local demo
    var text: String
}

struct SavedArrangement: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var productID: String
    var preferences: String
}

struct WebsiteSale: Codable, Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var amount: Double
    var note: String
}

struct CustomerReview: Codable, Identifiable {
    var id: UUID = UUID()
    var orderID: UUID
    var rating: Int
    var comment: String
    var date: Date = Date()
}

struct DemoDatabase: Codable {
    var customerName: String = "Guest"
    var catalog: [CatalogProduct] = DemoDatabase.sampleCatalog
    var orders: [StoreOrder] = []
    var cart: [CartLine] = []
    var notices: [AppNotice] = [AppNotice(title: "Welcome to Tiger Lillies", body: "Your flowers, coffee and rewards in one place. This is a local demo.", kind: .announcement)]
    var messages: [ChatMessage] = [ChatMessage(sender: "shop", text: "Welcome! Send us a question or custom flower request. Messages stay on this device in the prototype.")]
    var savedArrangements: [SavedArrangement] = []
    var websiteSales: [WebsiteSale] = []
    var reviews: [CustomerReview] = []
    var remindersEnabled: Bool = false
    var lastAppOpen: Date = Date()

    static let sampleCatalog: [CatalogProduct] = [
        CatalogProduct(id: "cutie-cup", title: "Cutie Cup", details: "A sweet, petite floral arrangement. From $55.", price: 55, category: .flowers, isFeatured: true),
        CatalogProduct(id: "low-lush", title: "Low and Lush", details: "Hand-selected fresh blooms in a low vase. From $80.", price: 80, category: .flowers, isFeatured: true),
        CatalogProduct(id: "tall-beautiful", title: "Tall and Beautiful", details: "An expressive arrangement, made fresh. From $85.", price: 85, category: .flowers),
        CatalogProduct(id: "mum-grab", title: "Mum Grab and Go", details: "Seasonal October special. Availability may vary.", price: 25, category: .plants, isFeatured: true),
        CatalogProduct(id: "oh-my-gourd", title: "Oh My Gourd!", details: "Fall espresso with pumpkin spice, cinnamon & white chocolate. From $6.25.", price: 6.25, category: .coffee, isFeatured: true),
        CatalogProduct(id: "southern-pecan", title: "Southern Pecan", details: "A cozy seasonal coffee. From $6.25.", price: 6.25, category: .coffee),
        CatalogProduct(id: "nutty-nana", title: "Nutty Nana", details: "A seasonal coffee favorite. Price starts at $6.25.", price: 6.25, category: .coffee)
    ]
}

extension Double { var asMoney: String { formatted(.currency(code: "USD")) } }
extension Date { var shortDate: String { formatted(date: .abbreviated, time: .shortened) } }
