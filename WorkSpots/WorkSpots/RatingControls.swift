import SwiftUI

/// Read-only 5-star display that understands half stars (e.g. 4.5).
struct StarRatingDisplay: View {
    let rating: Double
    var size: CGFloat = 13

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: symbol(for: index))
                    .font(.system(size: size))
                    .foregroundStyle(.orange)
            }
        }
        .accessibilityLabel("Rated \(rating, specifier: "%.1f") out of 5")
    }

    private func symbol(for index: Int) -> String {
        let full = Double(index) + 1.0
        if rating >= full {
            return "star.fill"
        } else if rating >= full - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

/// Tappable rating input: each star is split into a left half (x.5) and a
/// right half (x.0), so the whole 0.5–5 range is reachable by tapping.
struct HalfStarRatingPicker: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                starButton(index: index)
            }
            Text(String(format: "%.1f", rating))
                .font(.headline)
                .monospacedDigit()
                .frame(minWidth: 34, alignment: .leading)
        }
    }

    private func starButton(index: Int) -> some View {
        let base = Double(index)
        return ZStack {
            Image(systemName: symbol(for: index))
                .font(.title2)
                .foregroundStyle(.orange)
            HStack(spacing: 0) {
                Button {
                    rating = base + 0.5
                } label: {
                    Color.clear
                        .frame(width: 15, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(base + 0.5, specifier: "%.1f") stars")

                Button {
                    rating = base + 1.0
                } label: {
                    Color.clear
                        .frame(width: 15, height: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(base + 1.0, specifier: "%.1f") stars")
            }
        }
        .frame(width: 32, height: 32)
    }

    private func symbol(for index: Int) -> String {
        let full = Double(index) + 1.0
        if rating >= full {
            return "star.fill"
        } else if rating >= full - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

/// One 1–5 row of the check-in scorecard.
struct ScorecardStepperRow: View {
    let title: String
    let systemImage: String
    @Binding var value: Int

    var body: some View {
        Stepper(value: $value, in: 1...5) {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer()
                Text("\(value)/5")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }
}

/// A small pill shown for place tags ("Light Food", "Boutique", "Stretch"…).
struct TagChip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}

extension Place {
    /// Human-readable tag labels for chips, in a stable order.
    var tagLabels: [String] {
        var labels: [String] = []
        if tags.contains("light food") { labels.append("Light Food") }
        if tags.contains("boutique") { labels.append("Boutique") }
        if isStretch { labels.append("Stretch") }
        return labels
    }
}
