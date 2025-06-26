import SwiftUI

// MARK: - Note Model
struct Note: Identifiable, Codable {
    let id = UUID()
    var title: String
    var content: String
    var dateCreated: Date
    var dateModified: Date
    var location: String
    var date: Date
    var colorTag: ColorTag
    var customColorHex: String?
    
    init(title: String = "", content: String = "", location: String = "", date: Date = Date(), colorTag: ColorTag = .none, customColorHex: String? = nil) {
        self.title = title
        self.content = content
        self.dateCreated = Date()
        self.dateModified = Date()
        self.location = location
        self.date = date
        self.colorTag = colorTag
        self.customColorHex = customColorHex
    }
    
    mutating func updateContent(title: String, content: String, location: String, date: Date, colorTag: ColorTag, customColorHex: String?) {
        self.title = title
        self.content = content
        self.location = location
        self.date = date
        self.colorTag = colorTag
        self.customColorHex = customColorHex
        self.dateModified = Date()
    }
}

// MARK: - Color Tag Enum
enum ColorTag: String, CaseIterable, Codable {
    case none = "none"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case custom = "custom"
    
    var color: Color {
        switch self {
        case .none:
            return .clear
        case .red:
            return .red
        case .orange:
            return .orange
        case .yellow:
            return .yellow
        case .green:
            return .green
        case .blue:
            return .blue
        case .purple:
            return .purple
        case .pink:
            return .pink
        case .custom:
            return .black
        }
    }
    
    var displayName: String {
        switch self {
        case .none:
            return "No Tag"
        case .red:
            return "Red"
        case .orange:
            return "Orange"
        case .yellow:
            return "Yellow"
        case .green:
            return "Green"
        case .blue:
            return "Blue"
        case .purple:
            return "Purple"
        case .pink:
            return "Pink"
        case .custom:
            return "Custom"
        }
    }
}

// MARK: - Notes Store
class NotesStore: ObservableObject {
    @Published var notes: [Note] = []
    
    private let userDefaults = UserDefaults.standard
    private let notesKey = "SavedNotes"
    
    init() {
        loadNotes()
    }
    
    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        saveNotes()
    }
    
    func deleteNote(at indexSet: IndexSet) {
        notes.remove(atOffsets: indexSet)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            // Move updated note to top
            let updatedNote = notes.remove(at: index)
            notes.insert(updatedNote, at: 0)
            saveNotes()
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            userDefaults.set(encoded, forKey: notesKey)
        }
    }
    
    private func loadNotes() {
        if let data = userDefaults.data(forKey: notesKey),
           let decodedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decodedNotes
        }
    }
}

// MARK: - Main Content View
struct NotesMainView: View {
    @StateObject private var notesStore = NotesStore()
    @State private var showingAddNote = false
    @State private var searchText = ""
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notesStore.notes
        } else {
            return notesStore.notes.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                note.location.localizedCaseInsensitiveContains(searchText) ||
                note.colorTag.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if notesStore.notes.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note, notesStore: notesStore)) {
                                NoteRowView(note: note)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .searchable(text: $searchText, prompt: "Search notes...")
                }
            }
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddNote = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(notesStore: notesStore)
            }
        }
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        // Convert filtered indices to original indices
        let indicesToDelete = IndexSet(offsets.compactMap { offset in
            let noteToDelete = filteredNotes[offset]
            return notesStore.notes.firstIndex(where: { $0.id == noteToDelete.id })
        })
        notesStore.deleteNote(at: indicesToDelete)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "note.text")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Notes Yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Tap the + button to create your first note")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Note Row View
struct NoteRowView: View {
    let note: Note
    
    var displayColor: Color {
        if note.colorTag == .custom, let hex = note.customColorHex, let color = Color(hex: hex) {
            return color
        } else {
            return note.colorTag.color
        }
    }
    
