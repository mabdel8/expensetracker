Expense Tracker SwiftUI App: Requirements Document
1. High-Level Summary
This document outlines the features, workflow, and technical architecture for a modern, user-friendly expense tracker application built with SwiftUI. The app will allow users to easily log, categorize, and analyze their spending to improve their financial habits. The primary goal is to provide a clean, intuitive interface that makes expense tracking effortless.

2. Core Features
2.1. Expense Management (CRUD)
Add Transaction: Users must be able to quickly add a new transaction (either an expense or income). The entry should include:

Amount (Decimal)

Name/Title (String)

Type (Expense or Income)

Category (Link to Category Model)

Date & Time (Timestamp)

Optional Notes (String)

View Transactions: A list of all transactions, sortable and filterable.

Edit Transaction: Users can select any existing transaction to modify its details.

Delete Transaction: Users can delete a transaction, with a confirmation prompt.

2.2. Category Management
Default Categories: The app will ship with pre-defined sets of common categories for both expenses (e.g., Food, Transport, Shopping) and income (e.g., Salary, Freelance, Investment).

Custom Categories: Users can add their own custom categories for both types. Each category should have:

Name (String)

Icon/Symbol (e.g., SF Symbol name)

Color

Edit/Delete Categories: Users can manage their custom categories.

2.3. Budgeting
Set Budgets: Users can set monthly or weekly budgets on a per-category basis for expenses.

Track Budget Progress: The app will visualize how much of a budget has been spent.

Budget Alerts: (Optional - v1.1) Notify the user when they are approaching or have exceeded a budget limit.

2.4. Data Visualization & Reports
Dashboard/Summary View: The main screen will display a summary of spending and income.

Spending by Category: A pie or bar chart showing the distribution of expenses.

Historical Trends: A line chart showing spending/income trends over time.

2.5. Data Persistence & Sync
Local Persistence: All data will be stored locally on the device using SwiftData.

iCloud Sync: Data will automatically sync across a user's iCloud-connected devices.

3. Application Architecture
Pattern: The app will be built using the MVVM (Model-View-ViewModel) architecture.

Model: Transaction, Category, Budget managed by SwiftData.

View: SwiftUI views for UI.

ViewModel: Logic to bridge the Model and View.

Modularity: The codebase will be organized into logical folders for Models, Views, ViewModels, etc.

4. Data Models (SwiftData)
// Note: This is a conceptual representation for the requirements.
// The 'Expense' model is now a more generic 'Transaction' model.

enum TransactionType: String, Codable {
    case income
    case expense
}

@Model
class Transaction {
    var name: String
    var date: Date
    var amount: Double
    var notes: String?
    var type: TransactionType // To distinguish between income and expense
    
    // Relationship: A transaction belongs to one category
    @Relationship(inverse: \Category.transactions)
    var category: Category?
    
    init(name: String, date: Date, amount: Double, notes: String? = nil, type: TransactionType, category: Category? = nil) {
        self.name = name
        self.date = date
        self.amount = amount
        self.notes = notes
        self.type = type
        self.category = category
    }
}

@Model
class Category {
    @Attribute(.unique)
    var name: String
    var iconName: String // SF Symbol name
    var colorHex: String // Store color as a hex string
    var transactionType: TransactionType // Is this an income or expense category?
    
    // Relationship: A category can have many transactions
    @Relationship(deleteRule: .cascade)
    var transactions: [Transaction]? = []
    
    init(name: String, iconName: String, colorHex: String, transactionType: TransactionType) {
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.transactionType = transactionType
    }
}

@Model
class Budget {
    var amount: Double
    var startDate: Date
    var endDate: Date
    
    // Budget is tied to a specific expense category
    var category: Category?
    
    init(amount: Double, startDate: Date, endDate: Date, category: Category?) {
        self.amount = amount
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
    }
}

5. UI/UX Workflow
5.1 Onboarding Workflow
Purpose: To provide a simple and welcoming introduction for first-time users. This flow will run only once when the app is first launched.

Screen 0.1: Welcome Screen

Layout: A clean, centered layout.

Components: A large, prominent button with the text "Continue".

Action: Tapping "Continue" navigates to the next onboarding screen.

Screen 0.2: Get Started Screen

Layout: Similar clean, centered layout.

Components: A large, prominent button with the text "Begin".

Action: Tapping "Begin" dismisses the onboarding flow and takes the user to the main Dashboard / Home View. The app must remember that the user has completed onboarding so it doesn't show again.

5.2 Main Application Workflow
Screen 1: Dashboard / Home View (Detailed)
Overall Layout: A vertically scrolling view with distinct modular cards.

Header Bar:

At the very top of the screen is a navigation bar.

It contains a "Settings" icon/button on the top right.

It features two distinct buttons for adding transactions: one for "+ Income" and one for "- Expense".

Component 1: Calendar View

A monthly calendar is displayed below the header.

Each day cell shows a summary of total income (+) and total expenses (-) for that day.

The current day is highlighted.

Component 2: Monthly Summary Card

Below the calendar, a card displays the total income and total expense for the currently selected month.

This card is horizontally swipeable. Swiping left or right navigates to the previous or next month, and all data on the Home View updates accordingly.

Component 3: Breakdown Card (Swipeable)

This is a horizontally swipeable card container.

Initial View (Expense Breakdown): Shows a breakdown of expenses by category for the selected month.

Swiped View (Income Breakdown): Swiping the card reveals the Income Breakdown by category.

Component 4: Daily Transactions List

The bottom section lists all transactions for the selected month, grouped by day.

Each day is a collapsible header showing the date and the day's total income and expense.

Under each header, individual transaction items are listed.

Screen 2: Add/Edit Transaction View
Components:

A segmented control to select "Income" or "Expense".

A number pad/field for the amount.

A text field for the name.

A picker/sheet to select a category (the list of categories will update based on the selected transaction type).

A date picker for the date.

A text editor for optional notes.

A "Save" button.

Screen 3: Reports View
Components:

A segmented control for time periods (Week, Month, Year).

A pie chart showing expense distribution by category.

A list of categories below the chart with their totals.

Screen 4: Settings / Categories View
Components:

A section for managing categories (both income and expense).

A section for managing budgets.

(Future) App settings like currency, appearance, etc.

6. Future Enhancements (Post v1.0)
Receipt Scanning

Recurring Transactions

Advanced Filtering

Multi-Currency Support

Export to CSV

Widgets
