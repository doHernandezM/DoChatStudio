
// Provides undoable controls for message metadata visibility and document colors.

import SwiftUI

struct StyleView: View {
    @Environment(\.undoManager) var undoManager
    @Bindable var vm: ChatModel

    var body: some View {
        VStack{
            VStack(alignment: .leading) {
                HStack{
                    Image(systemName:"paint.bucket.classic")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.style.accent)
                        .font(.system(.largeTitle))

                    Text("Color")
                        .font(.system(.title3))
                        .bold()
                }
                
                ColorPickerView(vm: vm)
                    .frame(maxWidth: .infinity)
            }
            .help(Text("Set document colors."))
    
            Divider().foregroundStyle(vm.style.transparentAccent)
            
            VStack(alignment: .leading) {
                HStack{
                    Image(systemName:"text.bubble")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(vm.style.userColor?.color ?? vm.style.transparentAccent, vm.style.accent)
                        .font(.system(.largeTitle))

                    Text("Conversation")
                        .font(.system(.title3))
                        .bold()
                }
                .help(Text("Set options for the conversation."))
                .padding(.bottom)
                
                EntitledControl(){
                 VStack(){
                        HStack{
                            Toggle(isOn: Binding<Bool>(
                                get:{vm.style.showPrompt},
                                set: {showPrompt in
                                    vm.style.showPrompt = showPrompt
                                }
                            )
                            ) {
                                Label{Text("Show Prompt")} icon: {
                                    
                                }
                            }
                            .tint(vm.style.accent)
                            .help(Text("Show or hide the prompt"))
                            .padding(.leading)
                            Spacer()
                        }
                        
                        HStack{
                            Toggle(isOn: Binding<Bool>(
                                get:{vm.style.showTimeStamp},
                                set: {showTimeStamp in
                                    vm.style.showTimeStamp = showTimeStamp
                                }
                            )
                            ) {
                                Label{Text("Show Timestamps")} icon: {
                                    
                                }
                            }
                            .tint(vm.style.accent)
                            .help(Text("Show or hide the message timestamps"))
                            .padding(.leading)
                            Spacer()
                        }
                        
                        HStack{
                            Toggle(isOn: Binding<Bool>(
                                get:{vm.style.showMetadata},
                                set: {showMetadata in
                                    vm.style.showMetadata = showMetadata
                                }
                            )
                            ) {
                                Label{Text("Show Metadata")} icon: {
                                    
                                }
                            }
                            .tint(vm.style.accent)
                            .help(Text("Show or hide the message metadata"))
                            .padding(.leading)
                            Spacer()
                        }
                    }
                 .frame(maxWidth: .infinity)
                }
                
                
            }
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
        }
    }

}
#Preview {
      let em = EntitlementManager()
      let pm = PurchaseManager(entitlementManager: em)
      return StyleView(vm: ChatModel(mlxService: MLXService()))
          .environmentObject(em)
          .environmentObject(pm)
  }
