//
//  ContentView.swift
//  Iris
//
//  Created by Shalin on 7/16/20.
//  Copyright © 2020 Shalin. All rights reserved.
//

import SwiftUI
import Alamofire
import SwiftyJSON

struct Card {
    var title: String
    var shortcuts: [String]
}

struct DiscoveryItem: Hashable, Identifiable, Codable {
    var id: String = "1"
    var title: String
    var imageUrl: String
    var category: String
    var discover: Bool = false
    var ideas: Bool = false
}

struct PreferenceItem: Hashable, Identifiable, Codable {
    var id: String = "1"
    var title: String
    var selected: Bool = false
}

struct Preference: Hashable, Identifiable, Codable {
    var id: String = "1"
    var title: String
    var type: String
    var items: [PreferenceItem]
}

struct Recipe: Hashable, Identifiable, Codable {
    var id: String = "1"
    var title: String
    var rating: String
    var cookTime: String
    var difficulty: String
    var imageUrl: String
    var ingredients: [String]
    var link: String
}


class TopChoicesObserver : ObservableObject {
    init() {
        getTopChoices()
    }
        
    @Published var recipes = [Recipe]()
    @Published var category: String = "ingredient"
    @Published var title: String = "None"
    @Published var item: String = "None"
    @Published var subtitle: String = "None"

    func getTopChoices() {
        let parameters = [
            "user_id": UserDefaults.standard.string(forKey: "userID"),
            "query_type": "ingredient",
            "query_string": "Chicken"
        ]
        let headers : HTTPHeaders = ["Content-Type": "application/json"]
        AF.request("https://e2nmwaykqf.execute-api.us-west-1.amazonaws.com/alpha/cookingcardresults", method: .post, parameters: parameters as Parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
            do {
                let json = try JSON(data: response.data ?? Data())
                print(json)
                if let category = json["category"].string {
                    self.category = category
                }
                if let title = json["title"].string {
                    self.title = title
                }
                if let item = json["item"].string {
                    self.item = item
                }
                if let subtitle = json["subtitle"].string {
                    self.subtitle = subtitle
                }

                for (_,subJson):(String, JSON) in json["results"] {
                    self.recipes.append(Recipe(id: subJson["id"].stringValue, title: subJson["title"].stringValue, rating: subJson["rating"].stringValue, cookTime: subJson["cook_time"].stringValue, difficulty: subJson["difficulty"].stringValue, imageUrl: subJson["image_url"].stringValue, ingredients: subJson["ingredients"].arrayValue.map { $0.stringValue}, link: subJson["link"].stringValue))
                }
            } catch {
                print("error")
            }
        }
    }

}





class Observer : ObservableObject{
    @Published var discoveryItems = [DiscoveryItem]()
    @Published var title: String = "None"
    @Published var subtitle: String = "None"
    
    init() {
        getSuggestions()
        getPreferences()
    }
    
    func getSuggestions() {
        AF.request("https://e2nmwaykqf.execute-api.us-west-1.amazonaws.com/alpha/cookingcardsearch")
            .responseJSON { response in
            do {
                let json = try JSON(data: response.data ?? Data())
                if let title = json["title"].string {
                    self.title = title
                }
                if let subtitle = json["subtitle"].string {
                    self.subtitle = subtitle
                }
                
                
                for (i,subJson):(String, JSON) in json["data"]["items"] {
                    let item = DiscoveryItem(id: i, title: subJson["name"].stringValue, imageUrl: subJson["image"].stringValue, category: subJson["category"].stringValue, discover: subJson["discover"].boolValue, ideas: subJson["ideas"].boolValue)
                    print(item)
                    self.discoveryItems.append(item)
                }
            } catch {
                print("error")
            }
        }
    }
    
    @Published var preferences = [Preference]()
    @Published var etching: String = "None"
    @Published var userNumber: String = "None"
    