    var body: some View {
        HStack {
            // Color tag indicator
            if note.colorTag != .none {
                Circle()
                    .fill(displayColor)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                if !note.content.isEmpty {
                    Text(note.content)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if !note.location.isEmpty {
                        HStack(spacing: 2) {
                            Image(systemName: "location")
                                .font(.caption2)
                            Text(note.location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(note.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("Modified: \(note.dateModified, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Helper view for color tag button
struct ColorTagButton: View {
    let tag: ColorTag
    let isSelected: Bool
    let customColorHex: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if tag != .none && tag != .custom {
                    Circle()
                        .fill(tag.color)
                        .frame(width: 16, height: 16)
                } else if tag == .custom, let hex = customColorHex, let color = Color(hex: hex) {
                    Circle()
                        .fill(color)
                        .frame(width: 16, height: 16)
                }
                Text(tag.displayName)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Add Note Input Sections
struct NoteTitleSection: View {
    @Binding var title: String
    var isTitleFocused: FocusState<Bool>.Binding
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Title")
                .font(.headline)
                .foregroundColor(.primary)
            TextField("Enter title", text: $title)
                .font(.title2)
                .fontWeight(.semibold)
                .focused(isTitleFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct NoteLocationSection: View {
    @Binding var location: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
            TextField("Enter location", text: $location)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

struct NoteDateSection: View {
    @Binding var date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.headline)
                .foregroundColor(.primary)
            DatePicker("Select date", selection: $date, displayedComponents: .date)
                .datePickerStyle(CompactDatePickerStyle())
        }
    }
}

struct NoteColorTagSection: View {
    @Binding var colorTag: ColorTag
    @Binding var customColor: Color
    @Binding var customColorHex: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color Tag")
                .font(.headline)
                .foregroundColor(.primary)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                ForEach(ColorTag.allCases, id: \.self) { tag in
                    ColorTagButton(
                        tag: tag,
                        isSelected: colorTag == tag,
                        customColorHex: customColorHex,
                        action: { colorTag = tag }
                    )
                }
            }
            if colorTag == .custom {
                ColorPicker("Pick Custom Color", selection: $customColor)
                    .onChange(of: customColor) { newColor in
                        customColorHex = newColor.toHex()
                    }
            }
        }
    }
}

struct NoteContentSection: View {
    @Binding var content: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Content")
                .font(.headline)
                .foregroundColor(.primary)
            TextEditor(text: $content)
                .font(.body)
                .frame(minHeight: 200)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// MARK: - Add Note View
struct AddNoteView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var notesStore: NotesStore
    
    @State private var title = ""
    @State private var content = ""
    @State private var location = ""
    @State private var date = Date()
    @State private var colorTag: ColorTag = .none
    @State private var customColorHex: String?
    @FocusState private var isTitleFocused: Bool
    @State private var customColor: Color = .black
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        NoteTitleSection(title: $title, isTitleFocused: $isTitleFocused)
                        NoteLocationSection(location: $location)
                        NoteDateSection(date: $date)
                        NoteColorTagSection(colorTag: $colorTag, customColor: $customColor, customColorHex: $customColorHex)
                        NoteContentSection(content: $content)
                    }
                    .padding()
                }
            }
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            isTitleFocused = true
            if let hex = customColorHex, let color = Color(hex: hex) {
                customColor = color
            }
        }
    }
    
    private func saveNote() {
        let hex = colorTag == .custom ? customColor.toHex() : nil
        let newNote = Note(title: title, content: content, location: location, date: date, colorTag: colorTag, customColorHex: hex)
        notesStore.addNote(newNote)
        dismiss()
    }
}

// MARK: - Note Detail View
struct NoteDetailView: View {
    @State var note: Note
    @ObservedObject var notesStore: NotesStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedLocation: String
    @State private var editedDate: Date
    @State private var editedColorTag: ColorTag
    @State private var editedCustomColorHex: String?
    @State private var editedCustomColor: Color = .black
    
    init(note: Note, notesStore: NotesStore) {
        self._note = State(initialValue: note)
        self.notesStore = notesStore 
        self._editedTitle = State(initialValue: note.title)
        self._editedContent = State(initialValue: note.content)
        self._editedLocation = State(initialValue: note.location)
        self._editedDate = State(initialValue: note.date)
        self._editedColorTag = State(initialValue: note.colorTag)
        self._editedCustomColorHex = State(initialValue: note.customColorHex)
        if let hex = note.customColorHex, let color = Color(hex: hex) {
            self._editedCustomColor = State(initialValue: color)
        }
    }
    
    var displayColor: Color {
        if note.colorTag == .custom, let hex = note.customColorHex, let color = Color(hex: hex) {
            return color
        } else {
            return note.colorTag.color
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isEditing {
                ScrollView {
                    NoteDetailEditSections(
                        editedTitle: $editedTitle,
                        editedContent: $editedContent,
                        editedLocation: $editedLocation,
                        editedDate: $editedDate,
                        editedColorTag: $editedColorTag,
                        editedCustomColor: $editedCustomColor,
                        editedCustomColorHex: $editedCustomColorHex
                    )
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(note.title.isEmpty ? "Untitled" : note.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            if note.colorTag != .none {
                                Circle()
                                    .fill(displayColor)
                                    .frame(width: 20, height: 20)
                            }
                        }
                        
                        if !note.content.isEmpty {
                            Text(note.content)
                                .font(.body)
                        }
                        
                        // Location info
                        if !note.location.isEmpty {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.secondary)
                                Text(note.location)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Date info
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text("Date: \(note.date, style: .date)")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Created: \(note.dateCreated, style: .date)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if note.dateModified != note.dateCreated {
                                Text("Modified: \(note.dateModified, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    }
                    isEditing.toggle()
                }
                .fontWeight(.semibold)
            }
        }
    }
    
    private func saveChanges() {
        let hex = editedColorTag == .custom ? editedCustomColor.toHex() : nil
        note.updateContent(title: editedTitle, content: editedContent, location: editedLocation, date: editedDate, colorTag: editedColorTag, customColorHex: hex)
        notesStore.updateNote(note)
    }
}

// MARK: - Repeat similar refactor for NoteDetailView editing section
struct NoteDetailEditSections: View {
    @Binding var editedTitle: String
    @Binding var editedContent: String
    @Binding var editedLocation: String
    @Binding var editedDate: Date
    @Binding var editedColorTag: ColorTag
    @Binding var editedCustomColor: Color
    @Binding var editedCustomColorHex: String?
    @FocusState private var dummyFocus: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            NoteTitleSection(title: $editedTitle, isTitleFocused: $dummyFocus)
            NoteLocationSection(location: $editedLocation)
            NoteDateSection(date: $editedDate)
            NoteColorTagSection(colorTag: $editedColorTag, customColor: $editedCustomColor, customColorHex: $editedCustomColorHex)
            NoteContentSection(content: $editedContent)
        }
        .padding()
    }
}

// MARK: - SwiftUI Previews
struct NotesMainView_Previews: PreviewProvider {
    static var previews: some View {
        NotesMainView()
    }
}

struct NoteRowView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            NoteRowView(note: Note(title: "Sample Note", content: "This is a sample note with some content to show how it looks in the list view.", location: "New York", date: Date(), colorTag: .blue))
            NoteRowView(note: Note(title: "Another Note", content: "Short content", location: "Paris", date: Date().addingTimeInterval(-86400), colorTag: .green))
            NoteRowView(note: Note(title: "", content: "Untitled note example", location: "", date: Date(), colorTag: .none))
        }
    }
}

struct AddNoteView_Previews: PreviewProvider {
    static var previews: some View {
        AddNoteView(notesStore: NotesStore())
    }
}

struct NoteDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            NoteDetailView(note: Note(title: "Sample Note", content: "This is a detailed view of a sample note with longer content to demonstrate how the detail view appears when viewing and editing notes.", location: "San Francisco", date: Date(), colorTag: .purple), notesStore: NotesStore())
        }
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView()
    } 
}

// MARK: - App Entry Point
@main
struct ContentView: App {
    var body: some Scene {
        WindowGroup {
            NotesMainView()
        }
    }
}

// Utility to convert Color <-> Hex String
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
    
    func toHex() -> String? {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        let rgb: Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format: "%06X", rgb)
    }
}
