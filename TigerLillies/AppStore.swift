import SwiftUI
import UserNotifications

@MainActor
final class TigerStore: ObservableObject {
    @Published private(set) var db: DemoDatabase
    @Published var editingOrderID: UUID? = nil
    @Published var toast: String? = nil
    private let location: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        location = docs.appendingPathComponent("tiger-lillies-demo.json")
        if let data = try? Data(contentsOf: location), let saved = try? JSONDecoder().decode(DemoDatabase.self, from: data) {
            db = saved
        } else {
            db = DemoDatabase()
        }
        // Inactivity reminders are recorded locally the next time the app is opened.
        if Date().timeIntervalSince(db.lastAppOpen) >= 14 * 24 * 3600 {
            let points = db.orders.reduce(0) { $0 + $1.rewardPointsIssued }
            db.notices.insert(AppNotice(title: "It's been a while!", body: "Welcome back — you have \(points) Tiger Stars waiting in this demo.", kind: .reward), at: 0)
        }
        db.lastAppOpen = Date()
        save()
    }

    private func save() {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(db)
            try data.write(to: location, options: [.atomic])
        } catch { toast = "Could not save changes locally: \(error.localizedDescription)" }
    }
    private func change(_ work: (inout DemoDatabase) -> Void) { work(&db); save() }

    func product(_ id: String) -> CatalogProduct? { db.catalog.first(where: { $0.id == id }) }
    var cartCount: Int { db.cart.reduce(0) { $0 + $1.quantity } }
    var subtotal: Double { db.cart.reduce(0) { $0 + $1.subtotal } }
    var unreadNotices: Int { db.notices.filter { !$0.read }.count }
    var earnedStars: Int { db.orders.reduce(0) { $0 + $1.rewardPointsIssued } }
    var nextRewardRemaining: Int { let residue = earnedStars % 100; return residue == 0 && earnedStars > 0 ? 0 : 100 - residue }
    var pointsProgress: Double { Double(earnedStars % 100) / 100.0 }
    var appSales: Double { db.orders.filter { $0.status == .completed }.reduce(0) { $0 + $1.total } }
    var websiteSales: Double { db.websiteSales.reduce(0) { $0 + $1.amount } }
    var ordersToPrepare: [StoreOrder] { db.orders.filter { ![.completed, .cancelled].contains($0.status) }.sorted { $0.requestedPickup < $1.requestedPickup } }

    var purchaseStreak: Int {
        let calendar = Calendar.current
        let dayKeys = Set(db.orders.filter { $0.status == .completed }.map { calendar.startOfDay(for: $0.placedAt) })
        var date = calendar.startOfDay(for: Date())
        if !dayKeys.contains(date), let yesterday = calendar.date(byAdding: .day, value: -1, to: date), dayKeys.contains(yesterday) { date = yesterday }
        else if !dayKeys.contains(date) { return 0 }
        var result = 0
        while dayKeys.contains(date) {
            result += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return result
    }

    func addToCart(_ product: CatalogProduct, quantity: Int = 1, preferences: String = "") {
        guard product.isAvailable else { toast = "This item is currently unavailable."; return }
        change { db in
            db.cart.append(CartLine(productID: product.id, title: product.title, unitPrice: product.price, quantity: max(1, quantity), preferences: preferences))
        }
        toast = "Added to your bag"
    }
    func updateCartLine(_ id: UUID, quantity: Int) {
        change { db in
            guard let index = db.cart.firstIndex(where: { $0.id == id }) else { return }
            if quantity < 1 { db.cart.remove(at: index) } else { db.cart[index].quantity = quantity }
        }
    }
    func removeCartLine(_ id: UUID) { change { $0.cart.removeAll(where: { $0.id == id }) } }
    func updateCartNote(_ id: UUID, note: String) { change { db in
        if let i = db.cart.firstIndex(where: { $0.id == id }) { db.cart[i].preferences = note }
    } }
    func clearCart() { change { $0.cart = [] }; editingOrderID = nil }

    @discardableResult
    func submitDemoOrder(name: String, pickup: Date, instructions: String) -> Bool {
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty, !db.cart.isEmpty else { toast = "Enter your name and add an item first."; return false }
        guard pickup > Date() else { toast = "Choose a future pickup time."; return false }
        guard db.cart.allSatisfy({ product($0.productID)?.isAvailable == true }) else {
            toast = "One of your items is unavailable. Please adjust your bag."; return false
        }
        let editing = editingOrderID
        if let orderID = editing, let index = db.orders.firstIndex(where: { $0.id == orderID && $0.status.isEditable }) {
            change { db in
                db.orders[index].lines = db.cart
                db.orders[index].customerName = cleanName
                db.orders[index].requestedPickup = pickup
                db.orders[index].instructions = instructions
                db.cart = []
                db.customerName = cleanName
            }
            addNotice("Order \(String(orderID.uuidString.prefix(6)).uppercased()) updated", "Your changes are saved on this phone.", .order)
        } else {
            let order = StoreOrder(requestedPickup: pickup, customerName: cleanName, lines: db.cart, instructions: instructions)
            change { db in
                db.orders.insert(order, at: 0)
                db.cart = []
                db.customerName = cleanName
            }
            addNotice("Demo order submitted", "Order \(order.shortID) is waiting for the shop to accept it in this prototype.", .order)
        }
        editingOrderID = nil
        return true
    }

    func editOrder(_ order: StoreOrder) {
        guard order.status.isEditable else { toast = "This order is already in progress. Contact the shop for changes."; return }
        change { $0.cart = order.lines }
        editingOrderID = order.id
    }
    func cancelEdit() { editingOrderID = nil; change { $0.cart = [] } }

    func advanceOrder(_ id: UUID, to newStatus: OrderStatus) {
        guard let old = db.orders.first(where: { $0.id == id }) else { return }
        let valid: [OrderStatus: [OrderStatus]] = [
            .placed: [.accepted, .cancelled], .accepted: [.preparing, .cancelled],
            .preparing: [.ready], .ready: [.completed], .completed: [], .cancelled: []
        ]
        guard valid[old.status, default: []].contains(newStatus) else { toast = "That status change is not available."; return }
        change { db in
            guard let index = db.orders.firstIndex(where: { $0.id == id }) else { return }
            db.orders[index].status = newStatus
            if newStatus == .completed && db.orders[index].rewardPointsIssued == 0 {
                db.orders[index].rewardPointsIssued = Int(db.orders[index].total.rounded(.down))
            }
        }
        let title = newStatus == .ready ? "Your order is ready!" : "Order \(old.shortID): \(newStatus.title)"
        let body = newStatus == .ready ? "Your pickup order \(old.shortID) is ready to collect." : "Your local demo order has moved to \(newStatus.title.lowercased())."
        addNotice(title, body, .order)
        if newStatus == .ready { pushLocalAlert(title, body) }
        if newStatus == .completed {
            let earned = db.orders.first(where: { $0.id == id })?.rewardPointsIssued ?? 0
            addNotice("\(earned) stars earned", "Thanks for shopping! Your completed order earned \(earned) stars.", .reward)
        }
    }

    func addNotice(_ title: String, _ body: String, _ kind: NoteKind) {
        change { $0.notices.insert(AppNotice(title: title, body: body, kind: kind), at: 0) }
    }
    func markAllRead() { change { db in for i in db.notices.indices { db.notices[i].read = true } } }
    func sendMessage(_ content: String, from sender: String) {
        let text = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        change { $0.messages.append(ChatMessage(sender: sender, text: text)) }
        if sender == "shop" { addNotice("A message from Tiger Lillies", text, .message); pushLocalAlert("Tiger Lillies replied", text) }
    }
    func saveArrangement(name: String, productID: String, preferences: String) {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        change { $0.savedArrangements.append(SavedArrangement(name: clean, productID: productID, preferences: preferences)) }
        toast = "Custom order saved"
    }
    func removeArrangement(_ id: UUID) { change { $0.savedArrangements.removeAll(where: { $0.id == id }) } }
    func addWebsiteSale(amount: Double, note: String, date: Date) {
        guard amount > 0 else { toast = "Enter an amount greater than zero."; return }
        change { $0.websiteSales.insert(WebsiteSale(date: date, amount: amount, note: note), at: 0) }
    }
    func deleteWebsiteSale(_ id: UUID) { change { $0.websiteSales.removeAll(where: { $0.id == id }) } }
    func updateProduct(_ product: CatalogProduct) { change { db in if let i = db.catalog.firstIndex(where: { $0.id == product.id }) { db.catalog[i] = product } } }
    func addProduct(title: String, price: Double, category: ProductCategory, details: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, price >= 0 else { return }
        let item = CatalogProduct(id: UUID().uuidString, title: title, details: details, price: price, category: category)
        change { $0.catalog.append(item) }
        addNotice("New arrival: \(title)", "See what's new in the Tiger Lillies demo shop.", .announcement)
    }
    func leaveReview(orderID: UUID, stars: Int, comment: String) {
        guard (1...5).contains(stars), db.reviews.first(where: { $0.orderID == orderID }) == nil else { return }
        change { $0.reviews.append(CustomerReview(orderID: orderID, rating: stars, comment: comment)) }
        toast = "Thanks for your feedback!"
    }
    func setReminders(_ enabled: Bool) {
        change { $0.remindersEnabled = enabled }
        if enabled {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
        }
    }
    private func pushLocalAlert(_ title: String, _ body: String) {
        guard db.remindersEnabled else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false))
        UNUserNotificationCenter.current().add(request)
    }
    func resetDemo() {
        db = DemoDatabase()
        editingOrderID = nil
        save()
        toast = "Demo data cleared"
    }
}
