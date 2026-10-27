import SwiftUI

enum TL {
    static let bg = Color(red: 0.975, green: 0.973, blue: 0.965)
    static let ink = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let muted = Color(red: 0.48, green: 0.48, blue: 0.48)
    static let border = Color(red: 0.88, green: 0.88, blue: 0.86)
    static let soft = Color(red: 0.94, green: 0.94, blue: 0.92)
}

struct BrandMark: View {
    var small = false
    var body: some View {
        HStack(spacing: 10) {
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(width: small ? 46 : 58, height: small ? 46 : 58)
            VStack(alignment: .leading, spacing: 1) {
                Text("TIGER LILLIES").font(.system(size: small ? 15 : 17, weight: .heavy, design: .serif))
                Text("Floral & Coffee").font(.system(size: small ? 11 : 12, weight: .medium, design: .serif)).italic()
            }
            .foregroundStyle(TL.ink)
        }
        .accessibilityElement(children: .combine)
    }
}

struct SectionHeading: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.system(size: 24, weight: .semibold, design: .serif)).foregroundStyle(TL.ink)
            if let subtitle = subtitle { Text(subtitle).font(.footnote).foregroundStyle(TL.muted) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TinyTag: View {
    let text: String
    var dark = false
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .foregroundStyle(dark ? Color.white : TL.ink)
            .background(dark ? TL.ink : TL.soft, in: Capsule())
    }
}

struct RoundedPanel<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 21))
            .overlay(RoundedRectangle(cornerRadius: 21).stroke(TL.border, lineWidth: 0.6))
    }
}

struct SolidButton: View {
    let title: String
    var icon: String? = nil
    var disabled = false
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let icon = icon { Image(systemName: icon) }
                Text(title).fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.white)
        .background(disabled ? Color.gray : TL.ink, in: RoundedRectangle(cornerRadius: 14))
        .disabled(disabled)
    }
}

struct ProductGlyph: View {
    let product: CatalogProduct
    var height: CGFloat = 124
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18).fill(TL.soft)
            Circle().stroke(TL.border, lineWidth: 1).frame(width: height * 0.65, height: height * 0.65)
            Image(systemName: product.category.symbol)
                .font(.system(size: height * 0.35, weight: .ultraLight))
                .foregroundStyle(TL.ink)
        }
        .frame(height: height)
        .accessibilityLabel("\(product.category.rawValue) illustration")
    }
}

struct EmptyState: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 40, weight: .ultraLight)).foregroundStyle(TL.muted)
            Text(title).font(.system(size: 23, weight: .medium, design: .serif))
            Text(message).font(.subheadline).foregroundStyle(TL.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
    }
}

struct DemoFootnote: View {
    var body: some View {
        Label("Local test app · No real orders or payments", systemImage: "iphone")
            .font(.caption2)
            .foregroundStyle(TL.muted)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
    }
}
