//
//  DiscoverySearch.swift
//  Iris
//
//  Created by Shalin on 7/20/20.
//  Copyright © 2020 Shalin. All rights reserved.
//

import SwiftUI

struct DiscoverySearch: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Binding var searchPresented: Bool
    @ObservedObject var observed: Observer
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            // Search bar
            Search(isBack: true, placeholder: "Search for a cuisine, or an ingredient", searchText: $searchText, buttonCommit:{self.presentationMode.wrappedValue.dismiss()}).padding(.top, 40).background(Color.retinaOverlayLight)
            
            HStack {
                if (self.searchText.isEmpty) {
                    Text("Suggestions for you").retinaTypography(.p5_main).padding(.leading, 24).padding(.top, 12).foregroundColor(.retinaWinterGrey)
                    Spacer()
                }
            }
            
            ScrollView(.vertical) {
                if (self.searchText.isEmpty) {
                    ForEach(self.observed.discoveryItems.filter {
                        $0.ideas == true
                    }, id: \.self) { item in
                        NavigationLink(
                          destination: TopChoicesView()) {
                            SearchCell(title: item.title, subtitle: item.category)
                            .listRowInsets(EdgeInsets())
                        }
                    }
                } else {
                    if self.observed.discoveryItems.filter { $0.title.lowercased().contains(self.searchText.lowercased()) }.count == 0 {
                        Text("No search results found, sorry.").retinaTypography(.p5_main).padding(.top, 36).foregroundColor(.retinaWinterGrey)
                    } else {
                        ForEach(self.observed.discoveryItems.filter {
                            self.searchText.isEmpty ? true : $0.title.lowercased().contains(self.searchText.lowercased())
                        }, id: \.self) { item in
                            NavigationLink(
                              destination: TopChoicesView()) {
                                SearchCell(title: item.title, subtitle: item.category)
                                .listRowInsets(EdgeInsets())

                            }
                        }
                    }
                }
            }.padding([.bottom], 60).background(Color.retinaOverflow).edgesIgnoringSafeArea(.bottom)
            .onAppear {
                UITableView.appearance().separatorStyle = .none
                UITableViewCell.appearance().backgroundColor = Color.retinaOverflow.uiColor()
                UITableView.appearance().backgroundColor = Color.retinaOverflow.uiColor()
                UITableViewCell.appearance().selectionStyle = .none
            }
            .resignKeyboardOnDragGesture()
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle("")
        .navigationBarHidden(true)
        .edgesIgnoringSafeArea(.top)
        .background(Color.retinaOverflow)
    }
}

struct DiscoverySearch_Previews: PreviewProvider {
    @State static var searchPresented = true
    @ObservedObject static var observed = Observer()

    static var previews: some View {
        DiscoverySearch(searchPresented: $searchPresented, observed: observed)
    }
}
