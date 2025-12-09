import Foundation
import SwiftUI
import Combine

class AdvancedCodeGenerator: ObservableObject {
    static let shared = AdvancedCodeGenerator()
    
    private var achievementTracker: CodeGeneratorAchievementTracker?
    
    private init() {}
    
    // MARK: - Configuration
    
    func setAchievementTracker(_ tracker: CodeGeneratorAchievementTracker) {
        self.achievementTracker = tracker
    }
    
    /// Generates app with advanced presentation support
    func generateApp(
        from screens: [VisualScreen],
        branding: TemplateBranding,
        appName: String,
        bundleIdentifier: String,
        structure: AppStructureType,
        tabBarConfig: TabBarConfiguration?
    ) -> [String: String] {
        var files: [String: String] = [:]
        
        // Track advanced features
        switch structure {
        case .navigation:
            achievementTracker?.trackAdvancedFeature("navigation")
        case .tabBar, .tabBarWithNavigation:
            achievementTracker?.trackAdvancedFeature("tabBar")
        default:
            break
        }
        
        // Generate main app file based on structure
        files["main.swift"] = generateMainApp(
            appName: appName,
            structure: structure,
            screens: screens,
            tabBarConfig: tabBarConfig
        )
        
        // Generate each screen
        for screen in screens {
            let fileName = "\(screen.name).swift"
            files[fileName] = generateScreen(screen, branding: branding, allScreens: screens)
        }
        
        // Generate supporting files
        files["BrandingExtensions.swift"] = generateBrandingExtensions(branding)
        files["PresentationHelpers.swift"] = generatePresentationHelpers()
        
        // Generate tab bar view if needed
        if structure == .tabBar || structure == .tabBarWithNavigation, let config = tabBarConfig {
            files["TabBarView.swift"] = generateTabBarView(config: config, screens: screens)
        }
        
        return files
    }
    
    // MARK: - Main App Generation
    
    private func generateMainApp(
        appName: String,
        structure: AppStructureType,
        screens: [VisualScreen],
        tabBarConfig: TabBarConfiguration?
    ) -> String {
        let sanitizedName = appName.replacingOccurrences(of: " ", with: "")
        let initialScreen = screens.first { $0.isInitialScreen } ?? screens.first
        
        var rootView: String
        
        switch structure {
        case .singleScreen:
            rootView = "\(initialScreen?.name ?? "ContentView")()"
        case .navigation:
            rootView = """
            NavigationStack {
                \(initialScreen?.name ?? "ContentView")()
            }
            """
        case .tabBar, .tabBarWithNavigation:
            rootView = "TabBarView()"
        }
        
        return """
        import SwiftUI
        
        @main
        struct \(sanitizedName)App: App {
            @StateObject private var presentationState = PresentationStateManager()
            
            var body: some Scene {
                WindowGroup {
                    \(rootView)
                        .environmentObject(presentationState)
                }
            }
        }
        """
    }
    
    // MARK: - Tab Bar View Generation
    
    private func generateTabBarView(config: TabBarConfiguration, screens: [VisualScreen]) -> String {
        var code = """
        import SwiftUI
        
        struct TabBarView: View {
            @State private var selectedTab = 0
            
            var body: some View {
                TabView(selection: $selectedTab) {
        """
        
        for (index, tab) in config.tabs.enumerated() {
            if let screen = screens.first(where: { $0.id == tab.screenID }) {
                code += """
        
                    \(screen.name)()
                        .tabItem {
                            Label("\(tab.title)", systemImage: "\(tab.icon)")
                        }
                        .tag(\(index))
        """
                
                if let badge = tab.badge {
                    code += """
        
                        .badge("\(badge)")
        """
                }
            }
        }
        
        code += """
        
                }
        """
        
        if let accentColor = config.accentColor {
            code += """
        
                .tint(Color(hex: "\(accentColor)") ?? .accentColor)
        """
        }
        
        code += """
        
            }
        }
        
        #Preview {
            TabBarView()
        }
        """
        
        return code
    }
    