    func getPreferences() {
        let parameters = ["user_id": UserDefaults.standard.string(forKey: "userID")]
        let headers : HTTPHeaders = ["Content-Type": "application/json"]
        AF.request("https://e2nmwaykqf.execute-api.us-west-1.amazonaws.com/alpha/preferencesget", method: .post, parameters: parameters as Parameters, encoding: JSONEncoding.default, headers: headers)
            .responseJSON { response in
            do {
                let json = try JSON(data: response.data ?? Data(), options: .allowFragments)
                if let etching = json["etching"].string {
                    self.etching = etching
                }
                if let userNumber = json["user_number"].string {
                    self.userNumber = userNumber
                }

                for (i,subJson):(String, JSON) in json["preferences"] {
                    var items = [PreferenceItem]()
                    for (j,item):(String, JSON) in subJson["items"] {
                        let prefItem = PreferenceItem(id: j, title: item["name"].stringValue, selected: item["selected"].boolValue)
                        items.append(prefItem)
                    }
                    let preference = Preference(id: i, title: subJson["title"].stringValue, type: subJson["type"].stringValue, items: items)
                    print(preference)
                    self.preferences.append(preference)
                }
            } catch {
                print("error")
            }
        }
    }

}

















struct ContentView: View {
    let spacing: CGFloat
    
    let headerTop: String
    let headerMain: String
    let searchBarText: String
    
    @State var searchPresented: Bool = false
    @State var preferencesPresented: Bool = false
    @State var topChoicesPresented: Bool = false
    @ObservedObject var observed = Observer()
    @ObservedObject var observedTopChoices = TopChoicesObserver()
    
    @State var showPreferencesAlert: Bool = false


    init(spacing: CGFloat = 5) {
        self.spacing = spacing
        self.headerTop = "Header Top"
        self.headerMain = "Main Title"
        self.searchBarText = "Search for a cuisine, ingredient, dish"
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                GeometryReader { geometry in
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading) {
                            ZStack {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .top) {
                                        Spacer()
                                        Button(action: {
                                            if UserDefaults.standard.bool(forKey: "preferencesSeen") == false {
                                                self.showPreferencesAlert.toggle()
                                            } else {
                                                withAnimation {
                                                    self.preferencesPresented = true
                                                }
                                            }
                                        }) {
                                            Image(systemName: "line.horizontal.3.decrease").foregroundColor(.retinaSnowWhite).retinaTypography(.h4_main)
                                        }.padding(.trailing, 24)
                                        .alert(isPresented: self.$showPreferencesAlert) {
                                            Alert(title: Text("Review your preferences at any time."), message: Text("Iris uses your preferences that don’t change often to filter results behind the scenes."), primaryButton: .default(Text("Review"), action: {
                                                UserDefaults.standard.set(true, forKey: "preferencesSeen")
                                                withAnimation {
                                                    self.preferencesPresented = true
                                                }
                                            }), secondaryButton: .default(Text("Cancel")))
                                        }
                                    }
                                    
                                    Text(self.observed.subtitle)
                                        .retinaTypography(.p5_main)
                                        .padding([.leading], 24)
                                        .foregroundColor(.retinaWinterGrey)
                                    Text(self.observed.title)
                                        .retinaTypography(.h3_secondary)
                                        .padding([.leading], 24)
                                        .frame(width: UIScreen.screenWidth, alignment: .leading)
                                        .foregroundColor(.retinaSnowWhite)
                                }.frame(width: UIScreen.screenWidth, alignment: .leading).padding(.top, 96)
                                
                                GeometryReader { geometry in
                                    Rectangle().offset(y: -(geometry.frame(in: .global).minY)).foregroundColor(Color.retinaOverflow)
                                        .blur(radius: 20)
                                        .padding(-25)
                                        .frame(width: UIScreen.screenWidth, height: UIApplication.topInset*1.5)
                                }
                            }.zIndex(1)
                            
                            
                            
