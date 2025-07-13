//
//  AddTransactionView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedCategory: Category?
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var selectedFrequency: RecurrenceFrequency = .monthly
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    @Query private var categories: [Category]
    
    var availableCategories: [Category] {
        categories.filter { $0.transactionType == selectedType }
    }
    
    // Color scheme based on the provided image
    private let lightBlue = Color(red: 0.56, green: 0.79, blue: 0.90) // #8ECAE6
    private let teal = Color(red: 0.13, green: 0.62, blue: 0.74) // #219EBC
    private let darkTeal = Color(red: 0.01, green: 0.19, blue: 0.28) // #023047
    private let yellow = Color(red: 1.0, green: 0.72, blue: 0.02) // #FFB703
    private let orange = Color(red: 0.98, green: 0.52, blue: 0.0) // #FB8500
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Type Selector
                        typeSelector
                        
                        // Amount Section
                        amountSection
                        
                        // Category Section
                        categorySection
                        
                        // Date Section
                        dateSection
                        
                        // Notes Section
                        notesSection
                        
                        // Recurring Subscription Section
                        if selectedType == .expense {
                            recurringSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
                
                // Save and Cancel buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(16)
                    
                    Button("Save") {
                        saveTransaction()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(canSave ? teal : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    if isAmountFocused {
                        Spacer()
                        Button("Done") {
                            isAmountFocused = false
                        }
                        .foregroundColor(teal)
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
                    .foregroundColor(darkTeal)
            }
            
            Spacer()
            
            Text("Add Transaction")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
            Spacer()
            
            // Placeholder for right side (matching image layout)
            Color.clear
                .frame(width: 30, height: 30)
        }
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transaction Type")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
            HStack(spacing: 12) {
                Button(action: { 
                    selectedType = .income 
                    selectedCategory = nil // Reset category when type changes
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
                    .background(selectedType == .income ? teal : lightBlue.opacity(0.3))
                    .foregroundColor(selectedType == .income ? .white : darkTeal)
                    .cornerRadius(24)
                }
                
                Button(action: { 
                    selectedType = .expense 
                    selectedCategory = nil // Reset category when type changes
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
                    .background(selectedType == .expense ? orange : lightBlue.opacity(0.3))
                    .foregroundColor(selectedType == .expense ? .white : darkTeal)
                    .cornerRadius(24)
                }
            }
        }
    }
    
    private var amountSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(darkTeal)
                
                HStack {
                    Text("$")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(darkTeal)
                    
                    TextField("0.00", text: $amount)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(darkTeal)
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isAmountFocused ? teal : Color.clear, lineWidth: 2)
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(darkTeal)
                
                TextField("Enter description", text: $name)
                    .focused($isNameFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isNameFocused = false
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isNameFocused ? teal : Color.clear, lineWidth: 2)
                    )
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
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
                                    .foregroundColor(darkTeal)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 80, height: 90)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedCategory?.name == category.name ? (selectedType == .income ? teal : orange).opacity(0.1) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedCategory?.name == category.name ? (selectedType == .income ? teal : orange) : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollClipDisabled()
        }
        .padding(.vertical, 8)
    }
    
    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pick a date")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(teal)
                    .font(.system(size: 20))
                
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(CompactDatePickerStyle())
                    .accentColor(teal)
                    .font(.body)
                
                Spacer()
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
            TextField("Add additional details...", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
        }
        .padding(.bottom, 20)
    }
    
    private var recurringSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recurring Subscription")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(darkTeal)
            
            // Recurring Toggle
            HStack {
                Toggle("Make this a recurring subscription", isOn: $isRecurring)
                    .toggleStyle(SwitchToggleStyle(tint: teal))
                    .font(.body)
                    .foregroundColor(darkTeal)
            }
            .padding(.vertical, 8)
            
            // Frequency Picker (only visible when recurring is enabled)
            if isRecurring {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frequency")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(darkTeal)
                    
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .background(lightBlue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 8)
                .animation(.easeInOut(duration: 0.2), value: isRecurring)
                
                // Next Payment Date Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Payment")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(darkTeal)
                    
                    Text(formatNextPaymentDate())
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding(.bottom, 20)
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
        .modelContainer(for: [Transaction.self, Category.self, Budget.self, RecurringSubscription.self], inMemory: true)
} 
