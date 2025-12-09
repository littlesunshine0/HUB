//
//  OperationDAG.swift
//  Hub
//
//  Directed Acyclic Graph for operation workflows
//

import Foundation

// MARK: - Operation DAG

public struct OperationDAG {
    public let name: String
    public let description: String
    public let nodes: [DAGNode]
    
    public init(name: String, description: String, nodes: [DAGNode]) {
        self.name = name
        self.description = description
        self.nodes = nodes
    }
    
    /// Get execution order based on dependencies
    public func executionOrder() -> [DAGNode] {
        var ordered: [DAGNode] = []
        var visited: Set<String> = []
        
        func visit(_ nodeId: String) {
            guard !visited.contains(nodeId) else { return }
            visited.insert(nodeId)
            
            if let node = nodes.first(where: { $0.id == nodeId }) {
                // Visit dependencies first
                for dep in node.dependencies {
                    visit(dep)
                }
                ordered.append(node)
            }
        }
        
        // Visit all nodes
        for node in nodes {
            visit(node.id)
        }
        
        return ordered
    }
    
    /// Validate DAG has no cycles
    public func validate() -> Bool {
        var visiting: Set<String> = []
        var visited: Set<String> = []
        
        func hasCycle(_ nodeId: String) -> Bool {
            if visiting.contains(nodeId) { return true }
            if visited.contains(nodeId) { return false }
            
            visiting.insert(nodeId)
            
            if let node = nodes.first(where: { $0.id == nodeId }) {
                for dep in node.dependencies {
                    if hasCycle(dep) { return true }
                }
            }
            
            visiting.remove(nodeId)
            visited.insert(nodeId)
            return false
        }
        
        for node in nodes {
            if hasCycle(node.id) { return false }
        }
        
        return true
    }
}

// MARK: - DAG Node

public struct DAGNode {
    public let id: String
    public let operation: any RawRepresentable
    public let dependencies: [String]
    
    public init(id: String, operation: any RawRepresentable, dependencies: [String]) {
        self.id = id
        self.operation = operation
        self.dependencies = dependencies
    }
}
