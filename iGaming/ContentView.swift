import SwiftUI
import GameController
import Combine

enum AppPage: String, CaseIterable, Identifiable {
    case games = "Juego", library = "Biblioteca", accounts = "Cuentas", settings = "Configuración"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .games: "gamecontroller.fill"
        case .library: "square.grid.2x2.fill"
        case .accounts: "person.crop.circle.fill"
        case .settings: "gearshape.fill"
        }
    }
}
enum PadAction { case left, right, up, down, select, back }

@MainActor final class PadInput: ObservableObject {
    @Published var connected = false
    let action = PassthroughSubject<PadAction, Never>()
    private var observers: [NSObjectProtocol] = []
    init() {
        observers.append(NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] n in
            guard let c = n.object as? GCController else { return }
            self?.bind(c); self?.connected = true
        })
        observers.append(NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in
            self?.connected = !GCController.controllers().isEmpty
        })
        GCController.controllers().forEach(bind)
        connected = !GCController.controllers().isEmpty
    }
    private func bind(_ c: GCController) {
        guard let p = c.extendedGamepad else { return }
        p.dpad.left.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.left) } }
        p.dpad.right.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.right) } }
        p.dpad.up.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.up) } }
        p.dpad.down.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.down) } }
        p.buttonA.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.select) } }
        p.buttonB.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.back) } }
        p.leftShoulder.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.left) } }
        p.rightShoulder.pressedChangedHandler = { [weak self] _,_,v in if v { self?.action.send(.right) } }
    }
    deinit { observers.forEach { NotificationCenter.default.removeObserver($0) } }
}

struct CloudService: Identifiable {
    let id: String; let name: String; let detail: String; let icon: String; let url: String
}

struct ContentView: View {
    @StateObject private var pad = PadInput()
    @Environment(\.openURL) private var openURL
    @State private var page: AppPage = .games
    @State private var focus = 0
    @State private var query = ""
    @State private var sync = true
    @State private var notifications = false
    @State private var qualityIndex = 0
    @State private var message: String?
    private let services = [
        CloudService(id:"xbox",name:"Xbox Cloud Gaming",detail:"Jugá títulos de Game Pass en streaming.",icon:"xbox.logo",url:"https://www.xbox.com/play"),
        CloudService(id:"geforce",name:"NVIDIA GeForce NOW",detail:"Transmití juegos compatibles desde la nube.",icon:"bolt.fill",url:"https://play.geforcenow.com/"),
        CloudService(id:"boosteroid",name:"Boosteroid",detail:"Accedé a juegos en streaming.",icon:"b.circle.fill",url:"https://www.boosteroid.com/"),
        CloudService(id:"luna",name:"Amazon Luna",detail:"Descubrí juegos disponibles en la nube.",icon:"a.circle.fill",url:"https://luna.amazon.com/")]

