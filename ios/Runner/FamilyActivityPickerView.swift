import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

@available(iOS 16.0, *)
struct FamilyActivityPickerView: View {
    #if canImport(FamilyControls)
    @State private var selection: FamilyActivitySelection
    #endif
    
    var onDismiss: ((Bool) -> Void)?
    
    init(onDismiss: ((Bool) -> Void)? = nil) {
        self.onDismiss = onDismiss
        #if canImport(FamilyControls)
        if let saved = MiqaatLockManager.shared.getSelectedApps() {
            _selection = State(initialValue: saved)
        } else {
            _selection = State(initialValue: FamilyActivitySelection())
        }
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    onDismiss?(false)
                }) {
                    Text("Cancel")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("Select Apps to Lock")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    saveSelection()
                    onDismiss?(true)
                }) {
                    Text("Save")
                        .fontWeight(.bold)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(UIColor.systemBackground))
            
            Divider()
            
            #if canImport(FamilyControls)
            FamilyActivityPicker(selection: $selection)
            #else
            Text("Family Controls not available")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            #endif
        }
    }
    
    private func saveSelection() {
        #if canImport(FamilyControls)
        MiqaatLockManager.shared.setSelectedApps(selection)
        let appCount = selection.applicationTokens.count
        let categoryCount = selection.categoryTokens.count
        print("MiqaatLock: Saved \(appCount) apps and \(categoryCount) categories")
        #endif
    }
}

@available(iOS 16.0, *)
class FamilyActivityPickerHostingController: UIHostingController<FamilyActivityPickerView> {
    
    var onDismiss: (() -> Void)?
    
    init() {
        let pickerView = FamilyActivityPickerView()
        super.init(rootView: pickerView)
        
        self.rootView = FamilyActivityPickerView(
            onDismiss: { [weak self] saved in
                self?.dismiss(animated: true) {
                    self?.onDismiss?()
                }
            }
        )
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
