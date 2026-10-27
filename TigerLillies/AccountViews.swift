import SwiftUI

struct OrdersView: View {
    @EnvironmentObject private var store: TigerStore
    @State private var showEdit = false
    @State private var selectedReviewOrder: UUID? = nil
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: "Your orders", subtitle: "Everything in one place, from request to ready")
                if store.db.orders.isEmpty {
                    EmptyState(title: "No orders yet", message: "Your demo orders will appear here with their current status and pickup time.", symbol: "shippingbox")
                } else {
                    ForEach(store.db.orders.sorted(by: { $0.placedAt > $1.placedAt })) { order in
                        RoundedPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Order #\(order.shortID)").font(.headline)
                                        Text(order.placedAt.shortDate).font(.caption).foregroundStyle(TL.muted)
                                    }
                                    Spacer()
                                    TinyTag(text: order.status.title, dark: order.status == .ready)
                                }
                                HStack(spacing: 8) {
                                    Image(systemName: order.status.symbol).font(.title2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(order.status == .ready ? "Ready for pickup" : "Status: \(order.status.title)")
                                            .font(.subheadline.bold())
                                        Text("Requested: \(order.requestedPickup.shortDate)")
                                            .font(.caption).foregroundStyle(TL.muted)
                                    }
                                }
                                Divider()
                                ForEach(order.lines) { line in
                                    HStack(alignment: .top) {
                                        Text("\(line.quantity)× \(line.title)").font(.subheadline)
                                        Spacer()
                                        Text(line.subtotal.asMoney).font(.subheadline)
                                    }
                                    if !line.preferences.isEmpty {
                                        Text(line.preferences).font(.caption).foregroundStyle(TL.muted)
                                    }
                                }
                                HStack {
                                    Text("Total").font(.subheadline.bold())
                                    Spacer()
                                    Text(order.total.asMoney).font(.headline)
                                }
                                if order.status.isEditable {
                                    Button("Edit this order") {
                                        store.editOrder(order)
                                        showEdit = true
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(TL.ink)
                                } else if order.status == .completed && !store.db.reviews.contains(where: { $0.orderID == order.id }) {
                                    Button("Rate your experience") { selectedReviewOrder = order.id }
                                        .buttonStyle(.bordered)
                                } else if order.status == .completed {
                                    Label("Thank you for your review", systemImage: "star.fill")
                                        .font(.caption).foregroundStyle(TL.muted)
                                }
                                if order.status == .preparing || order.status == .accepted {
                                    Text("Need to change it? Message the shop. The prototype's chat is local only.")
                                        .font(.caption).foregroundStyle(TL.muted)
                                }
                            }
                        }
                    }
                }
                DemoFootnote()
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("Orders")
        .navigationDestination(isPresented: $showEdit) { CartView() }
        .sheet(item: Binding(
            get: { selectedReviewOrder.map { IdentifiedOrderID(id: $0) } },
            set: { selectedReviewOrder = $0?.id }
        )) { value in
            ReviewForm(orderID: value.id)
        }
    }
}

struct IdentifiedOrderID: Identifiable { let id: UUID }

struct ReviewForm: View {
    @EnvironmentObject private var store: TigerStore
    @Environment(\.dismiss) private var dismiss
    let orderID: UUID
    @State private var rating = 5
    @State private var comment = ""
    var body: some View {
        NavigationStack {
            Form {
                Section("Your experience") {
                    HStack(spacing: 6) {
                        ForEach(1...5, id: \.self) { num in
                            Button { rating = num } label: {
                                Image(systemName: num <= rating ? "star.fill" : "star")
                                    .font(.title)
                            }
                            .buttonStyle(.plain)
                        }
                    }.padding(.vertical, 10)
                    TextField("What did you think?", text: $comment, axis: .vertical).lineLimit(3...7)
                }
                Section { Text("This is private demo feedback, not a public Google review.").font(.caption) }
            }
            .navigationTitle("Leave feedback")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit") { store.leaveReview(orderID: orderID, stars: rating, comment: comment); dismiss() }
                }
            }
        }
    }
}