    var body: some View {
        ZStack {
            Color.ink.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 19) {
                        switch page {
                        case .games: home
                        case .library: library
                        case .accounts: accounts
                        case .settings: settings
                        }
                    }.padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 22)
                }
                tabs
            }
            if let message {
                VStack { Spacer(); Text(message).font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.ink).padding(13).background(Color.accent, in: Capsule()).padding(.bottom, 78) }
                    .allowsHitTesting(false)
            }
        }.preferredColorScheme(.dark).onReceive(pad.action, perform: handle)
    }

    private var topBar: some View {
        HStack {
            Label("iGaming", systemImage: "diamond.fill").font(.system(size: 13, weight: .bold, design: .rounded)).tracking(2).foregroundStyle(.white)
            Spacer()
            Label(pad.connected ? "Mando conectado" : "Cloud gaming", systemImage: "circle.fill")
                .font(.system(size: 9, weight: .medium)).foregroundStyle(pad.connected ? Color.accent : Color.muted)
            Image(systemName: "person.crop.circle.fill").font(.system(size: 20)).foregroundStyle(Color.accent).padding(.leading, 8)
        }.padding(.horizontal, 19).padding(.vertical, 13)
    }

    private var home: some View {
        VStack(alignment: .leading, spacing: 17) {
            title("TU HUB DE CLOUD GAMING", "Tu próxima partida.")
            VStack(alignment: .leading, spacing: 13) {
                Image(systemName: "gamecontroller.fill").font(.system(size: 65)).foregroundStyle(Color.accent.opacity(0.55)).frame(maxWidth: .infinity, alignment: .trailing).frame(height: 58)
                Text("TU CONSOLA EN LA NUBE").font(.system(size: 9, weight: .bold)).tracking(1.6).foregroundStyle(Color.accent)
                Text("Tus juegos.\nUna sola pantalla.").font(.system(size: 29, weight: .bold, design: .rounded)).tracking(-0.7).foregroundStyle(.white)
                Text("Conectá un servicio de cloud gaming para empezar a descubrir juegos.").font(.system(size: 12)).foregroundStyle(Color.muted)
                Button { page = .accounts; focus = 0 } label: {
                    Label("Conectar servicio", systemImage: "plus").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.ink).padding(.horizontal, 15).padding(.vertical, 11).background(Color.accent, in: Capsule())
                }.buttonStyle(.plain)
            }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color.card2, Color.card, Color.ink], startPoint: .topTrailing, endPoint: .bottomLeading), in: RoundedRectangle(cornerRadius: 21))
                .overlay(RoundedRectangle(cornerRadius: 21).stroke(Color.line, lineWidth: 1))
            emptyMessage("Tu biblioteca empieza acá", "Al conectar tus cuentas, los juegos disponibles aparecen automáticamente.", icon: "square.grid.2x2")
            controllerHint
        }
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 17) {
            title("TU COLECCIÓN", "Biblioteca")
            HStack { Image(systemName: "magnifyingglass").foregroundStyle(Color.muted); TextField("Buscar juegos...", text: $query).font(.system(size: 13)).autocorrectionDisabled() }
                .padding(13).background(Color.card, in: RoundedRectangle(cornerRadius: 12)).overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.line, lineWidth: 1))
            emptyMessage(query.isEmpty ? "Biblioteca vacía" : "No hay resultados", "Conectá un servicio de cloud gaming para descubrir su catálogo.", icon: "gamecontroller")
            Button { page = .accounts; focus = 0 } label: { Text("Ver servicios disponibles").font(.system(size: 12, weight: .bold)).foregroundStyle(Color.ink).padding(.horizontal, 15).padding(.vertical, 11).background(Color.accent, in: Capsule()) }.buttonStyle(.plain)
            controllerHint
        }
    }

    private var accounts: some View {
        VStack(alignment: .leading, spacing: 13) {
            title("SERVICIOS DE CLOUD GAMING", "Cuentas")
            Text("Conectá tus cuentas para reunir tus juegos disponibles en la nube.").font(.system(size: 12)).foregroundStyle(Color.muted)
            ForEach(services.indices, id: \.self) { index in
                let service = services[index]
                Button {
                    focus = index
                    if let url = URL(string: service.url) { openURL(url) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: service.icon).font(.system(size: 19, weight: .semibold)).foregroundStyle(Color.accent).frame(width: 43, height: 43).background(Color.card2, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 4) { Text(service.name).font(.system(size: 12, weight: .semibold)).foregroundStyle(.white); Text(service.detail).font(.system(size: 10)).foregroundStyle(Color.muted) }
                        Spacer(minLength: 3); Image(systemName: "plus.circle.fill").foregroundStyle(Color.accent)
                    }.padding(12).background(Color.card, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(focus == index ? Color.accent : Color.line, lineWidth: focus == index ? 1.5 : 1))
                }.buttonStyle(.plain)
            }
            Text("Sin tiendas de PC ni juegos precargados.").font(.system(size: 10)).foregroundStyle(Color.muted).padding(.top, 2)
            controllerHint
        }
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 17) {
            title("PREFERENCIAS", "Configuración")
            VStack(spacing: 0) {
                ToggleRow(title: "Sincronización automática", detail: "Actualizar la biblioteca al abrir la app.", value: $sync, focused: focus == 0)
                Divider().overlay(Color.line)
                ToggleRow(title: "Notificaciones", detail: "Novedades de tus servicios conectados.", value: $notifications, focused: focus == 1)
                Divider().overlay(Color.line)
                HStack { Text("Calidad de streaming").font(.system(size: 12, weight: .semibold)); Spacer(); Menu { Button("Automática") { qualityIndex = 0 }; Button("1080p · Alta") { qualityIndex = 1 }; Button("720p · Equilibrada") { qualityIndex = 2 } } label: { Label(["Automática", "1080p · Alta", "720p · Equilibrada"][qualityIndex], systemImage: "chevron.down").font(.system(size: 10)).foregroundStyle(.white).padding(9).background(Color.card2, in: Capsule()) } }.padding(14)
            }.background(Color.card, in: RoundedRectangle(cornerRadius: 15)).overlay(RoundedRectangle(cornerRadius: 15).stroke(Color.line, lineWidth: 1))
            controllerHint
        }
    }

    private var tabs: some View {
        HStack(spacing: 3) {
            ForEach(AppPage.allCases) { item in
                let index = AppPage.allCases.firstIndex(of: item) ?? 0
                Button { page = item; focus = index } label: {
                    VStack(spacing: 5) { Image(systemName: item.icon).font(.system(size: 16, weight: .semibold)); Text(item.rawValue).font(.system(size: 9, weight: .semibold)) }
                        .foregroundStyle(page == item ? Color.accent : Color.muted).frame(maxWidth: .infinity).frame(height: 49)
                        .background(focus == index ? Color.accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
                }.buttonStyle(.plain)
            }
        }.padding(.horizontal, 8).padding(.top, 5).background(.ultraThinMaterial).overlay(alignment: .top) { Rectangle().fill(Color.line).frame(height: 0.5) }
    }

    private var controllerHint: some View {
        HStack(spacing: 8) { Image(systemName: "gamecontroller.fill").foregroundStyle(Color.accent); Text(pad.connected ? "← → secciones · ↑ ↓ elegir · A aceptar · B volver" : "Compatible con mando Bluetooth").font(.system(size: 9, weight: .medium)).foregroundStyle(Color.muted) }.padding(.top, 3)
    }

    private func title(_ overline: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(overline).font(.system(size: 9, weight: .bold)).tracking(1.6).foregroundStyle(Color.accent)
            Text(value).font(.system(size: 27, weight: .bold, design: .rounded)).tracking(-0.5).foregroundStyle(.white)
        }
    }

    private func emptyMessage(_ heading: String, _ detail: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 29)).foregroundStyle(Color.accent.opacity(0.8))
            Text(heading).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundStyle(.white)
            Text(detail).font(.system(size: 11)).foregroundStyle(Color.muted).multilineTextAlignment(.center).frame(maxWidth: 280)
        }.frame(maxWidth: .infinity).padding(.vertical, 35).background(Color.card.opacity(0.6), in: RoundedRectangle(cornerRadius: 16)).overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.line, style: StrokeStyle(lineWidth: 1, dash: [5,5])))
    }

    private func handle(_ action: PadAction) {
        switch action {
        case .left:
            page = AppPage.allCases[(AppPage.allCases.firstIndex(of: page)! + 3) % 4]; focus = page == .accounts ? services.count - 1 : 0
        case .right:
            page = AppPage.allCases[(AppPage.allCases.firstIndex(of: page)! + 1) % 4]; focus = 0
        case .up: if page == .accounts || page == .settings { focus = max(0, focus - 1) }
        case .down: if page == .accounts { focus = min(services.count - 1, focus + 1) } else if page == .settings { focus = min(2, focus + 1) }
        case .select:
            if page == .accounts { let service = services[focus]; if let url = URL(string: service.url) { openURL(url) } }
            else if page == .settings { if focus == 0 { sync.toggle() } else if focus == 1 { notifications.toggle() } else { qualityIndex = (qualityIndex + 1) % 3 } }
            else if page == .games || page == .library { page = .accounts; focus = 0 }
        case .back: page = .games; focus = 0
        }
    }

    private func notify(_ value: String) {
        message = value
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { if message == value { message = nil } }
    }
}

private struct ToggleRow: View {
    let title: String; let detail: String; let focused: Bool; @Binding var value: Bool
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 12, weight: .semibold)); Text(detail).font(.system(size: 10)).foregroundStyle(Color.muted) }
            Spacer(); Toggle(title, isOn: $value).labelsHidden().tint(Color.accent)
        }.padding(14).background(focused ? Color.accent.opacity(0.08) : .clear, in: RoundedRectangle(cornerRadius: 12))
    }
}

private extension Color {
    static let ink = Color(red: 0.027, green: 0.035, blue: 0.055)
    static let card = Color(red: 0.065, green: 0.078, blue: 0.105)
    static let card2 = Color(red: 0.105, green: 0.13, blue: 0.18)
    static let line = Color(red: 0.15, green: 0.18, blue: 0.23)
    static let muted = Color(red: 0.55, green: 0.59, blue: 0.66)
    static let accent = Color(red: 0.56, green: 0.72, blue: 1.0)
}














