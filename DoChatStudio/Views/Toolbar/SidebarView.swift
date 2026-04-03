//
//  SidebarView.swift
//  DoChatStudio
//
//  Created by Cosas on 9/30/25.
//

import SwiftUI

struct SidebarView: View {
    @Binding var vm: ChatModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, content: {
                LazyVStack(pinnedViews: [.sectionHeaders]){
                    Section() {
                        InspectorPickerView(vm: $vm)
                        InspectorView(vm: $vm)
                    } header: {
                        SelectedModelView(vm: $vm)
                    }
                }
            })
            .scrollContentBackground(.hidden)
        }
        .background(.clear)
        .padding([.top])
    }
}

#Preview {
    SidebarView(vm: .constant(ChatModel(mlxService: MLXService())))
}

struct InspectorPickerView: View {
    @Binding var vm: ChatModel
    @State var size: CGSize = .zero
    
    var body: some View {
        
        VStack{
            Spacer(minLength: 5)
            HStack(){
                Button {
                    vm.style.currentSelectedTab = 1
                } label: {
                    VStack{
                        Image(systemName: "gear")
                            .font(.system(.title))
                            .foregroundStyle(vm.style.currentSelectedTab == 1 ? Color.primary : Color.secondary)
                        Text("Settings")
                            .foregroundStyle(vm.style.currentSelectedTab == 1 ? Color.primary : Color.secondary)
                    }
                    //                    .padding(4)
                    .foregroundStyle(vm.style.currentSelectedTab == 1 ? vm.style.accent : Color.secondary)
                    .frame(maxWidth: .infinity)
                    .background(content:{
                        RoundedRectangle(cornerRadius: 4 )
                            .stroke(vm.style.currentSelectedTab == 1 ? vm.style.accent : Color.secondary, lineWidth: 1.0)
                            .background(vm.style.currentSelectedTab == 1 ? vm.style.transparentAccent : Color.clear)
                    })
                    .contentShape(
                        RoundedRectangle(cornerRadius: 4)
                    )
                }
                
                Button {
                    vm.style.currentSelectedTab = 2
                } label: {
                    VStack{
                        Image(systemName: "gauge.with.needle")
                            .font(.system(.title))
                            .foregroundStyle(vm.style.currentSelectedTab == 2 ? Color.primary : Color.secondary)
                        Text("Performance")
                            .foregroundStyle(vm.style.currentSelectedTab == 2 ? Color.primary : Color.secondary)
                    }
                    //                    .padding(4)
                    .frame(maxWidth: .infinity)
                    .background(content:{
                        RoundedRectangle(cornerRadius: 4 )
                            .stroke(vm.style.currentSelectedTab == 2 ? vm.style.accent : Color.secondary, lineWidth: 1.0)
                            .background(vm.style.currentSelectedTab == 2 ? vm.style.transparentAccent : Color.clear)
                    })
                    .contentShape(
                        RoundedRectangle(cornerRadius: 4)
                    )
                }
            }
            .buttonStyle(.plain)
            .padding(4)
            
            Divider().foregroundStyle(vm.style.transparentAccent)
            
        }
        .frame(height: 64)
    }
}

struct InspectorView: View {
    @Binding var vm: ChatModel
    
    var body: some View {
        Group {
            switch vm.style.currentSelectedTab {
            case 2:
                PerformanceView(viewModel: vm)
                
            default:
                ConfigurationView(viewModel: vm)
            }
        }
        .padding([.leading, .trailing, .bottom])
    }
}
