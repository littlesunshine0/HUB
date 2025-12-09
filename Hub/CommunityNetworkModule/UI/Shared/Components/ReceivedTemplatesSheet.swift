import SwiftUI

// MARK: - Received Templates Sheet

struct ReceivedTemplatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    let templates: [TemplateModel]
    let onImport: (TemplateModel) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(templates) { template in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(template.name)
                                .font(.headline)
                            Text("From: \(template.author)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Import") {
                            onImport(template)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Received Templates")
            .toolbar {
                ToolbarItemGroup(placement: .confirmationAction) {
                    Button("Done") {
                        onDismiss()
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}
