//
//  AddEditAccountView.swift
//  Expense Tracker
//
//  Created by Mohamed Abdelmagid on 7/9/25.
//

import SwiftUI
import SwiftData

struct AddEditAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountName = ""
    @State private var selectedAccountType: AccountType = .debitCard
    @State private var selectedColor = "219EBC"
    @State private var lastFourDigits = ""
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDigitsFocused: Bool
    
    let account: Account?
    
    // Color options
    private let colorOptions = [
        "219EBC", // Teal
        "FB8500", // Orange
        "023047", // Dark Teal
        "58D68D", // Green
        "5DADE2", // Blue
        "F7DC6F", // Yellow
        "AF7AC5", // Purple
        "FF6B6B", // Red
        "4ECDC4", // Mint
        "85C1E9"  // Light Blue
    ]
    
    init(account: Account? = nil) {
        self.account = account
        if let account = account {
            _accountName = State(initialValue: account.name)
            _selectedAccountType = State(initialValue: account.accountType)
            _selectedColor = State(initialValue: account.colorHex)
            _lastFourDigits = State(initialValue: account.lastFourDigits ?? "")
        }
    }
    
    var isEditing: Bool {
        account != nil
    }
    
    var canSave: Bool {
        !accountName.isEmpty && (lastFourDigits.isEmpty || lastFourDigits.count == 4)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerSection
                
                // Content
                ScrollView {
                    VStack(spacing: 20) {
                        // Account Name Card
                        accountNameCard
                        
                        // Account Type Card
                        accountTypeCard
                        
                        // Color Selection Card
                        colorSelectionCard
                        
                        // Last Four Digits Card
                        lastFourDigitsCard
                        
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
        }
    }
    
    private var headerSection: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
            }
            
            Spacer()
            
            Text(isEditing ? "Edit Account" : "Add Account")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            Spacer()
            
            // Invisible view to balance the close button
            Image(systemName: "xmark")
                .font(.title2)
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 20)
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
    
    private var accountNameCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Name")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            TextField("Enter account name", text: $accountName)
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
    
    private var accountTypeCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Type")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            VStack(spacing: 12) {
                ForEach(AccountType.allCases, id: \.self) { type in
                    accountTypeButton(for: type)
                }
            }
        }
    }
    
    private func accountTypeButton(for type: AccountType) -> some View {
        let isSelected = selectedAccountType == type
        let selectedColorValue = Color(hex: selectedColor) ?? Color(hex: "219EBC") ?? .blue
        let darkTeal = Color(hex: "023047") ?? .blue
        
        return Button(action: {
            selectedAccountType = type
        }) {
            HStack(spacing: 12) {
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : darkTeal)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? selectedColorValue : Color.clear)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                    )
                
                Text(type.displayName)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(darkTeal)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body)
                        .foregroundColor(selectedColorValue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? selectedColorValue.opacity(0.1) : Color.clear)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? selectedColorValue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var colorSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                ForEach(colorOptions, id: \.self) { color in
                    Button(action: {
                        selectedColor = color
                    }) {
                        Circle()
                            .fill(Color(hex: color) ?? .blue)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.black : Color.clear, lineWidth: 2)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    private var lastFourDigitsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last Four Digits (Optional)")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: "023047") ?? .blue)
            
            TextField("1234", text: $lastFourDigits)
                .keyboardType(.numberPad)
                .focused($isDigitsFocused)
                .onChange(of: lastFourDigits) { _, newValue in
                    // Limit to 4 digits
                    if newValue.count > 4 {
                        lastFourDigits = String(newValue.prefix(4))
                    }
                    // Only allow numbers
                    lastFourDigits = newValue.filter { $0.isNumber }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDigitsFocused ? Color(hex: "219EBC") ?? .blue : Color.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text("This helps identify the account if you have multiple of the same type.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var bottomButtons: some View {
        HStack(spacing: 16) {
            Button(action: {
                dismiss()
            }) {
                Text("Cancel")
                    .font(.headline)
                    .foregroundColor(Color(hex: "023047") ?? .blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.clear)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "023047") ?? .blue, lineWidth: 1)
                    )
            }
            
            Button(action: {
                saveAccount()
            }) {
                Text(isEditing ? "Update" : "Save")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSave ? Color(hex: "219EBC") ?? .blue : Color.gray)
                    .cornerRadius(12)
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
    }
    
    private func saveAccount() {
        if let existingAccount = account {
            // Update existing account
            existingAccount.name = accountName
            existingAccount.accountType = selectedAccountType
            existingAccount.colorHex = selectedColor
            existingAccount.lastFourDigits = lastFourDigits.isEmpty ? nil : lastFourDigits
        } else {
            // Create new account
            let newAccount = Account(
                name: accountName,
                accountType: selectedAccountType,
                colorHex: selectedColor,
                lastFourDigits: lastFourDigits.isEmpty ? nil : lastFourDigits
            )
            modelContext.insert(newAccount)
        }
        
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddEditAccountView()
        .modelContainer(for: [Account.self], inMemory: true)
} 