struct RewardsView: View {
    @EnvironmentObject private var store: TigerStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionHeading(title: "Tiger Stars", subtitle: "A clearer, consistent way to earn rewards")
                VStack(alignment: .leading, spacing: 17) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("YOUR BALANCE").font(.caption.bold()).tracking(2).foregroundStyle(.white.opacity(0.73))
                            Text("\(store.earnedStars)")
                                .font(.system(size: 58, weight: .light, design: .serif))
                            Text("STARS").font(.caption.bold()).tracking(2)
                        }
                        Spacer()
                        Image(systemName: "star.circle").font(.system(size: 55, weight: .ultraLight))
                    }
                    ProgressView(value: store.pointsProgress).tint(.white)
                    Text(store.earnedStars >= 100 ? "You've reached a 100-star milestone!" : "\(store.nextRewardRemaining) stars until your first 100-star milestone")
                        .font(.subheadline)
                    Text("Rewards are illustrative until the business confirms a redemption policy.")
                        .font(.caption).foregroundStyle(.white.opacity(0.72))
                }
                .padding(22)
                .foregroundStyle(.white)
                .background(TL.ink, in: RoundedRectangle(cornerRadius: 24))
                HStack(spacing: 12) {
                    RoundedPanel {
                        Image(systemName: "flame").font(.title3)
                        Text("\(store.purchaseStreak)-day streak").font(.headline)
                        Text("Consecutive purchase days").font(.caption).foregroundStyle(TL.muted)
                    }
                    RoundedPanel {
                        Image(systemName: "bag").font(.title3)
                        Text("\(store.db.orders.filter { $0.status == .completed }.count) orders").font(.headline)
                        Text("Completed in this demo").font(.caption).foregroundStyle(TL.muted)
                    }
                }
                SectionHeading(title: "How stars work")
                RoundedPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("1 star for every $1 spent", systemImage: "star")
                            .font(.subheadline.bold())
                        Text("Points are based on the completed order total, rounded down to whole dollars. No stars are awarded for orders that are pending or cancelled.")
                            .font(.subheadline).foregroundStyle(TL.muted)
                        Divider()
                        Label("100-star milestone", systemImage: "gift")
                            .font(.subheadline.bold())
                        Text("Suggested future perk: $5 off. Redemptions are disabled in this test because no real checkout or rewards integration is connected.")
                            .font(.subheadline).foregroundStyle(TL.muted)
                        Divider()
                        Label("Streaks count purchase days", systemImage: "flame")
                            .font(.subheadline.bold())
                        Text("One or more completed purchases on consecutive days keeps your streak going. Multiple purchases in one day count as one day.")
                            .font(.subheadline).foregroundStyle(TL.muted)
                    }
                }
                SectionHeading(title: "Saved custom orders")
                if store.db.savedArrangements.isEmpty {
                    RoundedPanel {
                        Text("Save a personalized drink or arrangement from any product page to reorder it quickly.")
                            .font(.subheadline).foregroundStyle(TL.muted)
                    }
                } else {
                    ForEach(store.db.savedArrangements) { preset in
                        RoundedPanel {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(preset.name).font(.headline)
                                Text(preset.preferences.isEmpty ? "No special notes" : preset.preferences)
                                    .font(.caption).foregroundStyle(TL.muted)
                                HStack {
                                    if let product = store.product(preset.productID) {
                                        Button("Add to bag") { store.addToCart(product, preferences: preset.preferences) }
                                            .font(.subheadline.bold())
                                    }
                                    Spacer()
                                    Button("Delete", role: .destructive) { store.removeArrangement(preset.id) }
                                        .font(.caption).foregroundStyle(TL.muted)
                                }
                            }
                        }
                    }
                }
                DemoFootnote()
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("Rewards")
    }
}

