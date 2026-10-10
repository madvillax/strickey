import AppKit
import SwiftUI
import StrickeyCore

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    private let accent = Color.primary
    private let panelShape = RoundedRectangle(cornerRadius: 22, style: .continuous)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            statusCard
            profiles
            volumeControls
            Divider().opacity(0.5)
            VStack(spacing: 9) {
                Label("Recorded press + release", systemImage: "waveform")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                settingToggle("Skip ⌘ and ⌃ shortcuts", isOn: $model.ignoreShortcuts)
                settingToggle("Launch at login", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { isEnabled in model.setLaunchAtLogin(isEnabled) }
                ))
                if model.loginNeedsApproval {
                    Button("Approve in Login Items…", action: model.openLoginSettings)
                        .font(.system(size: 11))
                }
            }
            if let error = model.errorMessage {
                HStack(alignment: .top) {
                    Text(error).font(.system(size: 11)).foregroundStyle(.red)
                    Spacer(minLength: 4)
                    Button { model.errorMessage = nil } label: { Image(systemName: "xmark") }
                        .buttonStyle(.plain).accessibilityLabel("Dismiss error")
                }
            }
            HStack {
                Label("Only sound. Nothing saved.", systemImage: "lock")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
                Spacer()
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 11)).buttonStyle(.plain).foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(width: 320)
        .environment(\.colorScheme, .dark)
        .tint(accent)
        .accentColor(accent)
        .modifier(PanelSurface(shape: panelShape))
        .onAppear { model.refresh() }
    }

    private var header: some View {
        HStack(spacing: 9) {
            Image(nsImage: appIcon)
                .resizable().interpolation(.high).scaledToFit()
                .frame(width: 36, height: 36)
                .accessibilityLabel("strickey keycap")
            VStack(alignment: .leading, spacing: 2) {
                Text("strickey").font(.system(size: 19, weight: .semibold))
                Text("Make every key feel good.").font(.system(size: 10)).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Toggle("Enable keyboard sounds", isOn: $model.enabled)
                .labelsHidden().toggleStyle(MonochromeSwitchStyle())
                .help(model.enabled ? "Pause keyboard sounds" : "Enable keyboard sounds")
        }
    }

    private var appIcon: NSImage {
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else {
            return NSApplication.shared.applicationIconImage
        }
        return icon
    }

    private var profiles: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("SWITCH PROFILE").font(.system(size: 9, weight: .semibold))
                .tracking(1.2).foregroundStyle(.secondary)
            HStack(spacing: 5) {
                ForEach(SwitchProfile.allCases) { profile in
                    let selected = model.profile == profile
                    Button { model.profile = profile } label: {
                        VStack(spacing: 5) {
                            Image(systemName: profile.symbol).font(.system(size: 15))
                            Text(profile.name).font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(selected ? accent : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(selected ? accent.opacity(0.09) : Color.primary.opacity(0.015),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(selected ? accent.opacity(0.24) : .clear, lineWidth: 1))
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(profile.name): \(profile.subtitle)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .help(profile.subtitle)
                }
            }
            Text(model.profile.subtitle).font(.system(size: 10)).foregroundStyle(.secondary)
        }
    }

    private var volumeControls: some View {
        VStack(spacing: 7) {
            HStack {
                Text("Keyboard volume").font(.system(size: 12, weight: .medium))
                Spacer()
                Text("\(Int((model.volume * 100).rounded()))%")
                    .font(.system(size: 11, design: .monospaced)).monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: model.volume == 0 ? "speaker.slash.fill" : "speaker.fill")
                    .font(.system(size: 11)).foregroundStyle(.secondary).frame(width: 15)
                Slider(value: $model.volume, in: 0...1).tint(accent).controlSize(.small)
                    .accessibilityLabel("Keyboard sound volume")
                    .accessibilityValue("\(Int((model.volume * 100).rounded())) percent")
                    .help("Adjust Strickey independently. Your Mac volume also applies.")
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Label(model.outputDeviceName, systemImage: "hifispeaker")
                    .font(.system(size: 10)).foregroundStyle(.secondary).lineLimit(1)
                    .help("Follows your Mac’s default sound output and system volume")
                Spacer(minLength: 0)
                Button(action: model.preview) {
                    Label(model.previewing ? "Playing…" : "Preview", systemImage: "play.fill")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(model.previewing)
                .help("Play five sample keystrokes at the selected volume")
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Circle().fill(model.status == .listening ? accent : Color.secondary)
                    .frame(width: 5, height: 5)
                Text(model.status.title).font(.system(size: 10, weight: .medium))
                Spacer(minLength: 0)
                if model.typingDetected {
                    Image(systemName: "checkmark").font(.system(size: 9, weight: .semibold)).foregroundStyle(accent)
                        .accessibilityLabel("Typing detected")
                }
            }
            if !model.permissionGranted {
                Text("Enable Strickey in Privacy & Security → Input Monitoring to hear your typing.")
                    .font(.system(size: 11)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Allow Input Monitoring…", action: model.requestPermission)
                    .buttonStyle(.borderedProminent).tint(accent).controlSize(.small)
                Text("Already enabled? Quit and reopen. After a rebuild, you may need to add the current app again.")
                    .font(.system(size: 10)).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Button("Open Input Monitoring…", action: model.openInputSettings).controlSize(.small)
            } else if model.status == .secureInput {
                Text("Sounds resume when Secure Input ends.")
                    .font(.system(size: 10)).foregroundStyle(.secondary)
            } else if model.status == .unavailable {
                Button("Open Input Monitoring…", action: model.openInputSettings).controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(9)
        .background(accent.opacity(0.025), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func settingToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(.system(size: 11))
            Spacer()
            Toggle(title, isOn: isOn).labelsHidden()
                .toggleStyle(MonochromeSwitchStyle())
                .accessibilityLabel(title)
        }
    }
}

private struct PanelSurface: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: RoundedRectangle

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(nsColor: .windowBackgroundColor), in: shape)
                .clipShape(shape)
        } else if #available(macOS 26.0, *) {
            content.glassEffect(.regular.tint(.black.opacity(0.18)), in: shape)
        } else {
            content.background { PanelMaterial().clipShape(shape) }
                .overlay(shape.strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
                .clipShape(shape)
        }
    }
}

/// Native macOS switch controls use green regardless of tint; draw a neutral switch instead.
private struct MonochromeSwitchStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Capsule()
                .fill(Color.primary.opacity(configuration.isOn ? 0.35 : 0.09))
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5))
                .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                    Circle().fill(.white)
                        .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
                        .frame(width: 14, height: 14).padding(2)
                }
                .frame(width: 30, height: 18)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.switch)
        }
    }
}

/// Native backdrop blur lets the panel pick up the desktop behind it.
private struct PanelMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
