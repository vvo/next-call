import AppKit
import SwiftUI

private struct LinkPointer: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { inside in
            (inside ? NSCursor.pointingHand : NSCursor.arrow).set()
        }
    }
}

extension View {
    func linkPointer() -> some View { modifier(LinkPointer()) }
}

struct NotificationView: View {
    let model: NotificationModel
    var onJoin: () -> Void
    var onRemindAtStart: () -> Void
    var onCopyLink: () -> Void
    var onDismiss: () -> Void

    @State private var hoveringJoin = false
    @State private var hoveringCard = false
    @State private var appeared = false
    @State private var progress: Double = 0

    private let dismissAfter: TimeInterval = 30
    private let ticker = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        card
            .overlay(alignment: .topLeading) { closeButton }
            .onHover { hoveringCard = $0 }
            .onReceive(ticker) { _ in
                guard !hoveringCard, progress < 1 else { return }
                progress += 0.05 / dismissAfter
                if progress >= 1 {
                    onDismiss()
                }
            }
            .offset(y: appeared ? 0 : -16)
            .onAppear {
                withAnimation(.easeOut(duration: 0.35)) { appeared = true }
            }
            .padding(44) // must fully contain the shadow blur or it clips into a hard rectangle
    }

    private var card: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(model.accentColor.opacity(0.8))
                .frame(width: 6, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(model.timeRange)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                if let people = model.participantsLine {
                    Text(people)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(minWidth: 130, maxWidth: 210, alignment: .leading)

            joinControl
        }
        .padding(.leading, 16)
        .padding(.trailing, 12)
        .padding(.vertical, 13)
        .background(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 5)
        )
        .overlay(alignment: .bottomLeading) { progressBar }
        .overlay(
            RoundedRectangle(cornerRadius: 19, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private var progressBar: some View {
        GeometryReader { geo in
            Rectangle()
                .fill(Color.primary.opacity(0.16))
                .frame(width: geo.size.width * min(progress, 1), height: 4)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
        .allowsHitTesting(false)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            ZStack {
                Circle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 1)
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 22, height: 22)
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .linkPointer()
        .offset(x: -7, y: -7)
        .opacity(hoveringCard ? 1 : 0)
        .animation(.easeOut(duration: 0.15), value: hoveringCard)
    }

    private var joinControl: some View {
        HStack(spacing: 0) {
            Button(action: onJoin) {
                HStack(spacing: 10) {
                    if let logo = model.link.provider.logo {
                        Image(nsImage: logo)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 26, height: 26)
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Join Call")
                            .font(.system(size: 13, weight: .bold))
                        Text(model.link.provider.displayName)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider()
                .frame(height: 32)

            Menu {
                if let start = model.startDate, start > Date() {
                    Button("Remind me at start time", action: onRemindAtStart)
                }
                Button("Copy call link", action: onCopyLink)
                Divider()
                Button("Dismiss", action: onDismiss)
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 44)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 28)
        }
        .fixedSize()
        .background(hoveringJoin ? Color.primary.opacity(0.06) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { hoveringJoin = $0 }
        .linkPointer()
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
