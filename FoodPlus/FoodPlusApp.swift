//
//  FoodPlusApp.swift
//  FoodPlus
//
//  Created by Kaviprakash Ramalingam on 12/10/24.
//

import SwiftUI
import Firebase

@main
struct FoodPlusApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var postListener = PostListener()
    init(){
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    postListener.startListeningForNewPosts()
                }
        }
    }
}
