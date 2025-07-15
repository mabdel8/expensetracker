//
//  AccountsView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Query private var transactions: [Transaction]
    @EnvironmentObject private var categoryManager: CategoryManager
    
    @State private var showingAddAccount = false
    @State private var selectedAccount: Account?
    @State private var showingEditAccount = false
    @State private var showingDeleteAlert = false
    @State private var accountToDelete: Account?
    
    // Color scheme
    private let darkTeal = Color(hex: "023047") ?? .blue
    private let teal = Color(hex: "219EBC") ?? .blue
    private let orange = Color(hex: "FB8500") ?? .orange
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                if accounts.isEmpty {
                    emptyState
                } else {
                    accountsList
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddAccount) {
                AddEditAccountView()
            }
            .sheet(isPresented: $showingEditAccount) {
                if let account = selectedAccount {
                    AddEditAccountView(account: account)
                }
            }
            .alert("Delete Account", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let account = accountToDelete {
                        deleteAccount(account)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this account? This action cannot be undone.")
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Accounts")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(darkTeal)
            
            Spacer()
            
            Button(action: {
                showingAddAccount = true
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(darkTeal)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 60)
        .padding(.bottom, 30)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "creditcard.fill")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("No Accounts Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Add your first account to start tracking transactions by payment method.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: {
                showingAddAccount = true
            }) {
                Text("Add Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(teal)
                    .cornerRadius(25)
            }
            
            Spacer()
        }
    }
    
    private var accountsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(accounts.enumerated()), id: \.element.name) { index, account in
                    AccountCard(
                        account: account,
                        onEdit: {
                            selectedAccount = account
                            showingEditAccount = true
                        },
                        onDelete: {
                            accountToDelete = account
                            showingDeleteAlert = true
                        }
                    )
                    .padding(.top, index == 0 ? 10 : 0)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
    }
    
    private func deleteAccount(_ account: Account) {
        withAnimation {
            modelContext.delete(account)
            try? modelContext.save()
        }
    }
}

struct AccountCard: View {
    let account: Account
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @Query private var transactions: [Transaction]
    @State private var isExpanded = true
    @State private var showingEditOptions = false
    
    private var accountTransactions: [Transaction] {
        transactions.filter { $0.account?.name == account.name }
    }
    
    private var recentTransactions: [Transaction] {
        Array(accountTransactions.sorted { $0.date > $1.date }.prefix(3))
    }
    
    private let darkTeal = Color(hex: "023047") ?? .blue
    private let teal = Color(hex: "219EBC") ?? .blue
    private let orange = Color(hex: "FB8500") ?? .orange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Account Header
            HStack {
                // Account Icon and Info
                HStack(spacing: 12) {
                    Image(systemName: account.accountType.iconName)
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(hex: account.colorHex) ?? teal)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(darkTeal)
                        
                        Text(account.accountType.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Balance
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(account.formattedBalance)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(account.totalBalance >= 0 ? .green : .red)
                }
                
                // Chevron button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
            }
            
            // Recent Transactions
            if !recentTransactions.isEmpty && isExpanded {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Recent Transactions")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(darkTeal)
                        
                        Spacer()
                        
                        if accountTransactions.count > 3 {
                            Text("+ \(accountTransactions.count - 3) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    // Transactions List
                    VStack(spacing: 0) {
                        ForEach(Array(recentTransactions.enumerated()), id: \.offset) { index, transaction in
                            AccountRecentTransactionRow(
                                transaction: transaction,
                                isLast: index == recentTransactions.count - 1
                            )
                        }
                    }
                }
            }
            
            // Action Buttons
            HStack {
                Button(action: {
                    showingEditOptions = true
                }) {
                    HStack {
                        Image(systemName: "ellipsis")
                            .font(.caption)
                        Text("Options")
                            .font(.caption)
                    }
                    .foregroundColor(teal)
                }
                
                Spacer()
                
                Text("\(accountTransactions.count) transactions")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .confirmationDialog("Account Options", isPresented: $showingEditOptions) {
            Button("Edit Info") {
                onEdit()
            }
            Button("Delete Account", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

struct AccountRecentTransactionRow: View {
    let transaction: Transaction
    let isLast: Bool
    
    private let darkTeal = Color(hex: "023047") ?? .blue
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Category icon
                CategoryIconView(category: transaction.category, size: 32)
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.name)
                            .font(.body)
                            .fontWeight(.regular)
                            .lineLimit(1)
                        Text(transaction.category?.name ?? "Uncategorized")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        HStack(spacing: 6) {
                            // Show recurring tag for recurring transactions
                            if transaction.isRecurring {
                                HStack(spacing: 4) {
                                    Text("recurring")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(darkTeal)
                                .clipShape(Capsule())
                            }
                            
                            Text(transaction.displayAmount)
                                .font(.body)
                                .fontWeight(.light)
                                .foregroundColor(transaction.type == .expense ? .red : .green)
                        }
                        Text(formatDateFull(transaction.date))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    if let notes = transaction.notes, !notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(.leading, 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)
            .padding(.bottom, 8)
            
            if !isLast {
                Divider()
                    .padding(.horizontal, 12)
            }
        }
    }
    
    private func formatDateFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: [Account.self, Transaction.self], inMemory: true)
} 
