import Foundation
import SwiftUI


// MARK: - Screen Templates

struct ScreenTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let category: ScreenCategory
    let components: [RenderableComponent]
    
    enum ScreenCategory: String, CaseIterable {
        case basic = "Basic"
        case authentication = "Authentication"
        case forms = "Forms"
        case lists = "Lists"
        case settings = "Settings"
        case dashboard = "Dashboard"
        case profile = "Profile"
    }
}

class ScreenTemplateLibrary {
    static let shared = ScreenTemplateLibrary()
    
    private init() {}
    
    func getAllTemplates() -> [ScreenTemplate] {
        return [
            // Basic Templates
            blankScreen,
            welcomeScreen,
            detailScreen,
            
            // Authentication Templates
            biometricLoginScreen,
            signUpWithBiometricScreen,
            simpleLoginScreen,
            
            // Form Templates
            loginForm,
            signupForm,
            settingsForm,
            
            // List Templates
            simpleList,
            groupedList,
            
            // Dashboard Templates
            statsCard,
            
            // Profile Templates
            profileView,
            
            // Built-in App Templates (Task 16)
            financeDashboardTemplate,
            socialFeedTemplate,
            ecommerceStoreTemplate,
            taskManagerTemplate,
            settingsScreenTemplate,
            onboardingFlowTemplate,
            profileEditorTemplate,
            searchFilterTemplate,
            
            // Industry-Specific Templates (Task 17)
            healthcareDashboardTemplate,
            educationPortalTemplate,
            realEstateListingTemplate,
            foodDeliveryTemplate,
            fitnessTrackerTemplate,
            travelPlannerTemplate
        ]
    }
    
    func getTemplates(for category: ScreenTemplate.ScreenCategory) -> [ScreenTemplate] {
        getAllTemplates().filter { $0.category == category }
    }
    
    // MARK: - Basic Templates
    
