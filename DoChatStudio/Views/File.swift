////
////  File.swift
////  DoChatStudio
////
////  Created by Cosas on 7/11/25.
////
//
//
//VStack{
//                            HStack(alignment: .bottom){
//                                Button {
//                                    currentTab = 0
//                                } label: {
//                                    VStack{
//                                        Image(systemName: "book.circle")
//                                            .font(.system(.title2))
//                                        Text("Models")
//                                    }
//                                    .foregroundStyle(currentTab == 0 ? Color.accentColor : Color.primary)
//                                }
//                                
//                                Spacer()
//                                
//                                Button {
//                                    currentTab = 1
//                                } label: {
//                                    VStack{
//                                        Image(systemName: "gear")
//                                            .font(.system(.title2))
//                                        Text("Settings")
//                                    }
//                                    .foregroundStyle(currentTab == 1 ? Color.accentColor : Color.primary)
//                                }
//                                
//                                Spacer()
//                                
//                                Button {
//                                    currentTab = 2
//                                } label: {
//                                    VStack{
//                                        Image(systemName: "gauge.with.needle")
//                                            .font(.system(.title2))
//                                        Text("Performance")
//                                    }
//                                }
//                                .foregroundStyle(currentTab == 2 ? Color.accentColor : Color.primary)
//                                
//                            }
//                            .buttonStyle(.plain)
//                            .padding()
//                            
