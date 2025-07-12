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
    @FocusState private var isAmountFocused: Bool
    @FocusState private var isNameFocused: Bool
    
    @Query private var categories: [Category]
    
    var availableCategories: [Category] {
        categories.filter { $0.transactionType == selectedType }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                
                // Main content
                VStack(spacing: 16) {
                    // Type Selector
                    typeSelector
                    
                    // Amount Section
                    amountSection
                    
                    // Category Section
                    categorySection
                    
                    // Category
                    Picker("Category", selection: $selectedCategory) {
                        Text("Select Category").tag(nil as Category?)
                        ForEach(availableCategories, id: \.name) { category in
                            HStack {
                                CategoryIconView(category: category, size: 20)
                                Text(category.name)
                            }
                            .tag(category as Category?)
                        }
                    }
                    
                    // Date
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    
                    // Notes Section
                    notesSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                
                Spacer()
                
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
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .disabled(name.isEmpty || amount.isEmpty || selectedCategory == nil)
                    .opacity((name.isEmpty || amount.isEmpty || selectedCategory == nil) ? 0.5 : 1)
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
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text("Add transaction")
                .font(.headline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Placeholder for right side (matching image layout)
            Color.clear
                .frame(width: 30, height: 30)
        }
    }
    
    private var typeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose")
                .font(.headline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                Button(action: { selectedType = .income }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16))
                        Text("Income")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(selectedType == .income ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(selectedType == .income ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(selectedType == .income ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(22)
                }
                
                Button(action: { selectedType = .expense }) {
                    HStack {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 16))
                        Text("Expense")
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(selectedType == .expense ? Color.blue : Color.gray.opacity(0.1))
                    .foregroundColor(selectedType == .expense ? .white : .primary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(selectedType == .expense ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(22)
                }
            }
        }
    }
    
    private var amountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Amount")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Enter amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Name")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    TextField("Enter name", text: $name)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            isNameFocused = false
                        }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.headline)
                .fontWeight(.medium)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(availableCategories, id: \.name) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory?.name == category.name,
                            action: { selectedCategory = category }
                        )
                    }
                    
                    // Custom category button
                    Button(action: {
                        // Handle custom category - for now just show placeholder
                    }) {
                        VStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.gray)
                            Text("Custom")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 70, height: 70)
                        .background(Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var dateTimeSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Date")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    DatePicker("", selection: $date, displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Time")
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.gray)
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.headline)
                .fontWeight(.medium)
            
            TextField("Add details", text: $notes, axis: .vertical)
                .lineLimit(2...3)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        let transaction = Transaction(
            name: name.isEmpty ? selectedCategory?.name ?? "Transaction" : name,
            date: date,
            amount: amountValue,
            notes: notes.isEmpty ? nil : notes,
            type: selectedType,
            category: selectedCategory
        )
        
        modelContext.insert(transaction)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving transaction: \(error)")
        }
    }
}

struct CategoryButton: View {
    let category: Category
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(category.name)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 70, height: 70)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, Budget.self], inMemory: true)
} 