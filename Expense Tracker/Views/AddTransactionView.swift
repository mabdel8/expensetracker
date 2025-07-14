//
//  AddTransactionView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData
import Foundation


struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = TransactionType.expense
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var selectedFrequency: RecurrenceFrequency = RecurrenceFrequency.monthly
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    @EnvironmentObject private var categoryManager: CategoryManager
    
    var availableCategories: [Category] {
        categoryManager.categories.filter { $0.transactionType == selectedType }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Main content
                ScrollView {
                    VStack(spacing: 16) {
                        // Type Selector Card
                        typeSelector
                        
                        // Amount and Description Card
                        amountAndDescriptionCard
                        
                        // Category Card
                        categoryCard
                        
                        // Date Card
                        dateCard
                        
                        // Notes Card
                        notesCard
                        
                        // Recurring Subscription Card
                        if selectedType == .expense {
                            recurringCard
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
                
                // Save and Cancel buttons
                bottomButtons
            }
            .navigationBarHidden(true)
            .background(Color.white)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isAmountFocused {
                        Spacer()
                        Button("Done") {
                            isAmountFocused = false
                        }
                        .foregroundColor(Color(hex: "219EBC") ?? .blue)
                    }
                }
            }
        }
    }
    
    private var canSave: Bool {
        !name.isEmpty && !amount.isEmpty && selectedCategory != nil
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
            }
            
            Spacer()
            
            Text("Add Transaction")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            Spacer()
            
            // Placeholder for right side
            Color.clear
                .frame(width: 30, height: 30)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 10)
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Type")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            HStack(spacing: 12) {
                Button(action: { 
                    selectedType = .income 
                    selectedCategory = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Income")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(selectedType == .income ? Color(hex: "219EBC") ?? .blue : Color.gray.opacity(0.1))
                    .foregroundColor(selectedType == .income ? .white : Color(hex: "023047") ?? .blue)
                    .cornerRadius(12)
                }
                
                Button(action: { 
                    selectedType = .expense 
                    selectedCategory = nil
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 16, weight: .medium))
                        Text("Expense")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(selectedType == .expense ? Color(hex: "FB8500") ?? .orange : Color.gray.opacity(0.1))
                    .foregroundColor(selectedType == .expense ? .white : Color(hex: "023047") ?? .blue)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private var amountAndDescriptionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Details")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isAmountFocused ? Color(hex: "219EBC") ?? .blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                
                TextField("Enter description", text: $name)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFocused = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNameFocused ? Color(hex: "219EBC") ?? .blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(availableCategories, id: \.name) { category in
                        Button(action: {
                            selectedCategory = category
                        }) {
                            VStack(spacing: 8) {
                                CategoryIconView(category: category, size: 50)
                                
                                Text(category.name)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(Color(hex: "023047") ?? .blue)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 80, height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedCategory?.name == category.name ? (selectedType == .income ? Color(hex: "219EBC") ?? .blue : Color(hex: "FB8500") ?? .orange).opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCategory?.name == category.name ? (selectedType == .income ? Color(hex: "219EBC") ?? .blue : Color(hex: "FB8500") ?? .orange) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
    }
    
    private var dateCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: "219EBC") ?? .blue)
                    .font(.system(size: 20))
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(Color(hex: "219EBC") ?? .blue)
                    .font(.body)
                
                Spacer()
            }
        }
    }
    
    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            TextField("Add additional details...", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    private var recurringCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recurring Subscription")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            // Recurring Toggle
            HStack {
                Toggle("Make this a recurring subscription", isOn: $isRecurring)
                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "219EBC") ?? .blue))
                    .font(.body)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
            }
            .padding(.vertical, 8)
            
            // Frequency Picker (only visible when recurring is enabled)
            if isRecurring {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Frequency")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .animation(.easeInOut(duration: 0.2), value: isRecurring)
                
                // Next Payment Date Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Next Payment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color(hex: "023047") ?? .blue)
                    
                    Text(formatNextPaymentDate())
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button("Cancel") {
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.gray.opacity(0.1))
            .foregroundColor(Color(hex: "023047") ?? .blue)
            .cornerRadius(16)
            
            Button("Save") {
                saveTransaction()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canSave ? Color(hex: "219EBC") ?? .blue : Color.gray.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(16)
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 50)
    }
    
    private func formatNextPaymentDate() -> String {
        let nextDate = RecurringSubscription.calculateNextDueDate(from: date, frequency: selectedFrequency)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextDate)
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        if isRecurring && selectedType == .expense {
            // Create a recurring subscription
            let recurringSubscription = RecurringSubscription(
                name: name.isEmpty ? selectedCategory?.name ?? "Subscription" : name,
                amount: amountValue,
                frequency: selectedFrequency,
                startDate: date,
                type: selectedType,
                category: selectedCategory,
                notes: notes.isEmpty ? nil : notes
            )
            
            modelContext.insert(recurringSubscription)
            
            // Create the initial transaction
            let initialTransaction = recurringSubscription.createTransaction()
            modelContext.insert(initialTransaction)
            
        } else {
            // Create a regular transaction
            let transaction = Transaction(
                name: name.isEmpty ? selectedCategory?.name ?? "Transaction" : name,
                date: date,
                amount: amountValue,
                notes: notes.isEmpty ? nil : notes,
                type: selectedType,
                category: selectedCategory
            )
            
            modelContext.insert(transaction)
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving transaction: \(error)")
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, MonthlyBudget.self, CategoryBudget.self, RecurringSubscription.self], inMemory: true)
} 