                            // Search view
                            GeometryReader { geometry in
                                VStack {
                                    NavigationLink(destination: LazyView(DiscoverySearch(searchPresented: self.$searchPresented, observed: self.observed, observedTopChoices: self.observedTopChoices)), isActive: self.$searchPresented) { EmptyView() }
                                    if geometry.frame(in: .global).minY >= UIApplication.topInset {
                                        ZStack {
                                            retinaSearchButton(text: self.searchBarText, color: .retinaOverlayDark, backgroundColor: .retinaOverflow, action: { self.searchPresented = true })
                                                .offset(y: max(0, geometry.frame(in: .global).minY/9))
                                        }
                                    } else {
                                        ZStack {
                                            retinaSearchButton(text: self.searchBarText, color: .retinaOverlayDark, backgroundColor: .retinaOverflow, action: { self.searchPresented = true }).offset(y: -(geometry.frame(in: .global).minY - UIApplication.topInset))
                                        }
                                    }
                                }
                            }.frame(height: 60)
                                .zIndex(1)
                                .padding(.bottom, 24)
                                .padding(.top, 100)
                            
                            VStack {
                                HStack {
                                    Text("Ingredient Suggestions").retinaTypography(.h5_main).padding(.leading, 24).padding(.top, 36).padding(.bottom, 12).foregroundColor(.retinaWinterGrey)
                                    Spacer()
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(self.observed.discoveryItems.filter {
                                            $0.discover == true && $0.category == "ingredient"
                                        }, id: \.self) { item in
                                            NavigationLink(
                                            destination: LazyView(TopChoicesView(observed: self.observedTopChoices, topChoicesPresented: self.$topChoicesPresented))) {
                                                DiscoveryCell(title: item.title, backgroundImageUrl: item.imageUrl).padding([.leading, .trailing], 6)
                                            }.buttonStyle(PlainButtonStyle())
                                        }
                                    }.padding(.leading, 12)
                                }
                                
                                HStack {
                                    Text("Dish Suggestions").retinaTypography(.h5_main).padding(.leading, 24).padding(.top, 36).foregroundColor(.retinaWinterGrey).padding(.bottom, 12)
                                    Spacer()
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(self.observed.discoveryItems.filter {
                                            $0.discover == true && $0.category == "dish"
                                        }, id: \.self) { item in
                                            NavigationLink(
                                            destination: LazyView(TopChoicesView(observed: self.observedTopChoices, topChoicesPresented: self.$topChoicesPresented))) {
                                                DiscoveryCell(title: item.title, backgroundImageUrl: item.imageUrl).padding([.leading, .trailing], 6)
                                            }.buttonStyle(PlainButtonStyle())
                                        }
                                    }.padding(.leading, 12)
                                }
                                
                                
                                HStack {
                                    Text("Cuisine Suggestions").retinaTypography(.h5_main).padding(.leading, 24).padding(.top, 36).foregroundColor(.retinaWinterGrey).padding(.bottom, 12)
                                    Spacer()
                                }
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack {
                                        ForEach(self.observed.discoveryItems.filter {
                                            $0.discover == true && $0.category == "cuisine"
                                        }, id: \.self) { item in
                                            NavigationLink(
                                            destination: TopChoicesView(observed: self.observedTopChoices, topChoicesPresented: self.$topChoicesPresented)) {
                                                DiscoveryCell(title: item.title, backgroundImageUrl: item.imageUrl).padding([.leading, .trailing], 6)
                                            }.buttonStyle(PlainButtonStyle())
                                        }
                                    }.padding(.leading, 12).padding([.bottom], 120)
                                }
                            }.padding([.top], 48).background(Color.retinaSurface)
                        }
                    }
                }
                .background(Color.retinaOverflow)
                .navigationBarTitle("")
                .navigationBarHidden(true)
            }.background(Color.retinaSurface).edgesIgnoringSafeArea(.bottom)
            ZStack {
                PreferencesView(preferencesPresented: $preferencesPresented, observed: self.observed).padding([.top, .bottom], UIApplication.bottomInset)
            }
            .edgesIgnoringSafeArea(.all)
            .offset(x: 0, y: self.preferencesPresented ? 0 : UIScreen.screenHeight + UIApplication.bottomInset)
            

        }
    }
}























struct ContentView_Previews: PreviewProvider {
    @State static var data = [
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Chicken", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Beef", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Carrots", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Broccoli", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Pasta", imageUrl: "food", category: "Ingredient"),
        DiscoveryItem(title: "Salmon", imageUrl: "food", category: "Ingredient")
    ]
    
    static var previews: some View {
        Group {
            ContentView(spacing: -10)
        }
    }
}



