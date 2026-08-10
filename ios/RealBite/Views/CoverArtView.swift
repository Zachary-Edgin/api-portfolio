import SwiftUI

/// Generated cover art for a restaurant.
///
/// MapKit doesn't provide photos, so rather than invent imagery RealBite paints a
/// tasteful, deterministic gradient (chosen from the restaurant's name) and layers
/// the category glyph over it. Every screen shows the same art for a given place.
enum CoverArt {
    static let palettes: [[Color]] = [
        [Color(hex: 0xFF7E5F), Color(hex: 0xFEB47B)], // coral → peach
        [Color(hex: 0xF7971E), Color(hex: 0xFFD200)], // mango
        [Color(hex: 0xE96443), Color(hex: 0x904E95)], // sunset
        [Color(hex: 0x11998E), Color(hex: 0x38EF7D)], // herb
        [Color(hex: 0x2193B0), Color(hex: 0x6DD5ED)], // cool blue
        [Color(hex: 0xCB356B), Color(hex: 0xBD3F32)], // berry
        [Color(hex: 0x614385), Color(hex: 0x516395)], // plum
        [Color(hex: 0xEB3349), Color(hex: 0xF45C43)]  // chili
    ]

    static func colors(seed: Int) -> [Color] {
        palettes[abs(seed) % palettes.count]
    }

    static func gradient(seed: Int) -> LinearGradient {
        LinearGradient(colors: colors(seed), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct CoverArtView: View {
    let restaurant: Restaurant
    var glyphSize: CGFloat = 44

    var body: some View {
        ZStack {
            CoverArt.gradient(seed: restaurant.coverSeed)

            // Soft radial highlight for a little depth.
            RadialGradient(
                colors: [Color.white.opacity(0.28), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 180
            )

            Image(systemName: restaurant.glyphSymbol)
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        }
    }
}

#Preview {
    CoverArtView(restaurant: Restaurant.previewList[0])
        .frame(width: 200, height: 130)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding()
}
