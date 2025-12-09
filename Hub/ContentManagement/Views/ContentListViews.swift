//
//  ContentListViews.swift
//  Hub
//
//  List views for each content type
//

import SwiftUI
import SwiftData

// MARK: - Hub List View

struct HubListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var hubs: [AppHub] {
        let all = contentManager.fetchHubs()
        if searchText.isEmpty { return all }
        return all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.details.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        List(hubs, selection: $selectedID) { hub in
            HubRowView(hub: hub)
                .tag(hub.id)
                .contextMenu {
                    hubContextMenu(hub)
                }
        }
        .navigationTitle("Hubs")
    }
    
    @ViewBuilder
    private func hubContextMenu(_ hub: AppHub) -> some View {
        Button {
            selectedID = hub.id
        } label: {
            Label("Open", systemImage: "eye")
        }
        
        Button {
            _ = contentManager.duplicateHub(hub)
        } label: {
            Label("Duplicate", systemImage: "doc.on.doc")
        }
        
        Divider()
        
        Button(role: .destructive) {
            contentManager.deleteHub(hub)
        } label: {
            Label("Delete", systemImage: "trash")
        }
    }
}

struct HubRowView: View {
    let hub: AppHub
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: hub.icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40, height: 40)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(hub.name)
                    .font(.headline)
                
                Text(hub.details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if hub.isPublished {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Template List View

struct TemplateListView: View {
    @ObservedObject var contentManager: HubContentManager
    let searchText: String
    @Binding var selectedID: UUID?
    
    private var templates: [TemplateModel] {
        contentManager.fetchTemplates(filter: searchText.isEmpty ? nil : searchText)
    }
    
    var body: some View {
        List(templates, selection: $selectedID) { template in
            List(templates, selection: $selectedID) { template in
                TemplateRowView(template: template)
                    .tag(template.id)
            }
            .navigationTitle("Templates")
        }
    }
    
    struct TemplateRowView: View {
        let template: TemplateModel
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                    
                    Text(template.templateDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(template.category.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.vertical, 4)
        }
    }
}