    // MARK: - Screen Generation with Presentations
    
    private func generateScreen(_ screen: VisualScreen, branding: TemplateBranding, allScreens: [VisualScreen]) -> String {
        let stateVariables = extractStateVariables(from: screen.components)
        let presentationStates = extractPresentationStates(from: screen.components, allScreens: allScreens)
        let bodyCode = generateBody(from: screen.components, indent: 2)
        let actionMethods = generateActionMethods(from: screen.components, allScreens: allScreens)
        let presentationModifiers = generatePresentationModifiers(from: screen.components, allScreens: allScreens)
        
        var code = """
        import SwiftUI
        
        struct \(screen.name): View {
            @EnvironmentObject var presentationState: PresentationStateManager
        """
        
        // Add state variables
        if !stateVariables.isEmpty {
            code += "\n"
            for variable in stateVariables {
                code += "    @State private var \(variable.name): \(variable.type) = \(variable.defaultValue)\n"
            }
        }
        
        // Add presentation states
        if !presentationStates.isEmpty {
            code += "\n"
            for state in presentationStates {
                code += "    @State private var \(state)\n"
            }
        }
        
        // Add body
        code += """
        
            var body: some View {
        """
        
        // Wrap in NavigationStack if screen has navigation title
        if let navTitle = screen.navigationTitle {
            code += """
        
                NavigationStack {
        \(bodyCode)
                    .navigationTitle("\(navTitle)")
                }
        """
        } else {
            code += "\n\(bodyCode)\n"
        }
        
        // Add background if specified
        if let bgColor = screen.backgroundColor {
            code += """
        
                .background(Color(hex: "\(bgColor)") ?? .clear)
        """
        }
        
        // Add presentation modifiers
        code += presentationModifiers
        
        code += """
        
            }
        """
        
        // Add action methods
        if !actionMethods.isEmpty {
            code += actionMethods
        }
        
        code += """
        
        }
        
        #Preview {
            \(screen.name)()
                .environmentObject(PresentationStateManager())
        }
        """
        
        return code
    }
    
    // MARK: - Presentation Modifiers
    
    private func generatePresentationModifiers(from components: [RenderableComponent], allScreens: [VisualScreen]) -> String {
        var modifiers = ""
        
        // Check for sheet presentations
        let sheetScreens = findPresentationScreens(in: components, type: .sheet, allScreens: allScreens)
        for screenID in sheetScreens {
            if let screen = allScreens.first(where: { $0.id == screenID }) {
                modifiers += """
        
                .sheet(isPresented: $showing\(screen.name)) {
                    \(screen.name)()
                }
        """
            }
        }
        
        // Check for full screen covers
        let fullScreenScreens = findPresentationScreens(in: components, type: .fullScreenCover, allScreens: allScreens)
        for screenID in fullScreenScreens {
            if let screen = allScreens.first(where: { $0.id == screenID }) {
                modifiers += """
        
                .fullScreenCover(isPresented: $showing\(screen.name)) {
                    \(screen.name)()
                }
        """
            }
        }
        
        // Check for alerts
        if hasAlerts(in: components) {
            modifiers += """
        
                .alert(alertTitle, isPresented: $showingAlert) {
                    ForEach(alertButtons, id: \\.self) { button in
                        Button(button.title, role: button.role) {
                            handleAlertAction(button.action)
                        }
                    }
                } message: {
                    Text(alertMessage)
                }
        """
        }
        
        // Check for confirmation dialogs (action sheets)
        if hasActionSheets(in: components) {
            modifiers += """
        
                .confirmationDialog(actionSheetTitle, isPresented: $showingActionSheet) {
                    ForEach(actionSheetButtons, id: \\.self) { button in
                        Button(button.title, role: button.role) {
                            handleActionSheetAction(button.action)
                        }
                    }
                } message: {
                    if let message = actionSheetMessage {
                        Text(message)
                    }
                }
        """
        }
        
        return modifiers
    }
    
    // MARK: - Helper Methods
    
