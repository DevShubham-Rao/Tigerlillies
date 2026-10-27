import SwiftUI

enum OwnerSection: String, CaseIterable, Identifiable {
    case overview = "Overview", orders = "Orders", products = "Products", insights = "Insights"
    var id: String { rawValue }
}

struct OwnerPanel: View {
    @EnvironmentObject private var store: TigerStore
    let onExit: () -> Void
    @State private var section: OwnerSection = .overview
    @State private var showNewProduct = false
    @State private var activeProduct: CatalogProduct? = nil
    @State private var showWebsiteEntry = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            TinyTag(text: "OWNER MODE · LOCAL DEMO", dark: true)
                            Text("Good morning, Tiger Lillies.")
                                .font(.system(size: 30, weight: .semibold, design: .serif))
                            Text("A clearer view of what needs your attention.")
                                .font(.subheadline).foregroundStyle(TL.muted)
                        }
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(OwnerSection.allCases) { item in
                                Button(item.rawValue) { section = item }
                                    .font(.subheadline.weight(.medium))
                                    .padding(.horizontal, 17).padding(.vertical, 10)
                                    .background(section == item ? TL.ink : .white, in: Capsule())
                                    .foregroundStyle(section == item ? .white : TL.ink)
                            }
                        }
                    }
                    switch section {
                    case .overview: overview
                    case .orders: orders
                    case .products: products
                    case .insights: insights
                    }
                    DemoFootnote()
                }
                .padding(18)
            }
            .background(TL.bg)
            .navigationTitle("Owner studio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button { onExit() } label: { Label("Shop", systemImage: "chevron.left") } }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: MessagesView(ownerSide: true)) { Image(systemName: "bubble.left.and.bubble.right") }
                }
            }
            .sheet(isPresented: $showNewProduct) { AddProductView() }
            .sheet(item: $activeProduct) { item in EditProductView(product: item) }
            .sheet(isPresented: $showWebsiteEntry) { ManualWebsiteSaleView() }
        }
    }

    private var overview: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                metric("Orders to handle", "\(store.ordersToPrepare.count)", "shippingbox")
                metric("Completed app sales", store.appSales.asMoney, "iphone")
            }
            HStack(spacing: 12) {
                metric("Manual website sales", store.websiteSales.asMoney, "globe")
                metric("Products in catalog", "\(store.db.catalog.count)", "square.grid.2x2")
            }
            SectionHeading(title: "What's next", subtitle: "Orders sorted by requested pickup time")
            if store.ordersToPrepare.isEmpty {
                RoundedPanel { Text("No active test orders. Place one from the customer shop, then return here to process it.").font(.subheadline).foregroundStyle(TL.muted) }
            } else {
                ForEach(store.ordersToPrepare.prefix(4)) { order in orderControl(order) }
            }
            SectionHeading(title: "Quick actions")
            HStack(spacing: 10) {
                Button { showNewProduct = true } label: {
                    Label("Add item", systemImage: "plus.circle").frame(maxWidth: .infinity).padding(12)
                }.buttonStyle(.bordered)
                Button { showWebsiteEntry = true } label: {
                    Label("Log web sale", systemImage: "plus.circle").frame(maxWidth: .infinity).padding(12)
                }.buttonStyle(.bordered)
            }
            RoundedPanel {
                Label("Offline information stays on this device", systemImage: "wifi.slash")
                    .font(.subheadline.bold())
                Text("Customer and owner modes share this demo database, so you can test the workflow on one phone. This is not a secure staff login or a real website integration.")
                    .font(.caption).foregroundStyle(TL.muted)
            }
        }
    }

    private func metric(_ title: String, _ value: String, _ symbol: String) -> some View {
        RoundedPanel {
            Image(systemName: symbol).font(.title3)
            Text(value).font(.system(size: 24, weight: .semibold, design: .serif)).minimumScaleFactor(0.7).lineLimit(1)
            Text(title).font(.caption).foregroundStyle(TL.muted).fixedSize(horizontal: false, vertical: true)
        }
    }

    private var orders: some View {
        VStack(alignment: .leading, spacing: 13) {
            SectionHeading(title: "Pickup queue", subtitle: "Accept, prepare, and mark each order ready")
            if store.db.orders.isEmpty { EmptyState(title: "Queue is clear", message: "New local demo orders will show up here.", symbol: "tray") }
            ForEach(store.db.orders.sorted(by: { $0.requestedPickup < $1.requestedPickup })) { order in
                orderControl(order)
            }
        }
    }

    private func orderControl(_ order: StoreOrder) -> some View {
        RoundedPanel {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("#\(order.shortID) · \(order.customerName)").font(.headline)
                        Text("Pickup: \(order.requestedPickup.shortDate)")
                            .font(.caption).foregroundStyle(TL.muted)
                    }
                    Spacer()
                    TinyTag(text: order.status.title, dark: order.status == .ready)
                }
                ForEach(order.lines) { line in
                    VStack(alignment: .leading, spacing: 3) {
                        Text("\(line.quantity)× \(line.title)").font(.subheadline.bold())
                        if !line.preferences.isEmpty { Text(line.preferences).font(.caption).foregroundStyle(TL.muted) }
                    }
                }
                if !order.instructions.isEmpty { Text("Note: \(order.instructions)").font(.caption) }
                HStack {
                    Text(order.total.asMoney).font(.headline)
                    Spacer()
                    switch order.status {
                    case .placed:
                        Button("Decline") { store.advanceOrder(order.id, to: .cancelled) }.font(.caption)
                        Button("Accept") { store.advanceOrder(order.id, to: .accepted) }.buttonStyle(.borderedProminent).tint(TL.ink)
                    case .accepted:
                        Button("Start preparing") { store.advanceOrder(order.id, to: .preparing) }.buttonStyle(.borderedProminent).tint(TL.ink)
                    case .preparing:
                        Button("Mark ready") { store.advanceOrder(order.id, to: .ready) }.buttonStyle(.borderedProminent).tint(TL.ink)
                    case .ready:
                        Button("Picked up") { store.advanceOrder(order.id, to: .completed) }.buttonStyle(.borderedProminent).tint(TL.ink)
                    case .completed:
                        Label("Stars issued", systemImage: "star.fill").font(.caption)
                    case .cancelled:
                        Text("Cancelled").font(.caption).foregroundStyle(TL.muted)
                    }
                }
            }
        }
    }

    private var products: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                SectionHeading(title: "Your catalog", subtitle: "Update pricing or pause an item in a tap")
                Button { showNewProduct = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                    .accessibilityLabel("Add product")
            }
            ForEach(store.db.catalog) { item in
                RoundedPanel {
                    HStack(spacing: 12) {
                        Image(systemName: item.category.symbol).font(.title2).frame(width: 34)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.headline)
                            Text("\(item.price.asMoney) · \(item.category.rawValue)")
                                .font(.caption).foregroundStyle(TL.muted)
                        }
                        Spacer()
                        Button("Edit") { activeProduct = item }
                            .font(.subheadline.bold())
                    }
                    Toggle("Available for ordering", isOn: Binding(
                        get: { store.product(item.id)?.isAvailable ?? false },
                        set: { state in var edited = item; edited.isAvailable = state; store.updateProduct(edited) }
                    ))
                    .font(.caption)
                }
            }
            SolidButton(title: "Add a new item", icon: "plus") { showNewProduct = true }
        }
    }

    private var insights: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Where sales come from", subtitle: "Compare completed app orders to manually entered website totals")
            RoundedPanel {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Text("App (local demo)").font(.subheadline)
                        Spacer()
                        Text(store.appSales.asMoney).font(.subheadline.bold())
                    }
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 3).fill(TL.ink)
                            .frame(width: barWidth(store.appSales, totalWidth: proxy.size.width), height: 8)
                    }.frame(height: 8).background(TL.soft, in: Capsule())
                    HStack {
                        Text("Website (manual entry)").font(.subheadline)
                        Spacer()
                        Text(store.websiteSales.asMoney).font(.subheadline.bold())
                    }
                    GeometryReader { proxy in
                        RoundedRectangle(cornerRadius: 3).fill(TL.muted)
                            .frame(width: barWidth(store.websiteSales, totalWidth: proxy.size.width), height: 8)
                    }.frame(height: 8).background(TL.soft, in: Capsule())
                }
            }
            RoundedPanel {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Important about these numbers").font(.headline)
                    Text("App totals are only completed test orders on this phone. Website sales are typed in manually below, not read from Tiger Lillies' checkout. This view cannot report real business performance until a secure integration is built.")
                        .font(.subheadline).foregroundStyle(TL.muted)
                }
            }
            HStack {
                SectionHeading(title: "Website entries")
                Button { showWebsiteEntry = true } label: { Image(systemName: "plus.circle.fill").font(.title2) }
            }
            if store.db.websiteSales.isEmpty {
                RoundedPanel { Text("No website sales have been entered. Tap + to log a sample amount for comparison.").font(.subheadline).foregroundStyle(TL.muted) }
            }
            ForEach(store.db.websiteSales) { entry in
                RoundedPanel {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.amount.asMoney).font(.headline)
                            Text("\(entry.date.formatted(date: .abbreviated, time: .omitted)) · \(entry.note)")
                                .font(.caption).foregroundStyle(TL.muted)
                        }
                        Spacer()
                        Button { store.deleteWebsiteSale(entry.id) } label: { Image(systemName: "trash") }
                            .accessibilityLabel("Delete entry")
                    }
                }
            }
            SectionHeading(title: "Customer feedback")
            if store.db.reviews.isEmpty {
                RoundedPanel { Text("After completing an order, customers can leave a rating from Order history. Feedback will appear here.").font(.subheadline).foregroundStyle(TL.muted) }
            }
            ForEach(store.db.reviews) { entry in
                RoundedPanel {
                    Label("\(entry.rating) / 5 stars", systemImage: "star.fill").font(.headline)
                    if !entry.comment.isEmpty { Text(entry.comment).font(.subheadline) }
                    Text(entry.date.shortDate).font(.caption).foregroundStyle(TL.muted)
                }
            }
        }
    }

    private func barWidth(_ value: Double, totalWidth: CGFloat) -> CGFloat {
        let largest = max(store.appSales, store.websiteSales)
        guard largest > 0 else { return 0 }
        return totalWidth * CGFloat(max(0, value) / largest)
    }
}

