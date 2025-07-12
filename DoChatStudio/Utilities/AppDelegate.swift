//
//  AppDelegate.swift
//
//  Created by Oscar de la Hera Gomez on 10/18/24.
//

#if os(macOS)
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        
        let blockTermination:Bool = DoChatStudioApp.documents.contains(where: {
            $0.blockTermination
        })
        
        if !blockTermination {return .terminateNow}
        
        let alert = NSAlert()
        alert.messageText = "Models are still generating"
        alert.informativeText = "There are models that are still generation. Are you sure you want to quit now?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Stop All Models and Quit")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            saveUserData()
            return .terminateNow
        default:
            return .terminateCancel
        }
    }
    
    func saveUserData() {
        // Logic to save data before quitting
        _ = DoChatStudioApp.documents.map { document in
            guard document.chatModel!.isGenerating == true else {
                document.chatModel?.cancelGeneration()
                return true
            }
            return false
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        let alert = NSAlert.init()
        alert.messageText = "\(sender.title)"
        alert.informativeText = "\(sender.representedFilename)"
        alert.addButton(withTitle: "Return")
        alert.addButton(withTitle: "Quit")
        alert.informativeText = "Quit or return to application?"
        let response = alert.runModal()
        
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            return false
        } else {
            NSApplication.shared.terminate(self)
            return true
        }
    }
}
#endif
