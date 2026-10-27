import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: TigerStore
    @State private var showOwner = false
    var body: some View {
        Group {
            if showOwner {
                OwnerPanel(onExit: { showOwner = false })
            } else {
                TabView {
                    NavigationStack { HomeView() }
                        .tabItem { Label("Home", systemImage: "house") }
                    NavigationStack { ShopView() }
                        .tabItem { Label("Shop", systemImage: "bag") }
                    NavigationStack { OrdersView() }
                        .tabItem { Label("Orders", systemImage: "shippingbox") }
                    NavigationStack { RewardsView() }
                        .tabItem { Label("Stars", systemImage: "star") }
                    NavigationStack { MoreView(openOwner: { showOwner = true }) }
                        .tabItem { Label("More", systemImage: "line.3.horizontal") }
                }
            }
        }
        .foregroundStyle(TL.ink)
        .background(TL.bg)
        .overlay(alignment: .top) {
            if let toast = store.toast {
                Text(toast)
                    .font(.callout).fontWeight(.medium)
                    .padding(12)
                    .frame(maxWidth: .infinity)
                    .background(TL.ink, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
                    .padding(.horizontal)
                    .padding(.top, 3)
                    .onTapGesture { store.toast = nil }
            }
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: TigerStore
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                HStack {
                    BrandMark()
                    Spacer()
                    NavigationLink(destination: NoticeView()) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell").font(.title3).padding(10)
                            if store.unreadNotices > 0 { Circle().fill(TL.ink).frame(width: 9, height: 9).offset(x: -8, y: 7) }
                        }
                    }
                    .accessibilityLabel("Notifications")
                }
                HStack {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("A little joy, ready when you are.").font(.system(size: 32, weight: .semibold, design: .serif))
                        Text("Coffee to go. Flowers to make their day.").font(.subheadline).foregroundStyle(TL.muted)
                    }
                    Spacer(minLength: 0)
                }
                VStack(alignment: .leading, spacing: 14) {
                    TinyTag(text: "TIGER LILLIES · HAMILTON", dark: false)
                    Text("Thoughtful blooms.\nDelicious moments.")
                        .font(.system(size: 30, weight: .medium, design: .serif))
                        .foregroundStyle(.white)
                    Text("Personalized pickup orders, kept simple.").font(.footnote).foregroundStyle(.white.opacity(0.73))
                    NavigationLink(destination: ShopView()) {
                        HStack { Text("Browse the shop"); Image(systemName: "arrow.up.right") }
                            .font(.subheadline.bold())
                            .padding(.horizontal, 17).padding(.vertical, 11)
                            .foregroundStyle(TL.ink)
                            .background(.white, in: Capsule())
                    }
                }
                .padding(22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TL.ink, in: RoundedRectangle(cornerRadius: 24))
                HStack(spacing: 12) {
                    NavigationLink(destination: RewardsView()) {
                        RoundedPanel {
                            HStack { Image(systemName: "star.fill"); Text("\(store.earnedStars) stars").font(.subheadline.bold()) }
                            Text("Earn with every completed order").font(.caption).foregroundStyle(TL.muted)
                        }
                    }
                    NavigationLink(destination: OrdersView()) {
                        RoundedPanel {
                            HStack { Image(systemName: "clock.arrow.circlepath"); Text("\(store.ordersToPrepare.count) active").font(.subheadline.bold()) }
                            Text("Track your pickup orders").font(.caption).foregroundStyle(TL.muted)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(title: "Made for your day", subtitle: "The things people come back for")
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(store.db.catalog.filter { $0.isFeatured && $0.isAvailable }) { item in
                                NavigationLink(destination: ProductDetailView(productID: item.id)) {
                                    VStack(alignment: .leading, spacing: 9) {
                                        ProductGlyph(product: item, height: 110)
                                        Text(item.title).font(.subheadline.bold()).lineLimit(1)
                                        Text("From \(item.price.asMoney)").font(.caption).foregroundStyle(TL.muted)
                                    }
                                    .padding(9)
                                    .frame(width: 160)
                                    .background(.white, in: RoundedRectangle(cornerRadius: 19))
                                    .overlay(RoundedRectangle(cornerRadius: 19).stroke(TL.border))
                                }
                            }
                        }
                    }
                }
                if !store.db.savedArrangements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Your saved favorites")
                        ForEach(store.db.savedArrangements.prefix(2)) { preset in
                            if let item = store.product(preset.productID) {
                                RoundedPanel {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(preset.name).font(.headline)
                                            Text("\(item.title) · \(preset.preferences)").font(.caption).foregroundStyle(TL.muted).lineLimit(2)
                                        }
                                        Spacer()
                                        Button("Add") { store.addToCart(item, preferences: preset.preferences) }
                                            .font(.callout.bold())
                                    }
                                }
                            }
                        }
                    }
                }
                RoundedPanel {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "mappin.and.ellipse").font(.title2)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Local pickup").font(.headline)
                            Text("205 Club Ln · Hamilton, GA 31811")
                            Text("Pickup requests need shop confirmation. Hours and availability may change.")
                                .font(.caption).foregroundStyle(TL.muted)
                        }
                    }
                }
                DemoFootnote()
            }.padding(18)
        }
        .background(TL.bg)
        .navigationBarHidden(true)
    }
}

