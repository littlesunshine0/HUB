import SwiftUI
import Combine

// MARK: - Visual Workflow Designer
struct WorkflowDesignerView: View {
    @StateObject private var viewModel = WorkflowDesignerViewModel()
    @State private var selectedNode: WorkflowNode?
    @State private var showNodePicker = false
    
    var body: some View {
        HSplitView {
            // Node Palette
            NodePaletteView(onNodeSelected: { nodeType in
                viewModel.addNode(type: nodeType)
            })
            .frame(minWidth: 200, maxWidth: 250)
            
            // Canvas
            WorkflowCanvasView(
                nodes: $viewModel.nodes,
                connections: $viewModel.connections,
                selectedNode: $selectedNode
            )
            
            // Properties Panel
            if let node = selectedNode {
                NodePropertiesView(node: node) { updated in
                    viewModel.updateNode(updated)
                }
                .frame(minWidth: 250, maxWidth: 300)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Run") { viewModel.executeWorkflow() }
                Button("Save") { viewModel.saveWorkflow() }
                Button("Clear") { viewModel.clearCanvas() }
            }
        }
    }
}

// MARK: - Node Palette
struct NodePaletteView: View {
    let onNodeSelected: (WorkflowNodeType) -> Void
    
    var body: some View {
        List {
            Section("Triggers") {
                ForEach(WorkflowNodeType.triggers, id: \.self) { type in
                    NodeTypeRow(type: type, onTap: onNodeSelected)
                }
            }
            Section("Actions") {
                ForEach(WorkflowNodeType.actions, id: \.self) { type in
                    NodeTypeRow(type: type, onTap: onNodeSelected)
                }
            }
            Section("Logic") {
                ForEach(WorkflowNodeType.logic, id: \.self) { type in
                    NodeTypeRow(type: type, onTap: onNodeSelected)
                }
            }
        }
    }
}

struct NodeTypeRow: View {
    let type: WorkflowNodeType
    let onTap: (WorkflowNodeType) -> Void
    
    var body: some View {
        Button(action: { onTap(type) }) {
            HStack {
                Image(systemName: type.icon)
                Text(type.displayName)
                Spacer()
            }
        }
    }
}

// MARK: - Canvas
struct WorkflowCanvasView: View {
    @Binding var nodes: [WorkflowNode]
    @Binding var connections: [WorkflowConnection]
    @Binding var selectedNode: WorkflowNode?
    
    @State private var draggedNode: WorkflowNode?
    @State private var connectingFrom: WorkflowNode?
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.1)
            
            // Draw connections
            ForEach(connections) { connection in
                ConnectionLine(
                    from: nodePosition(connection.fromNodeId),
                    to: nodePosition(connection.toNodeId)
                )
            }
            
            // Draw nodes
            ForEach(nodes) { node in
                NodeView(node: node, isSelected: selectedNode?.id == node.id)
                    .position(node.position)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if let index = nodes.firstIndex(where: { $0.id == node.id }) {
                                    nodes[index].position = value.location
                                }
                            }
                    )
                    .onTapGesture {
                        selectedNode = node
                    }
            }
        }
    }
    
    private func nodePosition(_ nodeId: UUID) -> CGPoint {
        nodes.first(where: { $0.id == nodeId })?.position ?? .zero
    }
}

struct NodeView: View {
    let node: WorkflowNode
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: node.type.icon)
                .font(.title2)
            Text(node.name)
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: isSelected ? 8 : 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
        )
    }
}

struct ConnectionLine: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            path.move(to: from)
            path.addLine(to: to)
        }
        .stroke(Color.blue, lineWidth: 2)
    }
}

// MARK: - Properties Panel
struct NodePropertiesView: View {
    let node: WorkflowNode
    let onUpdate: (WorkflowNode) -> Void
    
    @State private var editedNode: WorkflowNode
    
    init(node: WorkflowNode, onUpdate: @escaping (WorkflowNode) -> Void) {
        self.node = node
        self.onUpdate = onUpdate
        _editedNode = State(initialValue: node)
    }
    
    var body: some View {
        Form {
            Section("Basic") {
                TextField("Name", text: $editedNode.name)
                TextField("Description", text: $editedNode.description)
            }
            
            Section("Configuration") {
                ForEach(editedNode.parameters.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key)
                        TextField("Value", text: binding(for: key))
                    }
                }
            }
            
            Button("Apply") {
                onUpdate(editedNode)
            }
        }
        .padding()
    }
    
    private func binding(for key: String) -> Binding<String> {
        Binding(
            get: { editedNode.parameters[key] ?? "" },
            set: { editedNode.parameters[key] = $0 }
        )
    }
}

// MARK: - View Model
@MainActor
class WorkflowDesignerViewModel: ObservableObject {
    @Published var nodes: [WorkflowNode] = []
    @Published var connections: [WorkflowConnection] = []
    @Published var workflow: VisualWorkflow?
    
    func addNode(type: WorkflowNodeType) {
        let node = WorkflowNode(
            type: type,
            name: type.displayName,
            position: CGPoint(x: 400, y: 300)
        )
        nodes.append(node)
    }
    
    func updateNode(_ node: WorkflowNode) {
        if let index = nodes.firstIndex(where: { $0.id == node.id }) {
            nodes[index] = node
        }
    }
    
    func executeWorkflow() {
        let workflow = VisualWorkflow(nodes: nodes, connections: connections)
        Task {
            let stateManager = WorkflowStateManager()
            
            // Create TerminalService dependencies
            let patternRegistry = CommandPatternRegistry()
            let contextManager = ShellContextManager(storageURL: FileManager.default.temporaryDirectory.appendingPathComponent("shell_context.json"))
            let historyManager = CommandHistoryManager(
                storageURL: FileManager.default.temporaryDirectory.appendingPathComponent("workflow_history.json")
            )
            let terminalService = TerminalService(
                patternRegistry: patternRegistry,
                contextManager: contextManager,
                historyManager: historyManager,
                sudoManager: SudoManager.shared,
                whitelist: CommandWhitelist.shared
            )
            
            let engine = WorkflowExecutionEngine(
                stateManager: stateManager,
                terminalService: terminalService
            )
            // Note: execute method signature may need adjustment
            // await engine.execute(workflow: workflow)
        }
    }
    
    func saveWorkflow() {
        workflow = VisualWorkflow(nodes: nodes, connections: connections)
        // Save to storage
    }
    
    func clearCanvas() {
        nodes.removeAll()
        connections.removeAll()
    }
}

