//
//  RecurringSubscriptionsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct RecurringSubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var recurringSubscriptions: [RecurringSubscription]
    
    // Color scheme
    private let lightBlue = Color(red: 0.56, green: 0.79, blue: 0.90) // #8ECAE6
    private let teal = Color(red: 0.13, green: 0.62, blue: 0.74) // #219EBC
    private let darkTeal = Color(red: 0.01, green: 0.19, blue: 0.28) // #023047
    private let orange = Color(red: 0.98, green: 0.52, blue: 0.0) // #FB8500
    
    var body: some View {
        NavigationView {
            VStack {
                if recurringSubscriptions.isEmpty {
                    emptyState
                } else {
                    subscriptionsList
                }
            }
            .navigationTitle("Recurring Subscriptions")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Recurring Subscriptions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add recurring subscriptions when creating expense transactions to automatically track your regular payments.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
    }
    
    private var subscriptionsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(activeSubscriptions, id: \.name) { subscription in
                    RecurringSubscriptionRow(subscription: subscription)
                }
                
                if !inactiveSubscriptions.isEmpty {
                    Section {
                        ForEach(inactiveSubscriptions, id: \.name) { subscription in
                            RecurringSubscriptionRow(subscription: subscription)
                        }
                    } header: {
                        HStack {
                            Text("Inactive Subscriptions")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 20)
        }
    }
    
    private var activeSubscriptions: [RecurringSubscription] {
        recurringSubscriptions.filter { $0.isActive }
    }
    
    private var inactiveSubscriptions: [RecurringSubscription] {
        recurringSubscriptions.filter { !$0.isActive }
    }
}

struct RecurringSubscriptionRow: View {
    let subscription: RecurringSubscription
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    @State private var showingEditOptions = false
    
    // Color scheme
    private let lightBlue = Color(red: 0.56, green: 0.79, blue: 0.90) // #8ECAE6
    private let teal = Color(red: 0.13, green: 0.62, blue: 0.74) // #219EBC
    private let darkTeal = Color(red: 0.01, green: 0.19, blue: 0.28) // #023047
    private let orange = Color(red: 0.98, green: 0.52, blue: 0.0) // #FB8500
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Category icon
                CategoryIconView(category: subscription.category, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(subscription.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(darkTeal)
                    
                    Text(subscription.category?.name ?? "No Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Text(subscription.frequency.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(subscription.isActive ? "Active" : "Inactive")
                            .font(.caption)
                            .foregroundColor(subscription.isActive ? .green : .orange)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(subscription.displayAmount)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(subscription.type == .expense ? .red : .green)
                    
                    if subscription.isActive {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Next:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(formatDate(subscription.nextDueDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .onTapGesture {
            // Show action sheet for editing
            showingEditOptions = true
        }
        .actionSheet(isPresented: $showingEditOptions) {
            ActionSheet(
                title: Text("Edit Subscription"),
                message: Text(subscription.name),
                buttons: [
                    .default(Text(subscription.isActive ? "Pause Subscription" : "Resume Subscription")) {
                        toggleActive()
                    },
                    .destructive(Text("Delete Subscription")) {
                        showingDeleteConfirmation = true
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Subscription", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteSubscription()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this recurring subscription? This action cannot be undone.")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func toggleActive() {
        subscription.isActive.toggle()
        
        do {
            try modelContext.save()
        } catch {
            print("Error toggling subscription active state: \(error)")
        }
    }
    
    private func deleteSubscription() {
        modelContext.delete(subscription)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting subscription: \(error)")
        }
    }
}

#Preview {
    RecurringSubscriptionsView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 