struct ShopView: View {
    @EnvironmentObject private var store: TigerStore
    @State private var selection = "All"
    @State private var search = ""
    var products: [CatalogProduct] {
        store.db.catalog.filter {
            (selection == "All" || $0.category.rawValue == selection) &&
            (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.details.localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 17) {
                SectionHeading(title: "The shop", subtitle: "Coffee, flowers, and everything in between")
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search the menu", text: $search)
                        .textInputAutocapitalization(.never)
                }
                .padding(13).background(.white, in: RoundedRectangle(cornerRadius: 14))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(["All"] + ProductCategory.allCases.map(\.rawValue), id: \.self) { category in
                            Button(category) { selection = category }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 15).padding(.vertical, 9)
                                .background(selection == category ? TL.ink : .white, in: Capsule())
                                .foregroundStyle(selection == category ? .white : TL.ink)
                        }
                    }
                }
                if products.isEmpty {
                    EmptyState(title: "Nothing found", message: "Try another search or category.", symbol: "magnifyingglass")
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(products) { item in
                            NavigationLink(destination: ProductDetailView(productID: item.id)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    ProductGlyph(product: item, height: 130)
                                    Text(item.title).font(.headline).lineLimit(2).frame(height: 43, alignment: .topLeading)
                                    Text("From \(item.price.asMoney)").font(.subheadline).foregroundStyle(TL.muted)
                                    if item.isAvailable { TinyTag(text: "Customize") } else { TinyTag(text: "Unavailable") }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(10)
                                .background(.white, in: RoundedRectangle(cornerRadius: 18))
                            }
                        }
                    }
                }
                Text("Illustrative starting prices from the public catalog; the owner must verify live pricing and stock.")
                    .font(.caption2).foregroundStyle(TL.muted)
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("Shop")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: CartView()) {
                    HStack(spacing: 4) { Image(systemName: "bag"); if store.cartCount > 0 { Text("\(store.cartCount)").font(.caption.bold()) } }
                }
            }
        }
    }
}

