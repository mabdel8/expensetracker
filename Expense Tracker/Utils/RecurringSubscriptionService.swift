//
//  RecurringSubscriptionService.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import Foundation
import SwiftData

class RecurringSubscriptionService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Process all due recurring subscriptions and create transactions for them
    func processDueSubscriptions() {
        let currentDate = Date()
        let descriptor = FetchDescriptor<RecurringSubscription>(
            predicate: #Predicate<RecurringSubscription> { subscription in
                subscription.isActive && subscription.nextDueDate <= currentDate
            }
        )
        
        do {
            let dueSubscriptions = try modelContext.fetch(descriptor)
            
            for subscription in dueSubscriptions {
                createTransactionForSubscription(subscription)
            }
            
            // Save all changes
            try modelContext.save()
            
        } catch {
            print("Error processing due subscriptions: \(error)")
        }
    }
    
    /// Create a transaction for a specific recurring subscription
    private func createTransactionForSubscription(_ subscription: RecurringSubscription) {
        let transaction = subscription.createTransaction()
        modelContext.insert(transaction)
    }
    
    /// Check if there are any due subscriptions
    func hasDueSubscriptions() -> Bool {
        let currentDate = Date()
        let descriptor = FetchDescriptor<RecurringSubscription>(
            predicate: #Predicate<RecurringSubscription> { subscription in
                subscription.isActive && subscription.nextDueDate <= currentDate
            }
        )
        
        do {
            let dueSubscriptions = try modelContext.fetch(descriptor)
            return !dueSubscriptions.isEmpty
        } catch {
            print("Error checking for due subscriptions: \(error)")
            return false
        }
    }
    
    /// Get count of due subscriptions
    func getDueSubscriptionsCount() -> Int {
        let currentDate = Date()
        let descriptor = FetchDescriptor<RecurringSubscription>(
            predicate: #Predicate<RecurringSubscription> { subscription in
                subscription.isActive && subscription.nextDueDate <= currentDate
            }
        )
        
        do {
            let dueSubscriptions = try modelContext.fetch(descriptor)
            return dueSubscriptions.count
        } catch {
            print("Error getting due subscriptions count: \(error)")
            return 0
        }
    }
    
    /// Get all due subscriptions
    func getDueSubscriptions() -> [RecurringSubscription] {
        let currentDate = Date()
        let descriptor = FetchDescriptor<RecurringSubscription>(
            predicate: #Predicate<RecurringSubscription> { subscription in
                subscription.isActive && subscription.nextDueDate <= currentDate
            }
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Error getting due subscriptions: \(error)")
            return []
        }
    }
} 