    private func extractStateVariables(from components: [RenderableComponent]) -> [(name: String, type: String, defaultValue: String)] {
        // Reuse from EnhancedCodeGenerator
        return EnhancedCodeGenerator.shared.extractStateVariables(from: components)
    }
    
    private func extractPresentationStates(from components: [RenderableComponent], allScreens: [VisualScreen]) -> [String] {
        var states: [String] = []
        
        // Find all screens that can be presented
        let sheetScreens = findPresentationScreens(in: components, type: .sheet, allScreens: allScreens)
        for screenID in sheetScreens {
            if let screen = allScreens.first(where: { $0.id == screenID }) {
                states.append("showing\(screen.name) = false")
            }
        }
        
        let fullScreenScreens = findPresentationScreens(in: components, type: .fullScreenCover, allScreens: allScreens)
        for screenID in fullScreenScreens {
            if let screen = allScreens.first(where: { $0.id == screenID }) {
                states.append("showing\(screen.name) = false")
            }
        }
        
        if hasAlerts(in: components) {
            states.append("showingAlert = false")
            states.append("alertTitle = \"\"")
            states.append("alertMessage = \"\"")
            states.append("alertButtons: [AlertButtonConfig] = []")
        }
        
        if hasActionSheets(in: components) {
            states.append("showingActionSheet = false")
            states.append("actionSheetTitle = \"\"")
            states.append("actionSheetMessage: String? = nil")
            states.append("actionSheetButtons: [ActionButtonConfig] = []")
        }
        
        return states
    }
    
    private func findPresentationScreens(in components: [RenderableComponent], type: PresentationType, allScreens: [VisualScreen]) -> Set<UUID> {
        let screenIDs = Set<UUID>()
        
        func search(in components: [RenderableComponent]) {
            for component in components {
                // Check if button has presentation action
                // This is simplified - in real implementation, check button actions
                search(in: component.children)
            }
        }
        
        search(in: components)
        return screenIDs
    }
    
    private func hasAlerts(in components: [RenderableComponent]) -> Bool {
        // Check if any button shows an alert
        return false // Simplified
    }
    
    private func hasActionSheets(in components: [RenderableComponent]) -> Bool {
        // Check if any button shows an action sheet
        return false // Simplified
    }
    
    private func generateBody(from components: [RenderableComponent], indent: Int) -> String {
        return EnhancedCodeGenerator.shared.generateBody(from: components, indent: indent)
    }
    
    private func generateActionMethods(from components: [RenderableComponent], allScreens: [VisualScreen]) -> String {
        return EnhancedCodeGenerator.shared.generateActionMethods(from: components)
    }
    
    // MARK: - Supporting Code Generation
    
    private func generateBrandingExtensions(_ branding: TemplateBranding) -> String {
        return EnhancedCodeGenerator.shared.generateBrandingExtensions(branding)
    }
    
    private func generatePresentationHelpers() -> String {
        return """
        import SwiftUI
        
        // MARK: - Presentation State Manager
        
        class PresentationStateManager: ObservableObject {
            @Published var activeSheet: UUID?
            @Published var activeFullScreenCover: UUID?
            @Published var navigationPath: [UUID] = []
            
            func present(_ screenID: UUID, type: PresentationType) {
                switch type {
                case .navigation:
                    navigationPath.append(screenID)
                case .sheet:
                    activeSheet = screenID
                case .fullScreenCover:
                    activeFullScreenCover = screenID
                default:
                    break
                }
            }
            
            func dismiss() {
                if !navigationPath.isEmpty {
                    navigationPath.removeLast()
                }
                activeSheet = nil
                activeFullScreenCover = nil
            }
        }
        
        enum PresentationType {
            case navigation
            case sheet
            case fullScreenCover
            case alert
            case confirmationDialog
        }
        
        // MARK: - Alert & Action Sheet Helpers
        
        struct AlertButtonConfig: Hashable {
            let title: String
            let role: ButtonRole?
            let action: String
        }
        
        struct ActionButtonConfig: Hashable {
            let title: String
            let role: ButtonRole?
            let action: String
        }
        """
    }
}