struct AddProductView: View {
    @EnvironmentObject private var store: TigerStore
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var details = ""
    @State private var priceString = ""
    @State private var category: ProductCategory = .flowers
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic information") {
                    TextField("Item name", text: $title)
                    TextField("Short description", text: $details, axis: .vertical).lineLimit(2...5)
                    Picker("Category", selection: $category) {
                        ForEach(ProductCategory.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                Section("Pricing") {
                    HStack { Text("$"); TextField("0.00", text: $priceString).keyboardType(.decimalPad) }
                    Text("An item is available immediately in the local customer demo after saving.")
                        .font(.caption).foregroundStyle(TL.muted)
                }
            }
            .navigationTitle("Add new item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.addProduct(title: title, price: Double(priceString) ?? -1, category: category, details: details); dismiss() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(priceString) ?? -1) < 0)
                }
            }
        }
    }
}

struct EditProductView: View {
    @EnvironmentObject private var store: TigerStore
    @Environment(\.dismiss) private var dismiss
    @State private var working: CatalogProduct
    @State private var priceString: String
    init(product: CatalogProduct) {
        _working = State(initialValue: product)
        _priceString = State(initialValue: String(format: "%.2f", product.price))
    }
    var body: some View {
        NavigationStack {
            Form {
                TextField("Item name", text: $working.title)
                TextField("Description", text: $working.details, axis: .vertical)
                Picker("Category", selection: $working.category) {
                    ForEach(ProductCategory.allCases) { Text($0.rawValue).tag($0) }
                }
                HStack { Text("$"); TextField("Price", text: $priceString).keyboardType(.decimalPad) }
                Toggle("Available", isOn: $working.isAvailable)
                Toggle("Featured item", isOn: $working.isFeatured)
            }
            .navigationTitle("Edit item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        working.price = Double(priceString) ?? working.price
                        store.updateProduct(working)
                        dismiss()
                    }
                    .disabled(working.title.trimmingCharacters(in: .whitespaces).isEmpty || (Double(priceString) ?? -1) < 0)
                }
            }
        }
    }
}

struct ManualWebsiteSaleView: View {
    @EnvironmentObject private var store: TigerStore
    @Environment(\.dismiss) private var dismiss
    @State private var amountString = ""
    @State private var note = ""
    @State private var date = Date()
    var body: some View {
        NavigationStack {
            Form {
                Section("Website sales · manual example") {
                    HStack { Text("$"); TextField("0.00", text: $amountString).keyboardType(.decimalPad) }
                    DatePicker("Sale date", selection: $date, displayedComponents: .date)
                    TextField("Optional note", text: $note)
                }
                Section { Text("This does not import or verify any real website transactions. Enter sample totals only unless you have permission to use actual data.").font(.caption) }
            }
            .navigationTitle("Log website sale")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.addWebsiteSale(amount: Double(amountString) ?? 0, note: note, date: date); dismiss() }
                        .disabled((Double(amountString) ?? 0) <= 0)
                }
            }
        }
    }
}