    private var blankScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Blank Screen",
            description: "Empty screen to start from scratch",
            icon: "doc",
            category: .basic,
            components: []
        )
    }
    
    private var welcomeScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Welcome Screen",
            description: "Welcome message with title and subtitle",
            icon: "hand.wave",
            category: .basic,
            components: [
                .vstack(id: UUID(), spacing: 20, children: [
                    .spacer(id: UUID()),
                    .image(id: UUID(), systemName: "star.fill", size: 60, color: "#FFD700"),
                    .text(id: UUID(), content: "Welcome!", fontSize: 32, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "Get started with your new app", fontSize: 16, fontWeight: .regular, color: ""),
                    .spacer(id: UUID()),
                    .button(id: UUID(), title: "Get Started", action: .custom(actionName: "getStarted"), style: .borderedProminent)
                ])
            ]
        )
    }
    
    private var detailScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Detail Screen",
            description: "Content detail view with image and text",
            icon: "doc.text",
            category: .basic,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 16, children: [
                        .image(id: UUID(), systemName: "photo", size: 100, color: "#007AFF"),
                        .text(id: UUID(), content: "Detail Title", fontSize: 24, fontWeight: .bold, color: ""),
                        .divider(id: UUID()),
                        .text(id: UUID(), content: "This is the detail content. Add your description here.", fontSize: 14, fontWeight: .regular, color: "")
                    ])
                ])
            ]
        )
    }
    
    // MARK: - Form Templates
    
    private var loginForm: ScreenTemplate {
        ScreenTemplate(
            name: "Login Form",
            description: "Email and password login form",
            icon: "person.circle",
            category: .forms,
            components: [
                .vstack(id: UUID(), spacing: 20, children: [
                    .spacer(id: UUID()),
                    .text(id: UUID(), content: "Sign In", fontSize: 28, fontWeight: .bold, color: ""),
                    .vstack(id: UUID(), spacing: 12, children: [
                        .textField(id: UUID(), placeholder: "Email", binding: "email"),
                        .textField(id: UUID(), placeholder: "Password", binding: "password")
                    ]),
                    .button(id: UUID(), title: "Sign In", action: .custom(actionName: "signIn"), style: .borderedProminent),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    private var signupForm: ScreenTemplate {
        ScreenTemplate(
            name: "Sign Up Form",
            description: "Registration form with name, email, and password",
            icon: "person.badge.plus",
            category: .forms,
            components: [
                .vstack(id: UUID(), spacing: 20, children: [
                    .spacer(id: UUID()),
                    .text(id: UUID(), content: "Create Account", fontSize: 28, fontWeight: .bold, color: ""),
                    .vstack(id: UUID(), spacing: 12, children: [
                        .textField(id: UUID(), placeholder: "Full Name", binding: "name"),
                        .textField(id: UUID(), placeholder: "Email", binding: "email"),
                        .textField(id: UUID(), placeholder: "Password", binding: "password")
                    ]),
                    .button(id: UUID(), title: "Sign Up", action: .custom(actionName: "signUp"), style: .borderedProminent),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    private var settingsForm: ScreenTemplate {
        ScreenTemplate(
            name: "Settings Form",
            description: "Settings form with toggles and pickers",
            icon: "gearshape",
            category: .forms,
            components: [
                .form(id: UUID(), children: [
                    .section(id: UUID(), header: "Preferences", children: [
                        .toggle(id: UUID(), label: "Enable Notifications", binding: "notificationsEnabled"),
                        .toggle(id: UUID(), label: "Dark Mode", binding: "darkModeEnabled")
                    ]),
                    .section(id: UUID(), header: "Account", children: [
                        .button(id: UUID(), title: "Sign Out", action: .custom(actionName: "signOut"), style: .plain)
                    ])
                ])
            ]
        )
    }
    
    // MARK: - List Templates
    
    private var simpleList: ScreenTemplate {
        ScreenTemplate(
            name: "Simple List",
            description: "Basic list with text items",
            icon: "list.bullet",
            category: .lists,
            components: [
                .list(id: UUID(), children: [
                    .text(id: UUID(), content: "Item 1", fontSize: 16, fontWeight: .regular, color: ""),
                    .text(id: UUID(), content: "Item 2", fontSize: 16, fontWeight: .regular, color: ""),
                    .text(id: UUID(), content: "Item 3", fontSize: 16, fontWeight: .regular, color: "")
                ])
            ]
        )
    }
    
    private var groupedList: ScreenTemplate {
        ScreenTemplate(
            name: "Grouped List",
            description: "List with sections",
            icon: "list.bullet.indent",
            category: .lists,
            components: [
                .list(id: UUID(), children: [
                    .section(id: UUID(), header: "Section 1", children: [
                        .text(id: UUID(), content: "Item 1", fontSize: 16, fontWeight: .regular, color: ""),
                        .text(id: UUID(), content: "Item 2", fontSize: 16, fontWeight: .regular, color: "")
                    ]),
                    .section(id: UUID(), header: "Section 2", children: [
                        .text(id: UUID(), content: "Item 3", fontSize: 16, fontWeight: .regular, color: ""),
                        .text(id: UUID(), content: "Item 4", fontSize: 16, fontWeight: .regular, color: "")
                    ])
                ])
            ]
        )
    }
    
    // MARK: - Dashboard Templates
    
    private var statsCard: ScreenTemplate {
        ScreenTemplate(
            name: "Stats Dashboard",
            description: "Dashboard with stat cards",
            icon: "chart.bar",
            category: .dashboard,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 16, children: [
                        .text(id: UUID(), content: "Dashboard", fontSize: 28, fontWeight: .bold, color: ""),
                        .hstack(id: UUID(), spacing: 12, children: [
                            .rectangle(id: UUID(), width: 150, height: 100, color: "#007AFF", cornerRadius: 12),
                            .rectangle(id: UUID(), width: 150, height: 100, color: "#34C759", cornerRadius: 12)
                        ]),
                        .hstack(id: UUID(), spacing: 12, children: [
                            .rectangle(id: UUID(), width: 150, height: 100, color: "#FF9500", cornerRadius: 12),
                            .rectangle(id: UUID(), width: 150, height: 100, color: "#FF3B30", cornerRadius: 12)
                        ])
                    ])
                ])
            ]
        )
    }
    
    // MARK: - Profile Templates
    
    private var profileView: ScreenTemplate {
        ScreenTemplate(
            name: "Profile View",
            description: "User profile with avatar and info",
            icon: "person.crop.circle",
            category: .profile,
            components: [
                .vstack(id: UUID(), spacing: 20, children: [
                    .circle(id: UUID(), size: 100, color: "#007AFF"),
                    .text(id: UUID(), content: "John Doe", fontSize: 24, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "john@example.com", fontSize: 14, fontWeight: .regular, color: ""),
                    .divider(id: UUID()),
                    .button(id: UUID(), title: "Edit Profile", action: .custom(actionName: "editProfile"), style: .bordered),
                    .button(id: UUID(), title: "Settings", action: .custom(actionName: "openSettings"), style: .bordered)
                ])
            ]
        )
    }
    
    // MARK: - Authentication Templates
    
    private var biometricLoginScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Biometric Login",
            description: "Login screen with Face ID/Touch ID support",
            icon: "faceid",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 32, children: [
                    .spacer(id: UUID()),
                    // Logo/Icon
                    .vstack(id: UUID(), spacing: 12, children: [
                        .image(id: UUID(), systemName: "faceid", size: 60, color: "#007AFF"),
                        .text(id: UUID(), content: "Welcome Back", fontSize: 28, fontWeight: .bold, color: ""),
                        .text(id: UUID(), content: "Sign in to continue", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                    ]),
                    // Email Field
                    .vstack(id: UUID(), spacing: 16, children: [
                        .textField(id: UUID(), placeholder: "Email", binding: "email"),
                        .textField(id: UUID(), placeholder: "Password", binding: "password")
                    ]),
                    // Sign In Button
                    .button(id: UUID(), title: "Sign In", action: .custom(actionName: "signIn"), style: .borderedProminent),
                    // Biometric Button
                    .button(id: UUID(), title: "Sign in with Face ID", action: .custom(actionName: "authenticateWithBiometrics"), style: .bordered),
                    .spacer(id: UUID()),
                    // Sign Up Link
                    .text(id: UUID(), content: "Don't have an account? Sign Up", fontSize: 14, fontWeight: .regular, color: "#007AFF")
                ])
            ]
        )
    }
    
    private var signUpWithBiometricScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Sign Up with Biometric",
            description: "Registration screen with biometric enrollment",
            icon: "person.badge.plus",
            category: .authentication,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 24, children: [
                        // Header
                        .vstack(id: UUID(), spacing: 8, children: [
                            .image(id: UUID(), systemName: "person.crop.circle.badge.plus", size: 60, color: "#007AFF"),
                            .text(id: UUID(), content: "Create Account", fontSize: 28, fontWeight: .bold, color: ""),
                            .text(id: UUID(), content: "Sign up to get started", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                        ]),
                        // Form Fields
                        .vstack(id: UUID(), spacing: 16, children: [
                            .textField(id: UUID(), placeholder: "Full Name", binding: "fullName"),
                            .textField(id: UUID(), placeholder: "Email", binding: "email"),
                            .textField(id: UUID(), placeholder: "Password", binding: "password"),
                            .textField(id: UUID(), placeholder: "Confirm Password", binding: "confirmPassword")
                        ]),
                        // Biometric Toggle
                        .toggle(id: UUID(), label: "Enable Face ID", binding: "useBiometrics"),
                        // Sign Up Button
                        .button(id: UUID(), title: "Sign Up", action: .custom(actionName: "signUp"), style: .borderedProminent),
                        // Sign In Link
                        .text(id: UUID(), content: "Already have an account? Sign In", fontSize: 14, fontWeight: .regular, color: "#007AFF")
                    ])
                ])
            ]
        )
    }
    
    private var simpleLoginScreen: ScreenTemplate {
        ScreenTemplate(
            name: "Simple Login",
            description: "Clean and minimal login screen",
            icon: "lock.shield",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 24, children: [
                    .spacer(id: UUID()),
                    // Logo
                    .image(id: UUID(), systemName: "lock.shield.fill", size: 80, color: "#007AFF"),
                    // Title
                    .text(id: UUID(), content: "Sign In", fontSize: 32, fontWeight: .bold, color: ""),
                    // Form
                    .vstack(id: UUID(), spacing: 16, children: [
                        .textField(id: UUID(), placeholder: "Email", binding: "email"),
                        .textField(id: UUID(), placeholder: "Password", binding: "password"),
                        .toggle(id: UUID(), label: "Remember me", binding: "rememberMe")
                    ]),
                    // Buttons
                    .vstack(id: UUID(), spacing: 12, children: [
                        .button(id: UUID(), title: "Sign In", action: .custom(actionName: "signIn"), style: .borderedProminent),
                        .button(id: UUID(), title: "Forgot Password?", action: .custom(actionName: "forgotPassword"), style: .plain)
                    ]),
                    .spacer(id: UUID()),
                    // Footer
                    .text(id: UUID(), content: "New user? Create an account", fontSize: 14, fontWeight: .regular, color: "#007AFF")
                ])
            ]
        )
    }
    
    // MARK: - Built-in App Templates (Task 16)
    
    private var financeDashboardTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Finance Dashboard",
            description: "Financial dashboard with charts, metrics, and transactions",
            icon: "chart.line.uptrend.xyaxis",
            category: .dashboard,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Dashboard", fontSize: 28, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "Filter", action: .custom(actionName: "showFilter"), style: .bordered)
                        ]),
                        
                        // Balance Card
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Total Balance", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                            .text(id: UUID(), content: "$24,582.50", fontSize: 36, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 8, children: [
                                .image(id: UUID(), systemName: "arrow.up.right", size: 14, color: "#34C759"),
                                .text(id: UUID(), content: "+12.5% this month", fontSize: 14, fontWeight: .regular, color: "#34C759")
                            ])
                        ]),
                        
                        // Metrics Grid
                        .hstack(id: UUID(), spacing: 12, children: [
                            .vstack(id: UUID(), spacing: 8, children: [
                                .rectangle(id: UUID(), width: 160, height: 100, color: "#007AFF", cornerRadius: 12),
                                .text(id: UUID(), content: "Income", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                .text(id: UUID(), content: "$8,420", fontSize: 20, fontWeight: .bold, color: "")
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .rectangle(id: UUID(), width: 160, height: 100, color: "#FF3B30", cornerRadius: 12),
                                .text(id: UUID(), content: "Expenses", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                .text(id: UUID(), content: "$3,280", fontSize: 20, fontWeight: .bold, color: "")
                            ])
                        ]),
                        
                        // Recent Transactions
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Recent Transactions", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 40, color: "#34C759"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Salary Deposit", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Today, 9:30 AM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .text(id: UUID(), content: "+$5,200", fontSize: 16, fontWeight: .bold, color: "#34C759")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 40, color: "#FF9500"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Grocery Store", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Yesterday, 3:15 PM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .text(id: UUID(), content: "-$142.50", fontSize: 16, fontWeight: .bold, color: "#FF3B30")
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }
    
    private var socialFeedTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Social Feed",
            description: "Social media feed with profile, posts, comments, and likes",
            icon: "person.2.fill",
            category: .profile,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 16, children: [
                        // Profile Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .circle(id: UUID(), size: 50, color: "#007AFF"),
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "John Doe", fontSize: 18, fontWeight: .bold, color: ""),
                                .text(id: UUID(), content: "@johndoe", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                            ]),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "Follow", action: .custom(actionName: "follow"), style: .borderedProminent)
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Feed Post 1
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .circle(id: UUID(), size: 40, color: "#34C759"),
                                .vstack(id: UUID(), spacing: 2, children: [
                                    .text(id: UUID(), content: "Jane Smith", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "2 hours ago", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "•••", action: .custom(actionName: "showMenu"), style: .plain)
                            ]),
                            .text(id: UUID(), content: "Just finished an amazing project! Can't wait to share more details soon. 🚀", fontSize: 14, fontWeight: .regular, color: ""),
                            .rectangle(id: UUID(), width: 350, height: 200, color: "#E5E5EA", cornerRadius: 12),
                            .hstack(id: UUID(), spacing: 24, children: [
                                .hstack(id: UUID(), spacing: 6, children: [
                                    .image(id: UUID(), systemName: "heart", size: 20, color: "#8E8E93"),
                                    .text(id: UUID(), content: "124", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 6, children: [
                                    .image(id: UUID(), systemName: "bubble.right", size: 20, color: "#8E8E93"),
                                    .text(id: UUID(), content: "32", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 6, children: [
                                    .image(id: UUID(), systemName: "arrow.2.squarepath", size: 20, color: "#8E8E93"),
                                    .text(id: UUID(), content: "8", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .image(id: UUID(), systemName: "square.and.arrow.up", size: 20, color: "#8E8E93")
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Feed Post 2
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .circle(id: UUID(), size: 40, color: "#FF9500"),
                                .vstack(id: UUID(), spacing: 2, children: [
                                    .text(id: UUID(), content: "Mike Johnson", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "5 hours ago", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "•••", action: .custom(actionName: "showMenu"), style: .plain)
                            ]),
                            .text(id: UUID(), content: "Beautiful sunset today! 🌅", fontSize: 14, fontWeight: .regular, color: ""),
                            .hstack(id: UUID(), spacing: 24, children: [
                                .hstack(id: UUID(), spacing: 6, children: [
                                    .image(id: UUID(), systemName: "heart.fill", size: 20, color: "#FF3B30"),
                                    .text(id: UUID(), content: "89", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 6, children: [
                                    .image(id: UUID(), systemName: "bubble.right", size: 20, color: "#8E8E93"),
                                    .text(id: UUID(), content: "12", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID())
                            ])
                        ])
                    ])
                ])
            ]
        )
    }
}

    
    private var ecommerceStoreTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "E-commerce Store",
            description: "Product grid, cart, and checkout flow",
            icon: "cart.fill",
            category: .basic,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header with Cart
                        .hstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Shop", fontSize: 28, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "🛒 3", action: .custom(actionName: "showCart"), style: .bordered)
                        ]),
                        
                        // Search Bar
                        .hstack(id: UUID(), spacing: 8, children: [
                            .image(id: UUID(), systemName: "magnifyingglass", size: 16, color: "#8E8E93"),
                            .textField(id: UUID(), placeholder: "Search products...", binding: "searchQuery")
                        ]),
                        
                        // Categories
                        .scrollView(id: UUID(), axis: .horizontal, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .button(id: UUID(), title: "All", action: .custom(actionName: "filterAll"), style: .borderedProminent),
                                .button(id: UUID(), title: "Electronics", action: .custom(actionName: "filterElectronics"), style: .bordered),
                                .button(id: UUID(), title: "Clothing", action: .custom(actionName: "filterClothing"), style: .bordered),
                                .button(id: UUID(), title: "Home", action: .custom(actionName: "filterHome"), style: .bordered)
                            ])
                        ]),
                        
                        // Product Grid
                        .vstack(id: UUID(), spacing: 16, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 160, height: 160, color: "#E5E5EA", cornerRadius: 12),
                                    .text(id: UUID(), content: "Wireless Headphones", fontSize: 14, fontWeight: .medium, color: ""),
                                    .text(id: UUID(), content: "$129.99", fontSize: 16, fontWeight: .bold, color: "#007AFF")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 160, height: 160, color: "#E5E5EA", cornerRadius: 12),
                                    .text(id: UUID(), content: "Smart Watch", fontSize: 14, fontWeight: .medium, color: ""),
                                    .text(id: UUID(), content: "$299.99", fontSize: 16, fontWeight: .bold, color: "#007AFF")
                                ])
                            ]),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 160, height: 160, color: "#E5E5EA", cornerRadius: 12),
                                    .text(id: UUID(), content: "Laptop Stand", fontSize: 14, fontWeight: .medium, color: ""),
                                    .text(id: UUID(), content: "$49.99", fontSize: 16, fontWeight: .bold, color: "#007AFF")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 160, height: 160, color: "#E5E5EA", cornerRadius: 12),
                                    .text(id: UUID(), content: "USB-C Cable", fontSize: 14, fontWeight: .medium, color: ""),
                                    .text(id: UUID(), content: "$19.99", fontSize: 16, fontWeight: .bold, color: "#007AFF")
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var taskManagerTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Task Manager",
            description: "Task lists with kanban board and calendar views",
            icon: "checklist",
            category: .basic,
            components: [
                .vstack(id: UUID(), spacing: 16, children: [
                    // Header
                    .hstack(id: UUID(), spacing: 12, children: [
                        .text(id: UUID(), content: "My Tasks", fontSize: 28, fontWeight: .bold, color: ""),
                        .spacer(id: UUID()),
                        .button(id: UUID(), title: "+", action: .custom(actionName: "addTask"), style: .borderedProminent)
                    ]),
                    
                    // View Switcher
                    .hstack(id: UUID(), spacing: 8, children: [
                        .button(id: UUID(), title: "List", action: .custom(actionName: "showList"), style: .borderedProminent),
                        .button(id: UUID(), title: "Board", action: .custom(actionName: "showBoard"), style: .bordered),
                        .button(id: UUID(), title: "Calendar", action: .custom(actionName: "showCalendar"), style: .bordered)
                    ]),
                    
                    // Task List
                    .scrollView(id: UUID(), axis: .vertical, children: [
                        .vstack(id: UUID(), spacing: 12, children: [
                            // Today Section
                            .text(id: UUID(), content: "Today", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 24, color: "#E5E5EA"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Review project proposal", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Due: 2:00 PM", fontSize: 12, fontWeight: .regular, color: "#FF9500")
                                    ]),
                                    .spacer(id: UUID()),
                                    .rectangle(id: UUID(), width: 8, height: 8, color: "#FF3B30", cornerRadius: 4)
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 24, color: "#34C759"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Team standup meeting", fontSize: 16, fontWeight: .medium, color: "#8E8E93"),
                                        .text(id: UUID(), content: "Completed", fontSize: 12, fontWeight: .regular, color: "#34C759")
                                    ]),
                                    .spacer(id: UUID())
                                ])
                            ]),
                            
                            .divider(id: UUID()),
                            
                            // Tomorrow Section
                            .text(id: UUID(), content: "Tomorrow", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 24, color: "#E5E5EA"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Prepare presentation", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Due: 10:00 AM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .rectangle(id: UUID(), width: 8, height: 8, color: "#007AFF", cornerRadius: 4)
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var settingsScreenTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Settings Screen",
            description: "Grouped settings with toggles and navigation",
            icon: "gearshape.fill",
            category: .settings,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 24, children: [
                        // Header
                        .text(id: UUID(), content: "Settings", fontSize: 32, fontWeight: .bold, color: ""),
                        
                        // Account Section
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Account", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 50, color: "#007AFF"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "John Doe", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "john@example.com", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Preferences Section
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Preferences", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 16, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .image(id: UUID(), systemName: "bell.fill", size: 20, color: "#007AFF"),
                                    .text(id: UUID(), content: "Notifications", fontSize: 16, fontWeight: .regular, color: ""),
                                    .spacer(id: UUID()),
                                    .toggle(id: UUID(), label: "", binding: "notificationsEnabled")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .image(id: UUID(), systemName: "moon.fill", size: 20, color: "#5856D6"),
                                    .text(id: UUID(), content: "Dark Mode", fontSize: 16, fontWeight: .regular, color: ""),
                                    .spacer(id: UUID()),
                                    .toggle(id: UUID(), label: "", binding: "darkModeEnabled")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .image(id: UUID(), systemName: "location.fill", size: 20, color: "#34C759"),
                                    .text(id: UUID(), content: "Location Services", fontSize: 16, fontWeight: .regular, color: ""),
                                    .spacer(id: UUID()),
                                    .toggle(id: UUID(), label: "", binding: "locationEnabled")
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Support Section
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Support", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .image(id: UUID(), systemName: "questionmark.circle.fill", size: 20, color: "#FF9500"),
                                    .text(id: UUID(), content: "Help Center", fontSize: 16, fontWeight: .regular, color: ""),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .image(id: UUID(), systemName: "envelope.fill", size: 20, color: "#007AFF"),
                                    .text(id: UUID(), content: "Contact Us", fontSize: 16, fontWeight: .regular, color: ""),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Sign Out Button
                        .button(id: UUID(), title: "Sign Out", action: .custom(actionName: "signOut"), style: .bordered)
                    ])
                ])
            ]
        )
    }

    
    private var onboardingFlowTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Onboarding Flow",
            description: "Welcome screens with skip and continue buttons",
            icon: "hand.wave.fill",
            category: .basic,
            components: [
                .vstack(id: UUID(), spacing: 32, children: [
                    // Skip Button
                    .hstack(id: UUID(), spacing: 12, children: [
                        .spacer(id: UUID()),
                        .button(id: UUID(), title: "Skip", action: .custom(actionName: "skip"), style: .plain)
                    ]),
                    
                    .spacer(id: UUID()),
                    
                    // Content
                    .vstack(id: UUID(), spacing: 24, children: [
                        .image(id: UUID(), systemName: "star.fill", size: 80, color: "#FFD700"),
                        .text(id: UUID(), content: "Welcome to App", fontSize: 32, fontWeight: .bold, color: ""),
                        .text(id: UUID(), content: "Discover amazing features that will help you achieve your goals", fontSize: 16, fontWeight: .regular, color: "#8E8E93")
                    ]),
                    
                    .spacer(id: UUID()),
                    
                    // Page Indicators
                    .hstack(id: UUID(), spacing: 8, children: [
                        .circle(id: UUID(), size: 8, color: "#007AFF"),
                        .circle(id: UUID(), size: 8, color: "#E5E5EA"),
                        .circle(id: UUID(), size: 8, color: "#E5E5EA")
                    ]),
                    
                    // Continue Button
                    .button(id: UUID(), title: "Continue", action: .custom(actionName: "continue"), style: .borderedProminent)
                ])
            ]
        )
    }

    
    private var profileEditorTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Profile Editor",
            description: "Avatar picker with form fields for editing profile",
            icon: "person.crop.circle.badge.pencil",
            category: .profile,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 24, children: [
                        // Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .button(id: UUID(), title: "Cancel", action: .custom(actionName: "cancel"), style: .plain),
                            .spacer(id: UUID()),
                            .text(id: UUID(), content: "Edit Profile", fontSize: 18, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "Save", action: .custom(actionName: "save"), style: .plain)
                        ]),
                        
                        // Avatar Section
                        .vstack(id: UUID(), spacing: 12, children: [
                            .circle(id: UUID(), size: 100, color: "#007AFF"),
                            .button(id: UUID(), title: "Change Photo", action: .custom(actionName: "changePhoto"), style: .bordered)
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Form Fields
                        .vstack(id: UUID(), spacing: 20, children: [
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Name", fontSize: 14, fontWeight: .medium, color: "#8E8E93"),
                                .textField(id: UUID(), placeholder: "Enter your name", binding: "name")
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Username", fontSize: 14, fontWeight: .medium, color: "#8E8E93"),
                                .textField(id: UUID(), placeholder: "Enter username", binding: "username")
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Email", fontSize: 14, fontWeight: .medium, color: "#8E8E93"),
                                .textField(id: UUID(), placeholder: "Enter email", binding: "email")
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Bio", fontSize: 14, fontWeight: .medium, color: "#8E8E93"),
                                .textField(id: UUID(), placeholder: "Tell us about yourself", binding: "bio")
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Website", fontSize: 14, fontWeight: .medium, color: "#8E8E93"),
                                .textField(id: UUID(), placeholder: "https://", binding: "website")
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Privacy Settings
                        .vstack(id: UUID(), spacing: 16, children: [
                            .text(id: UUID(), content: "Privacy", fontSize: 18, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Private Account", fontSize: 16, fontWeight: .regular, color: ""),
                                .spacer(id: UUID()),
                                .toggle(id: UUID(), label: "", binding: "isPrivate")
                            ]),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Show Activity Status", fontSize: 16, fontWeight: .regular, color: ""),
                                .spacer(id: UUID()),
                                .toggle(id: UUID(), label: "", binding: "showActivity")
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var searchFilterTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Search & Filter",
            description: "Search bar with filter chips and results list",
            icon: "magnifyingglass",
            category: .basic,
            components: [
                .vstack(id: UUID(), spacing: 16, children: [
                    // Search Bar
                    .hstack(id: UUID(), spacing: 12, children: [
                        .image(id: UUID(), systemName: "magnifyingglass", size: 18, color: "#8E8E93"),
                        .textField(id: UUID(), placeholder: "Search...", binding: "searchQuery"),
                        .button(id: UUID(), title: "Cancel", action: .custom(actionName: "cancelSearch"), style: .plain)
                    ]),
                    
                    // Filter Chips
                    .scrollView(id: UUID(), axis: .horizontal, children: [
                        .hstack(id: UUID(), spacing: 12, children: [
                            .button(id: UUID(), title: "All", action: .custom(actionName: "filterAll"), style: .borderedProminent),
                            .button(id: UUID(), title: "Recent", action: .custom(actionName: "filterRecent"), style: .bordered),
                            .button(id: UUID(), title: "Popular", action: .custom(actionName: "filterPopular"), style: .bordered),
                            .button(id: UUID(), title: "Favorites", action: .custom(actionName: "filterFavorites"), style: .bordered),
                            .button(id: UUID(), title: "Nearby", action: .custom(actionName: "filterNearby"), style: .bordered)
                        ])
                    ]),
                    
                    .divider(id: UUID()),
                    
                    // Results List
                    .scrollView(id: UUID(), axis: .vertical, children: [
                        .vstack(id: UUID(), spacing: 12, children: [
                            // Result 1
                            .hstack(id: UUID(), spacing: 12, children: [
                                .rectangle(id: UUID(), width: 60, height: 60, color: "#E5E5EA", cornerRadius: 8),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Result Title 1", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Description of the first result", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                    .hstack(id: UUID(), spacing: 8, children: [
                                        .image(id: UUID(), systemName: "star.fill", size: 12, color: "#FFD700"),
                                        .text(id: UUID(), content: "4.8", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "2.5 km", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ])
                                ]),
                                .spacer(id: UUID()),
                                .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                            ]),
                            
                            .divider(id: UUID()),
                            
                            // Result 2
                            .hstack(id: UUID(), spacing: 12, children: [
                                .rectangle(id: UUID(), width: 60, height: 60, color: "#E5E5EA", cornerRadius: 8),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Result Title 2", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Description of the second result", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                    .hstack(id: UUID(), spacing: 8, children: [
                                        .image(id: UUID(), systemName: "star.fill", size: 12, color: "#FFD700"),
                                        .text(id: UUID(), content: "4.5", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "1.2 km", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ])
                                ]),
                                .spacer(id: UUID()),
                                .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                            ]),
                            
                            .divider(id: UUID()),
                            
                            // Result 3
                            .hstack(id: UUID(), spacing: 12, children: [
                                .rectangle(id: UUID(), width: 60, height: 60, color: "#E5E5EA", cornerRadius: 8),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Result Title 3", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Description of the third result", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                    .hstack(id: UUID(), spacing: 8, children: [
                                        .image(id: UUID(), systemName: "star.fill", size: 12, color: "#FFD700"),
                                        .text(id: UUID(), content: "4.9", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "3.8 km", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ])
                                ]),
                                .spacer(id: UUID()),
                                .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                            ])
                        ])
                    ])
                ])
            ]
        )
    }


    // MARK: - Industry-Specific Templates (Task 17)
    
    private var healthcareDashboardTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Healthcare Dashboard",
            description: "Medical dashboard with appointments, vitals, and reminders",
            icon: "heart.text.square.fill",
            category: .dashboard,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Health Dashboard", fontSize: 28, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "Profile", action: .custom(actionName: "showProfile"), style: .bordered)
                        ]),
                        
                        // Vital Signs Card
                        .vstack(id: UUID(), spacing: 16, children: [
                            .text(id: UUID(), content: "Vital Signs", fontSize: 20, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "heart.fill", size: 30, color: "#FF3B30"),
                                    .text(id: UUID(), content: "72 bpm", fontSize: 18, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Heart Rate", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "waveform.path.ecg", size: 30, color: "#007AFF"),
                                    .text(id: UUID(), content: "120/80", fontSize: 18, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Blood Pressure", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "thermometer", size: 30, color: "#FF9500"),
                                    .text(id: UUID(), content: "98.6°F", fontSize: 18, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Temperature", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),

                        // Upcoming Appointments
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Appointments", fontSize: 18, fontWeight: .bold, color: ""),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "View All", action: .custom(actionName: "viewAllAppointments"), style: .plain)
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 50, height: 50, color: "#34C759", cornerRadius: 8),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Dr. Sarah Johnson", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "General Checkup", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "Today, 2:30 PM", fontSize: 12, fontWeight: .regular, color: "#007AFF")
                                    ]),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 50, height: 50, color: "#007AFF", cornerRadius: 8),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Dr. Michael Chen", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "Follow-up Visit", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                        .text(id: UUID(), content: "Tomorrow, 10:00 AM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ])
                            ])
                        ]),

                        .divider(id: UUID()),
                        
                        // Medication Reminders
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Medications", fontSize: 18, fontWeight: .bold, color: ""),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "+", action: .custom(actionName: "addMedication"), style: .borderedProminent)
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 40, color: "#FF9500"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Aspirin 100mg", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Take with breakfast", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .button(id: UUID(), title: "✓", action: .custom(actionName: "markTaken"), style: .bordered)
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 40, color: "#5856D6"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Vitamin D", fontSize: 16, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Once daily", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .button(id: UUID(), title: "✓", action: .custom(actionName: "markTaken"), style: .bordered)
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var educationPortalTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Education Portal",
            description: "Student portal with courses, grades, and assignments",
            icon: "graduationcap.fill",
            category: .basic,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header with Student Info
                        .hstack(id: UUID(), spacing: 12, children: [
                            .circle(id: UUID(), size: 50, color: "#007AFF"),
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "Welcome, Alex", fontSize: 20, fontWeight: .bold, color: ""),
                                .text(id: UUID(), content: "Computer Science • Junior", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                            ]),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "📅", action: .custom(actionName: "showCalendar"), style: .bordered)
                        ]),
                        
                        // GPA Card
                        .hstack(id: UUID(), spacing: 16, children: [
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Current GPA", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                .text(id: UUID(), content: "3.85", fontSize: 32, fontWeight: .bold, color: "#34C759")
                            ]),
                            .divider(id: UUID()),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .text(id: UUID(), content: "Credits", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                .text(id: UUID(), content: "87/120", fontSize: 24, fontWeight: .bold, color: "#007AFF")
                            ])
                        ]),
                        
                        .divider(id: UUID()),

                        // Current Courses
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Current Courses", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 60, height: 60, color: "#007AFF", cornerRadius: 12),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Data Structures", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "CS 201 • Prof. Smith", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .hstack(id: UUID(), spacing: 8, children: [
                                            .text(id: UUID(), content: "Grade: A", fontSize: 12, fontWeight: .medium, color: "#34C759"),
                                            .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                            .text(id: UUID(), content: "3 Credits", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ])
                                    ]),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 60, height: 60, color: "#34C759", cornerRadius: 12),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Web Development", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "CS 305 • Prof. Johnson", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                        .hstack(id: UUID(), spacing: 8, children: [
                                            .text(id: UUID(), content: "Grade: A-", fontSize: 12, fontWeight: .medium, color: "#34C759"),
                                            .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                            .text(id: UUID(), content: "4 Credits", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ])
                                    ]),
                                    .spacer(id: UUID()),
                                    .image(id: UUID(), systemName: "chevron.right", size: 14, color: "#8E8E93")
                                ])
                            ])
                        ]),

                        .divider(id: UUID()),
                        
                        // Upcoming Assignments
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Assignments", fontSize: 18, fontWeight: .bold, color: ""),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "View All", action: .custom(actionName: "viewAllAssignments"), style: .plain)
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 8, height: 50, color: "#FF3B30", cornerRadius: 4),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Binary Search Tree Implementation", fontSize: 14, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Data Structures • Due Tomorrow", fontSize: 12, fontWeight: .regular, color: "#FF3B30")
                                    ]),
                                    .spacer(id: UUID())
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 8, height: 50, color: "#FF9500", cornerRadius: 4),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "React Portfolio Project", fontSize: 14, fontWeight: .medium, color: ""),
                                        .text(id: UUID(), content: "Web Development • Due in 3 days", fontSize: 12, fontWeight: .regular, color: "#FF9500")
                                    ]),
                                    .spacer(id: UUID())
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var realEstateListingTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Real Estate Listing",
            description: "Property listings with cards, map view, and filters",
            icon: "house.fill",
            category: .basic,
            components: [
                .vstack(id: UUID(), spacing: 16, children: [
                    // Search and Filter Bar
                    .vstack(id: UUID(), spacing: 12, children: [
                        .hstack(id: UUID(), spacing: 12, children: [
                            .image(id: UUID(), systemName: "magnifyingglass", size: 18, color: "#8E8E93"),
                            .textField(id: UUID(), placeholder: "Search location...", binding: "searchQuery"),
                            .button(id: UUID(), title: "🗺", action: .custom(actionName: "showMap"), style: .bordered)
                        ]),
                        .scrollView(id: UUID(), axis: .horizontal, children: [
                            .hstack(id: UUID(), spacing: 8, children: [
                                .button(id: UUID(), title: "All", action: .custom(actionName: "filterAll"), style: .borderedProminent),
                                .button(id: UUID(), title: "For Sale", action: .custom(actionName: "filterSale"), style: .bordered),
                                .button(id: UUID(), title: "For Rent", action: .custom(actionName: "filterRent"), style: .bordered),
                                .button(id: UUID(), title: "Price", action: .custom(actionName: "filterPrice"), style: .bordered),
                                .button(id: UUID(), title: "Bedrooms", action: .custom(actionName: "filterBedrooms"), style: .bordered)
                            ])
                        ])
                    ]),
                    
                    .divider(id: UUID()),
                    
                    // Property Listings
                    .scrollView(id: UUID(), axis: .vertical, children: [
                        .vstack(id: UUID(), spacing: 16, children: [

                            // Property Card 1
                            .vstack(id: UUID(), spacing: 12, children: [
                                .rectangle(id: UUID(), width: 350, height: 200, color: "#E5E5EA", cornerRadius: 12),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .vstack(id: UUID(), spacing: 8, children: [
                                        .text(id: UUID(), content: "$850,000", fontSize: 24, fontWeight: .bold, color: "#007AFF"),
                                        .text(id: UUID(), content: "Modern Downtown Condo", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "123 Main St, Downtown", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                        .hstack(id: UUID(), spacing: 16, children: [
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "bed.double.fill", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "3", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ]),
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "shower.fill", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "2", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ]),
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "square.split.2x2", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "1,850 sqft", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ])
                                        ])
                                    ]),
                                    .spacer(id: UUID()),
                                    .button(id: UUID(), title: "♡", action: .custom(actionName: "toggleFavorite"), style: .bordered)
                                ])
                            ]),

                            // Property Card 2
                            .vstack(id: UUID(), spacing: 12, children: [
                                .rectangle(id: UUID(), width: 350, height: 200, color: "#E5E5EA", cornerRadius: 12),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .vstack(id: UUID(), spacing: 8, children: [
                                        .text(id: UUID(), content: "$2,500/mo", fontSize: 24, fontWeight: .bold, color: "#34C759"),
                                        .text(id: UUID(), content: "Spacious Family Home", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "456 Oak Ave, Suburbs", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                        .hstack(id: UUID(), spacing: 16, children: [
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "bed.double.fill", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "4", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ]),
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "shower.fill", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "3", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ]),
                                            .hstack(id: UUID(), spacing: 4, children: [
                                                .image(id: UUID(), systemName: "square.split.2x2", size: 14, color: "#8E8E93"),
                                                .text(id: UUID(), content: "2,400 sqft", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                                            ])
                                        ])
                                    ]),
                                    .spacer(id: UUID()),
                                    .button(id: UUID(), title: "♡", action: .custom(actionName: "toggleFavorite"), style: .bordered)
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var foodDeliveryTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Food Delivery",
            description: "Restaurant list, menu, cart, and order tracking",
            icon: "fork.knife",
            category: .basic,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header with Location
                        .hstack(id: UUID(), spacing: 12, children: [
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "Deliver to", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                .hstack(id: UUID(), spacing: 4, children: [
                                    .image(id: UUID(), systemName: "location.fill", size: 14, color: "#007AFF"),
                                    .text(id: UUID(), content: "123 Main St", fontSize: 16, fontWeight: .bold, color: "")
                                ])
                            ]),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "🛒 2", action: .custom(actionName: "showCart"), style: .borderedProminent)
                        ]),
                        
                        // Search Bar
                        .hstack(id: UUID(), spacing: 8, children: [
                            .image(id: UUID(), systemName: "magnifyingglass", size: 16, color: "#8E8E93"),
                            .textField(id: UUID(), placeholder: "Search restaurants or dishes...", binding: "searchQuery")
                        ]),
                        
                        // Categories
                        .scrollView(id: UUID(), axis: .horizontal, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .circle(id: UUID(), size: 60, color: "#FF9500"),
                                    .text(id: UUID(), content: "Pizza", fontSize: 12, fontWeight: .regular, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .circle(id: UUID(), size: 60, color: "#34C759"),
                                    .text(id: UUID(), content: "Burgers", fontSize: 12, fontWeight: .regular, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .circle(id: UUID(), size: 60, color: "#FF3B30"),
                                    .text(id: UUID(), content: "Sushi", fontSize: 12, fontWeight: .regular, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .circle(id: UUID(), size: 60, color: "#5856D6"),
                                    .text(id: UUID(), content: "Desserts", fontSize: 12, fontWeight: .regular, color: "")
                                ])
                            ])
                        ]),

                        .divider(id: UUID()),
                        
                        // Featured Restaurants
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Popular Near You", fontSize: 18, fontWeight: .bold, color: ""),
                            .vstack(id: UUID(), spacing: 16, children: [
                                // Restaurant Card 1
                                .vstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 350, height: 150, color: "#E5E5EA", cornerRadius: 12),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .text(id: UUID(), content: "Joe's Pizza", fontSize: 18, fontWeight: .bold, color: ""),
                                            .text(id: UUID(), content: "Italian • Pizza", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .hstack(id: UUID(), spacing: 4, children: [
                                                    .image(id: UUID(), systemName: "star.fill", size: 12, color: "#FFD700"),
                                                    .text(id: UUID(), content: "4.8", fontSize: 12, fontWeight: .regular, color: "")
                                                ]),
                                                .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "25-35 min", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "$2.99 delivery", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                            ])
                                        ]),
                                        .spacer(id: UUID())
                                    ])
                                ]),

                                // Restaurant Card 2
                                .vstack(id: UUID(), spacing: 12, children: [
                                    .rectangle(id: UUID(), width: 350, height: 150, color: "#E5E5EA", cornerRadius: 12),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .text(id: UUID(), content: "Sushi Palace", fontSize: 18, fontWeight: .bold, color: ""),
                                            .text(id: UUID(), content: "Japanese • Sushi", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .hstack(id: UUID(), spacing: 4, children: [
                                                    .image(id: UUID(), systemName: "star.fill", size: 12, color: "#FFD700"),
                                                    .text(id: UUID(), content: "4.9", fontSize: 12, fontWeight: .regular, color: "")
                                                ]),
                                                .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "30-40 min", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "•", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                                .text(id: UUID(), content: "Free delivery", fontSize: 12, fontWeight: .regular, color: "#34C759")
                                            ])
                                        ]),
                                        .spacer(id: UUID())
                                    ])
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var fitnessTrackerTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Fitness Tracker",
            description: "Workout tracking with progress stats and exercise history",
            icon: "figure.run",
            category: .dashboard,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Fitness", fontSize: 28, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "Profile", action: .custom(actionName: "showProfile"), style: .bordered)
                        ]),
                        
                        // Daily Activity Rings
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Today's Activity", fontSize: 18, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 20, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .circle(id: UUID(), size: 80, color: "#FF3B30"),
                                    .text(id: UUID(), content: "Move", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "420/500 cal", fontSize: 14, fontWeight: .bold, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .circle(id: UUID(), size: 80, color: "#34C759"),
                                    .text(id: UUID(), content: "Exercise", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "25/30 min", fontSize: 14, fontWeight: .bold, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .circle(id: UUID(), size: 80, color: "#007AFF"),
                                    .text(id: UUID(), content: "Stand", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "10/12 hrs", fontSize: 14, fontWeight: .bold, color: "")
                                ])
                            ])
                        ]),

                        .divider(id: UUID()),
                        
                        // Quick Stats
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "This Week", fontSize: 18, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 100, height: 80, color: "#FF9500", cornerRadius: 12),
                                    .text(id: UUID(), content: "Workouts", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "5", fontSize: 24, fontWeight: .bold, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 100, height: 80, color: "#5856D6", cornerRadius: 12),
                                    .text(id: UUID(), content: "Calories", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "2,840", fontSize: 24, fontWeight: .bold, color: "")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .rectangle(id: UUID(), width: 100, height: 80, color: "#34C759", cornerRadius: 12),
                                    .text(id: UUID(), content: "Minutes", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "180", fontSize: 24, fontWeight: .bold, color: "")
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),

                        // Recent Workouts
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Recent Workouts", fontSize: 18, fontWeight: .bold, color: ""),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "+", action: .custom(actionName: "addWorkout"), style: .borderedProminent)
                            ]),
                            .vstack(id: UUID(), spacing: 8, children: [
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 50, color: "#FF3B30"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Morning Run", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "5.2 km • 32 min • 420 cal", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .text(id: UUID(), content: "Today", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .hstack(id: UUID(), spacing: 12, children: [
                                    .circle(id: UUID(), size: 50, color: "#007AFF"),
                                    .vstack(id: UUID(), spacing: 4, children: [
                                        .text(id: UUID(), content: "Strength Training", fontSize: 16, fontWeight: .bold, color: ""),
                                        .text(id: UUID(), content: "45 min • 280 cal", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                    ]),
                                    .spacer(id: UUID()),
                                    .text(id: UUID(), content: "Yesterday", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

    
    private var travelPlannerTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Travel Planner",
            description: "Trip itinerary with bookings, maps, and travel details",
            icon: "airplane",
            category: .basic,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 20, children: [
                        // Header
                        .hstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "My Trips", fontSize: 28, fontWeight: .bold, color: ""),
                            .spacer(id: UUID()),
                            .button(id: UUID(), title: "+", action: .custom(actionName: "addTrip"), style: .borderedProminent)
                        ]),
                        
                        // Upcoming Trip Card
                        .vstack(id: UUID(), spacing: 16, children: [
                            .rectangle(id: UUID(), width: 350, height: 180, color: "#007AFF", cornerRadius: 16),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .text(id: UUID(), content: "Paris, France", fontSize: 24, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Dec 15 - Dec 22, 2024", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                                    .hstack(id: UUID(), spacing: 16, children: [
                                        .hstack(id: UUID(), spacing: 4, children: [
                                            .image(id: UUID(), systemName: "airplane", size: 14, color: "#007AFF"),
                                            .text(id: UUID(), content: "Round trip", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ]),
                                        .hstack(id: UUID(), spacing: 4, children: [
                                            .image(id: UUID(), systemName: "bed.double.fill", size: 14, color: "#007AFF"),
                                            .text(id: UUID(), content: "7 nights", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ])
                                    ])
                                ]),
                                .spacer(id: UUID())
                            ])
                        ]),

                        .divider(id: UUID()),
                        
                        // Itinerary
                        .vstack(id: UUID(), spacing: 12, children: [
                            .hstack(id: UUID(), spacing: 12, children: [
                                .text(id: UUID(), content: "Itinerary", fontSize: 18, fontWeight: .bold, color: ""),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "View Map", action: .custom(actionName: "showMap"), style: .bordered)
                            ]),
                            .vstack(id: UUID(), spacing: 12, children: [
                                // Day 1
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .text(id: UUID(), content: "Day 1 - Dec 15", fontSize: 16, fontWeight: .bold, color: ""),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .rectangle(id: UUID(), width: 4, height: 60, color: "#007AFF", cornerRadius: 2),
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .image(id: UUID(), systemName: "airplane.departure", size: 16, color: "#007AFF"),
                                                .text(id: UUID(), content: "Flight to Paris", fontSize: 14, fontWeight: .medium, color: "")
                                            ]),
                                            .text(id: UUID(), content: "AA 123 • 10:00 AM - 11:30 PM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ]),
                                        .spacer(id: UUID())
                                    ]),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .rectangle(id: UUID(), width: 4, height: 60, color: "#34C759", cornerRadius: 2),
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .image(id: UUID(), systemName: "bed.double.fill", size: 16, color: "#34C759"),
                                                .text(id: UUID(), content: "Hotel Check-in", fontSize: 14, fontWeight: .medium, color: "")
                                            ]),
                                            .text(id: UUID(), content: "Le Grand Hotel • 3:00 PM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ]),
                                        .spacer(id: UUID())
                                    ])
                                ]),

                                // Day 2
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .text(id: UUID(), content: "Day 2 - Dec 16", fontSize: 16, fontWeight: .bold, color: ""),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .rectangle(id: UUID(), width: 4, height: 60, color: "#FF9500", cornerRadius: 2),
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .image(id: UUID(), systemName: "building.columns.fill", size: 16, color: "#FF9500"),
                                                .text(id: UUID(), content: "Eiffel Tower Visit", fontSize: 14, fontWeight: .medium, color: "")
                                            ]),
                                            .text(id: UUID(), content: "Guided tour • 9:00 AM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ]),
                                        .spacer(id: UUID())
                                    ]),
                                    .hstack(id: UUID(), spacing: 12, children: [
                                        .rectangle(id: UUID(), width: 4, height: 60, color: "#FF3B30", cornerRadius: 2),
                                        .vstack(id: UUID(), spacing: 4, children: [
                                            .hstack(id: UUID(), spacing: 8, children: [
                                                .image(id: UUID(), systemName: "fork.knife", size: 16, color: "#FF3B30"),
                                                .text(id: UUID(), content: "Dinner Reservation", fontSize: 14, fontWeight: .medium, color: "")
                                            ]),
                                            .text(id: UUID(), content: "Le Bistro • 7:00 PM", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                        ]),
                                        .spacer(id: UUID())
                                    ])
                                ])
                            ])
                        ]),
                        
                        .divider(id: UUID()),
                        
                        // Bookings Summary
                        .vstack(id: UUID(), spacing: 12, children: [
                            .text(id: UUID(), content: "Bookings", fontSize: 18, fontWeight: .bold, color: ""),
                            .hstack(id: UUID(), spacing: 12, children: [
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "airplane", size: 24, color: "#007AFF"),
                                    .text(id: UUID(), content: "Flight", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "Confirmed", fontSize: 12, fontWeight: .bold, color: "#34C759")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "bed.double.fill", size: 24, color: "#34C759"),
                                    .text(id: UUID(), content: "Hotel", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "Confirmed", fontSize: 12, fontWeight: .bold, color: "#34C759")
                                ]),
                                .vstack(id: UUID(), spacing: 8, children: [
                                    .image(id: UUID(), systemName: "car.fill", size: 24, color: "#FF9500"),
                                    .text(id: UUID(), content: "Rental", fontSize: 12, fontWeight: .regular, color: "#8E8E93"),
                                    .text(id: UUID(), content: "Pending", fontSize: 12, fontWeight: .bold, color: "#FF9500")
                                ])
                            ])
                        ])
                    ])
                ])
            ]
        )
    }