struct ProductDetailView: View {
    @EnvironmentObject private var store: TigerStore
    let productID: String
    @State private var qty = 1
    @State private var preference = ""
    @State private var presetName = ""
    @State private var showSaved = false
    var body: some View {
        ScrollView {
            if let item = store.product(productID) {
                VStack(alignment: .leading, spacing: 20) {
                    ProductGlyph(product: item, height: 215)
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            TinyTag(text: item.category.rawValue)
                            Text(item.title).font(.system(size: 31, weight: .semibold, design: .serif))
                            Text("From \(item.price.asMoney)").font(.title3.weight(.medium))
                        }
                        Spacer()
                    }
                    Text(item.details).font(.subheadline).foregroundStyle(TL.muted)
                    RoundedPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Make it yours").font(.headline)
                            Text(item.category == .coffee ? "Hot or iced, milk preferences, sweetness, and special instructions" : "Colors, favorite blooms, sizes, card message, and flowers to avoid")
                                .font(.caption).foregroundStyle(TL.muted)
                            TextField("Your preferences or special instructions", text: $preference, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(12)
                                .background(TL.bg, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    HStack {
                        Text("Quantity").font(.headline)
                        Spacer()
                        Button { qty = max(1, qty - 1) } label: { Image(systemName: "minus.circle") }
                        Text("\(qty)").monospacedDigit().frame(width: 30)
                        Button { qty = min(30, qty + 1) } label: { Image(systemName: "plus.circle") }
                    }
                    .font(.title3)
                    SolidButton(title: "Add to bag · \((item.price * Double(qty)).asMoney)", icon: "bag", disabled: !item.isAvailable) {
                        store.addToCart(item, quantity: qty, preferences: preference)
                    }
                    Button("Save these customizations") { showSaved = true }
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .disabled(!item.isAvailable)
                    Text("Prices can vary by size or substitutions. This demo does not calculate those adjustments or send a real order.")
                        .font(.caption).foregroundStyle(TL.muted)
                }
                .padding(18)
                .alert("Save a favorite", isPresented: $showSaved) {
                    TextField("Favorite name", text: $presetName)
                    Button("Save") { store.saveArrangement(name: presetName, productID: item.id, preferences: preference); presetName = "" }
                    Button("Cancel", role: .cancel) { }
                } message: { Text("Reorder these preferences in a tap next time.") }
            }
        }
        .background(TL.bg)
        .navigationTitle("Item details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { NavigationLink(destination: CartView()) { Image(systemName: "bag") } } }
    }
}

struct CartView: View {
    @EnvironmentObject private var store: TigerStore
    @State private var name = ""
    @State private var instructions = ""
    @State private var pickup = Date().addingTimeInterval(3600)
    @State private var showConfirmation = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: store.editingOrderID == nil ? "Your bag" : "Edit your order", subtitle: "A simple way to place even complex pickup requests")
                if store.db.cart.isEmpty {
                    EmptyState(title: "Your bag is empty", message: "Explore coffee and florals, and add your favorites.", symbol: "bag")
                } else {
                    ForEach(store.db.cart) { line in
                        RoundedPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(line.title).font(.headline)
                                        Text(line.unitPrice.asMoney).font(.footnote).foregroundStyle(TL.muted)
                                    }
                                    Spacer()
                                    Text(line.subtotal.asMoney).fontWeight(.semibold)
                                }
                                HStack {
                                    Button { store.updateCartLine(line.id, quantity: line.quantity - 1) } label: { Image(systemName: "minus.circle") }
                                    Text("\(line.quantity)").monospacedDigit()
                                    Button { store.updateCartLine(line.id, quantity: line.quantity + 1) } label: { Image(systemName: "plus.circle") }
                                    Spacer()
                                    Button("Remove") { store.removeCartLine(line.id) }.font(.caption).foregroundStyle(TL.muted)
                                }
                                TextField("Item notes / modifications", text: Binding(
                                    get: { store.db.cart.first(where: { $0.id == line.id })?.preferences ?? "" },
                                    set: { store.updateCartNote(line.id, note: $0) }), axis: .vertical)
                                    .lineLimit(1...3)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    RoundedPanel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Pickup details").font(.headline)
                            TextField("Name for pickup", text: $name)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                            DatePicker("Requested date & time", selection: $pickup, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                            TextField("Anything the shop should know?", text: $instructions, axis: .vertical)
                                .lineLimit(2...4)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    RoundedPanel {
                        HStack {
                            Text("Estimated total").font(.headline)
                            Spacer()
                            Text(store.subtotal.asMoney).font(.title3.bold())
                        }
                        Text("Demo only: no tax, live availability check, or payment collection. Pickup requests need staff confirmation.")
                            .font(.caption).foregroundStyle(TL.muted)
                    }
                    SolidButton(title: store.editingOrderID == nil ? "Place test order" : "Save order changes", icon: "checkmark") {
                        showConfirmation = store.submitDemoOrder(name: name, pickup: pickup, instructions: instructions)
                    }
                    if store.editingOrderID != nil {
                        Button("Discard edits") { store.cancelEdit() }
                            .font(.subheadline).frame(maxWidth: .infinity)
                    }
                }
                DemoFootnote()
            }.padding(18)
        }
        .background(TL.bg)
        .navigationTitle("Bag")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = store.db.customerName == "Guest" ? "" : store.db.customerName
            if let orderID = store.editingOrderID, let order = store.db.orders.first(where: { $0.id == orderID }) {
                pickup = order.requestedPickup
                instructions = order.instructions
                name = order.customerName
            }
        }
        .alert("Test order saved", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) { }
        } message: { Text("Your order is saved locally on this device. It was not sent to Tiger Lillies or charged.") }
    }
}