struct MoreView: View {
    @EnvironmentObject private var store: TigerStore
    let openOwner: () -> Void
    @State private var confirmReset = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BrandMark()
                SectionHeading(title: "Your Tiger Lillies", subtitle: "A personal space for the little things")
                RoundedPanel {
                    NavigationLink(destination: NoticeView()) {
                        Label("Notifications · \(store.unreadNotices) unread", systemImage: "bell")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    NavigationLink(destination: MessagesView(ownerSide: false)) {
                        Label("Message the shop", systemImage: "bubble.left.and.bubble.right")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Divider()
                    NavigationLink(destination: RewardsView()) {
                        Label("My saved orders & stars", systemImage: "star")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                RoundedPanel {
                    Toggle(isOn: Binding(get: { store.db.remindersEnabled }, set: { store.setReminders($0) })) {
                        Label("Device reminders", systemImage: "bell.badge")
                    }
                    Text("Allow local notifications when a test order is marked ready. Real push notifications need a connected server.")
                        .font(.caption).foregroundStyle(TL.muted)
                }
                RoundedPanel {
                    Label("Offline-first demo", systemImage: "wifi.slash").font(.headline)
                    Text("Your catalog, saved customizations, order history and messages are stored on this phone. Data is not synced with staff devices or the existing website.")
                        .font(.subheadline).foregroundStyle(TL.muted)
                }
                SolidButton(title: "Open owner demo", icon: "person.crop.rectangle.stack") { openOwner() }
                Button("Reset all local test data", role: .destructive) { confirmReset = true }
                    .font(.footnote)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                Text("Tiger Lillies Floral & Coffee\n205 Club Ln, Hamilton, GA 31811\n(706) 801-0021")
                    .font(.caption).foregroundStyle(TL.muted)
                    .frame(maxWidth: .infinity).multilineTextAlignment(.center)
                DemoFootnote()
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("More")
        .alert("Reset this prototype?", isPresented: $confirmReset) {
            Button("Delete demo data", role: .destructive) { store.resetDemo() }
            Button("Cancel", role: .cancel) { }
        } message: { Text("Local orders, stars, saved designs, messages and owner edits will be cleared. This can't be undone.") }
    }
}

struct NoticeView: View {
    @EnvironmentObject private var store: TigerStore
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if store.db.notices.isEmpty { EmptyState(title: "All caught up", message: "New items and order updates will appear here.", symbol: "bell") }
                ForEach(store.db.notices) { note in
                    RoundedPanel {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: note.kind == .reward ? "star" : note.kind == .message ? "bubble.left" : "bell")
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(note.title).font(.headline)
                                Text(note.body).font(.subheadline).foregroundStyle(TL.muted)
                                Text(note.date.shortDate).font(.caption2).foregroundStyle(TL.muted)
                            }
                            Spacer()
                            if !note.read { Circle().fill(TL.ink).frame(width: 7, height: 7) }
                        }
                    }
                }
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("Notifications")
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Mark read") { store.markAllRead() }.font(.caption) } }
    }
}

struct MessagesView: View {
    @EnvironmentObject private var store: TigerStore
    let ownerSide: Bool
    @State private var draft = ""
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 13) {
                    Text("Local prototype conversation · Not delivered to another phone")
                        .font(.caption).foregroundStyle(TL.muted)
                        .multilineTextAlignment(.center)
                        .padding()
                    ForEach(store.db.messages) { msg in
                        HStack {
                            if msg.sender == "shop" { Spacer(minLength: 35) }
                            VStack(alignment: .leading, spacing: 5) {
                                Text(msg.sender == "shop" ? "TIGER LILLIES" : "CUSTOMER")
                                    .font(.caption2.bold()).tracking(0.7)
                                Text(msg.text).font(.subheadline)
                                Text(msg.date.formatted(date: .omitted, time: .shortened))
                                    .font(.caption2).foregroundStyle(TL.muted)
                            }
                            .padding(12)
                            .background(msg.sender == "shop" ? TL.soft : .white, in: RoundedRectangle(cornerRadius: 15))
                            if msg.sender != "shop" { Spacer(minLength: 35) }
                        }
                    }
                }
                .padding(16)
            }
            HStack(spacing: 9) {
                TextField(ownerSide ? "Reply to customer…" : "Ask about your order…", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                Button {
                    store.sendMessage(draft, from: ownerSide ? "shop" : "customer")
                    draft = ""
                } label: { Image(systemName: "arrow.up.circle.fill").font(.system(size: 31)) }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12).background(.white)
        }
        .background(TL.bg)
        .navigationTitle(ownerSide ? "Customer messages" : "Message the shop")
        .navigationBarTitleDisplayMode(.inline)
    }
}
