import Foundation
import SwiftUI


// MARK: - Authentication Templates Extension

/// Additional authentication templates for AuthHub
/// These extend the base authentication templates in ScreenTemplates.swift
extension ScreenTemplateLibrary {
    
    // MARK: - Forgot Password Templates
    
    var forgotPasswordTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Forgot Password",
            description: "Password reset request screen",
            icon: "key.fill",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 24, children: [
                    .spacer(id: UUID()),
                    // Icon
                    .image(id: UUID(), systemName: "key.fill", size: 60, color: "#007AFF"),
                    // Title
                    .text(id: UUID(), content: "Forgot Password?", fontSize: 28, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "Enter your email to receive a reset link", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                    // Email Field
                    .vstack(id: UUID(), spacing: 16, children: [
                        .textField(id: UUID(), placeholder: "Email", binding: "email")
                    ]),
                    // Send Button
                    .button(id: UUID(), title: "Send Reset Link", action: .custom(actionName: "sendResetLink"), style: .borderedProminent),
                    .spacer(id: UUID()),
                    // Back to Sign In
                    .button(id: UUID(), title: "Back to Sign In", action: .custom(actionName: "backToSignIn"), style: .plain)
                ])
            ]
        )
    }
    
    var resetPasswordTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Reset Password",
            description: "Create new password screen",
            icon: "lock.rotation",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 24, children: [
                    .spacer(id: UUID()),
                    // Icon
                    .image(id: UUID(), systemName: "lock.rotation", size: 60, color: "#34C759"),
                    // Title
                    .text(id: UUID(), content: "Reset Password", fontSize: 28, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "Enter your new password", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                    // Password Fields
                    .vstack(id: UUID(), spacing: 16, children: [
                        .textField(id: UUID(), placeholder: "New Password", binding: "newPassword"),
                        .textField(id: UUID(), placeholder: "Confirm Password", binding: "confirmPassword")
                    ]),
                    // Requirements
                    .vstack(id: UUID(), spacing: 8, children: [
                        .hstack(id: UUID(), spacing: 8, children: [
                            .image(id: UUID(), systemName: "checkmark.circle.fill", size: 16, color: "#34C759"),
                            .text(id: UUID(), content: "At least 8 characters", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                        ]),
                        .hstack(id: UUID(), spacing: 8, children: [
                            .image(id: UUID(), systemName: "checkmark.circle.fill", size: 16, color: "#34C759"),
                            .text(id: UUID(), content: "Contains a number", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                        ])
                    ]),
                    // Reset Button
                    .button(id: UUID(), title: "Reset Password", action: .custom(actionName: "resetPassword"), style: .borderedProminent),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    // MARK: - Two-Factor Authentication Templates
    
    var twoFactorAuthTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Two-Factor Authentication",
            description: "2FA verification code entry",
            icon: "number.square.fill",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 24, children: [
                    .spacer(id: UUID()),
                    // Icon
                    .image(id: UUID(), systemName: "number.square.fill", size: 60, color: "#007AFF"),
                    // Title
                    .text(id: UUID(), content: "Enter Verification Code", fontSize: 28, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "We sent a code to your email", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                    // Code Input
                    .hstack(id: UUID(), spacing: 12, children: [
                        .textField(id: UUID(), placeholder: "0", binding: "digit1"),
                        .textField(id: UUID(), placeholder: "0", binding: "digit2"),
                        .textField(id: UUID(), placeholder: "0", binding: "digit3"),
                        .textField(id: UUID(), placeholder: "0", binding: "digit4"),
                        .textField(id: UUID(), placeholder: "0", binding: "digit5"),
                        .textField(id: UUID(), placeholder: "0", binding: "digit6")
                    ]),
                    // Verify Button
                    .button(id: UUID(), title: "Verify", action: .custom(actionName: "verifyCode"), style: .borderedProminent),
                    // Resend
                    .hstack(id: UUID(), spacing: 4, children: [
                        .text(id: UUID(), content: "Didn't receive code?", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                        .button(id: UUID(), title: "Resend", action: .custom(actionName: "resendCode"), style: .plain)
                    ]),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    var twoFactorSetupTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "2FA Setup",
            description: "Enable two-factor authentication",
            icon: "shield.checkered",
            category: .authentication,
            components: [
                .scrollView(id: UUID(), axis: .vertical, children: [
                    .vstack(id: UUID(), spacing: 24, children: [
                        // Header
                        .vstack(id: UUID(), spacing: 12, children: [
                            .image(id: UUID(), systemName: "shield.checkered", size: 60, color: "#34C759"),
                            .text(id: UUID(), content: "Secure Your Account", fontSize: 28, fontWeight: .bold, color: ""),
                            .text(id: UUID(), content: "Add an extra layer of security", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                        ]),
                        // Options
                        .vstack(id: UUID(), spacing: 16, children: [
                            // SMS Option
                            .hstack(id: UUID(), spacing: 12, children: [
                                .circle(id: UUID(), size: 50, color: "#007AFF"),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Text Message", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Receive codes via SMS", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "Setup", action: .custom(actionName: "setupSMS"), style: .bordered)
                            ]),
                            .divider(id: UUID()),
                            // Authenticator App Option
                            .hstack(id: UUID(), spacing: 12, children: [
                                .circle(id: UUID(), size: 50, color: "#34C759"),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Authenticator App", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Use an authenticator app", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "Setup", action: .custom(actionName: "setupAuthApp"), style: .bordered)
                            ]),
                            .divider(id: UUID()),
                            // Email Option
                            .hstack(id: UUID(), spacing: 12, children: [
                                .circle(id: UUID(), size: 50, color: "#FF9500"),
                                .vstack(id: UUID(), spacing: 4, children: [
                                    .text(id: UUID(), content: "Email", fontSize: 16, fontWeight: .bold, color: ""),
                                    .text(id: UUID(), content: "Receive codes via email", fontSize: 12, fontWeight: .regular, color: "#8E8E93")
                                ]),
                                .spacer(id: UUID()),
                                .button(id: UUID(), title: "Setup", action: .custom(actionName: "setupEmail"), style: .bordered)
                            ])
                        ]),
                        // Skip Button
                        .button(id: UUID(), title: "Skip for Now", action: .custom(actionName: "skip2FA"), style: .plain)
                    ])
                ])
            ]
        )
    }
    
    // MARK: - Biometric Templates
    
    var biometricSetupTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Biometric Setup",
            description: "Enable Face ID or Touch ID",
            icon: "faceid",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 32, children: [
                    .spacer(id: UUID()),
                    // Icon
                    .image(id: UUID(), systemName: "faceid", size: 80, color: "#007AFF"),
                    // Title
                    .vstack(id: UUID(), spacing: 12, children: [
                        .text(id: UUID(), content: "Enable Face ID", fontSize: 28, fontWeight: .bold, color: ""),
                        .text(id: UUID(), content: "Sign in quickly and securely", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                    ]),
                    // Benefits
                    .vstack(id: UUID(), spacing: 16, children: [
                        .hstack(id: UUID(), spacing: 12, children: [
                            .image(id: UUID(), systemName: "checkmark.circle.fill", size: 24, color: "#34C759"),
                            .text(id: UUID(), content: "Faster sign in", fontSize: 16, fontWeight: .regular, color: "")
                        ]),
                        .hstack(id: UUID(), spacing: 12, children: [
                            .image(id: UUID(), systemName: "checkmark.circle.fill", size: 24, color: "#34C759"),
                            .text(id: UUID(), content: "More secure", fontSize: 16, fontWeight: .regular, color: "")
                        ]),
                        .hstack(id: UUID(), spacing: 12, children: [
                            .image(id: UUID(), systemName: "checkmark.circle.fill", size: 24, color: "#34C759"),
                            .text(id: UUID(), content: "No passwords to remember", fontSize: 16, fontWeight: .regular, color: "")
                        ])
                    ]),
                    // Buttons
                    .vstack(id: UUID(), spacing: 12, children: [
                        .button(id: UUID(), title: "Enable Face ID", action: .custom(actionName: "enableBiometric"), style: .borderedProminent),
                        .button(id: UUID(), title: "Maybe Later", action: .custom(actionName: "skipBiometric"), style: .plain)
                    ]),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    // MARK: - Onboarding Templates
    
    var welcomeOnboardingTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Welcome Onboarding",
            description: "First-time user welcome screen",
            icon: "hand.wave.fill",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 32, children: [
                    .spacer(id: UUID()),
                    // Logo/Icon
                    .image(id: UUID(), systemName: "star.circle.fill", size: 100, color: "#007AFF"),
                    // Title
                    .vstack(id: UUID(), spacing: 12, children: [
                        .text(id: UUID(), content: "Welcome!", fontSize: 36, fontWeight: .bold, color: ""),
                        .text(id: UUID(), content: "Let's get you started", fontSize: 16, fontWeight: .regular, color: "#8E8E93")
                    ]),
                    // Features
                    .vstack(id: UUID(), spacing: 20, children: [
                        .hstack(id: UUID(), spacing: 16, children: [
                            .circle(id: UUID(), size: 50, color: "#34C759"),
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "Easy to Use", fontSize: 18, fontWeight: .bold, color: ""),
                                .text(id: UUID(), content: "Intuitive interface", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                            ])
                        ]),
                        .hstack(id: UUID(), spacing: 16, children: [
                            .circle(id: UUID(), size: 50, color: "#FF9500"),
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "Secure", fontSize: 18, fontWeight: .bold, color: ""),
                                .text(id: UUID(), content: "Your data is protected", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                            ])
                        ]),
                        .hstack(id: UUID(), spacing: 16, children: [
                            .circle(id: UUID(), size: 50, color: "#007AFF"),
                            .vstack(id: UUID(), spacing: 4, children: [
                                .text(id: UUID(), content: "Fast", fontSize: 18, fontWeight: .bold, color: ""),
                                .text(id: UUID(), content: "Lightning quick performance", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                            ])
                        ])
                    ]),
                    // Get Started Button
                    .button(id: UUID(), title: "Get Started", action: .custom(actionName: "startOnboarding"), style: .borderedProminent),
                    .spacer(id: UUID())
                ])
            ]
        )
    }
    
    var emailVerificationTemplate: ScreenTemplate {
        ScreenTemplate(
            name: "Email Verification",
            description: "Verify email address screen",
            icon: "envelope.badge.fill",
            category: .authentication,
            components: [
                .vstack(id: UUID(), spacing: 24, children: [
                    .spacer(id: UUID()),
                    // Icon
                    .image(id: UUID(), systemName: "envelope.badge.fill", size: 60, color: "#007AFF"),
                    // Title
                    .text(id: UUID(), content: "Verify Your Email", fontSize: 28, fontWeight: .bold, color: ""),
                    .text(id: UUID(), content: "We sent a verification link to", fontSize: 14, fontWeight: .regular, color: "#8E8E93"),
                    .text(id: UUID(), content: "user@example.com", fontSize: 16, fontWeight: .bold, color: "#007AFF"),
                    // Instructions
                    .vstack(id: UUID(), spacing: 12, children: [
                        .text(id: UUID(), content: "Check your inbox and click the verification link to continue", fontSize: 14, fontWeight: .regular, color: "#8E8E93")
                    ]),
                    // Buttons
                    .vstack(id: UUID(), spacing: 12, children: [
                        .button(id: UUID(), title: "Open Email App", action: .custom(actionName: "openEmail"), style: .borderedProminent),
                        .button(id: UUID(), title: "Resend Email", action: .custom(actionName: "resendVerification"), style: .bordered)
                    ]),
                    .spacer(id: UUID()),
                    // Change Email
                    .button(id: UUID(), title: "Change Email Address", action: .custom(actionName: "changeEmail"), style: .plain)
                ])
            ]
        )
    }
}
