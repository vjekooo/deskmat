import SwiftUI
import AppKit

struct SpinningArc: View {
    @State private var rotate = false

    var body: some View {
        Circle()
            .trim(from: 0.2, to: 1)
            .stroke(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 40, height: 40)
            .rotationEffect(.degrees(rotate ? 360 : 0))
            .animation(
                .linear(duration: 1).repeatForever(autoreverses: false),
                value: rotate
            )
            .onAppear { rotate = true }
    }
}

struct InstantTooltip: ViewModifier {
    let text: String
    @State private var isHovering = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovering = $0 }
            .background(
                Group {
                    if isHovering {
                        Text(text)
                            .font(.caption)
                            .fixedSize()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 6))
                            .offset(y: -36)
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                },
                alignment: .top
            )
            .animation(.easeInOut(duration: 0.1), value: isHovering)
    }
}

extension View {
    func instantTooltip(_ text: String) -> some View {
        modifier(InstantTooltip(text: text))
    }
}

struct ContentView: View {

    @StateObject private var vm = WallpaperViewModel()

    init(previewWallpaper: WallpaperResult? = nil) {
        _vm = StateObject(wrappedValue: WallpaperViewModel(previewWallpaper: previewWallpaper))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            if let wallpaper = vm.current {

                AsyncImage(url: URL(string: wallpaper.path)) { phase in
                    switch phase {
                    case .empty:
                        Text("")

                    case .success(let image):
                        GeometryReader { geo in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        }

                    case .failure:
                        VStack {
                            Image(systemName: "photo")
                            Text("Failed to load image")
                        }

                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Text("Type in a query and hit Enter or press Refresh")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            if vm.isLoading {
                VStack {
                    Spacer()
                    SpinningArc()
                    Spacer()
                }
            }
            
            VStack {
                HStack {
                    Menu(vm.imageSource == .wallhaven ? "Wallhaven" : "Unsplash") {
                        Button("Wallhaven") { vm.imageSource = .wallhaven }
                        Button("Unsplash") { vm.imageSource = .unsplash }
                    }
                    .menuStyle(.borderlessButton)
                    .padding(8)
                    .buttonStyle(.plain)
                    .focusable(false)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    Spacer()

                    Button(action: vm.openInBrowser) {
                        Image(systemName: "safari")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    .help("Open image in browser")
                    .disabled(vm.current == nil)
                }
                .padding(12)
                .padding(.horizontal)
                .padding(.top, 20)

                Spacer()
            }
            
            if vm.imageSource == .unsplash {
                Link(destination: URL(string: vm.current?.userLink ?? "https://unsplash.com")!) {
                    Text("Photo by " + (vm.current?.user ?? "Unknown"))
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .buttonStyle(.plain)
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
        
            HStack {
                if vm.imageSource == .wallhaven {
                    TextField("Search example: 'night sky'", text: $vm.query)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { vm.fetch() }
                        .opacity(vm.showSearch ? 1 : 0)
                        .disabled(!vm.showSearch)
                        .frame(width: vm.showSearch ? nil : 0)
                    
                    Button {
                        vm.toggleSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .focusable(false)
                    .help("Toggle search bar")
                }
                
                Button {
                    vm.fetch()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Fetch new image")
                .disabled(vm.isLoading)
                .focusable(false)

                Button {
                    vm.setAsWallpaper()
                } label: {
                    Image(systemName: "desktopcomputer")
                }
                .help("Set image as wallpaper")
                .disabled(vm.current == nil)
                .focusable(false)
            }
            .padding(12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding()
            .frame(maxWidth: .infinity, alignment: .trailing)
            .animation(.easeInOut(duration: 0.2), value: vm.showSearch)
            
            if vm.errorMessage != nil {
                VStack {
                    Spacer()

                    Text(vm.errorMessage ?? "")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: vm.errorMessage)
            }
        }
        .onAppear {
            vm.onAppear()
        }
        .onChange(of: vm.imageSource) { _ in
            vm.fetch()
        }
    }
}
