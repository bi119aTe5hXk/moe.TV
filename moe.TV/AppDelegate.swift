//
//  AppDelegate.swift
//  moe.TV
//
//  Created by billgateshxk on 2019/08/13.
//  Copyright © 2019 bi119aTe5hXk. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        let ud = UserDefaults.init(suiteName: UD_SUITE_NAME)!
        ud.register(defaults: [UD_SAVED_COOKIES : []])
        ud.register(defaults: [UD_TOPSHELF_ARR : []])
        ud.register(defaults: [UD_LOGEDIN : false])
        ud.register(defaults: [UD_SERVICE_TYPE : "albireo"])
        ud.register(defaults: [UD_SERVER_ADDR : ""])
        ud.register(defaults: [UD_PROXY_SERVER : ""])
        ud.register(defaults: [UD_PROXY_PORT : ""])
        ud.register(defaults: [UD_SONARR_APIKEY : ""])
        ud.register(defaults: [UD_SONARR_USERNAME : ""])
        ud.register(defaults: [UD_SONARR_PASSWORD : ""])
        ud.register(defaults: [UD_SONARR_ROOTFOLDER : ""])
        ud.register(defaults: [UD_USING_HTTPS : true])
        ud.register(defaults: [UD_SONARR_WEBDAV_PORT : 0])
        ud.register(defaults: [UD_SONARR_USINGBASICAUTH : false])
        
        //UserDefaults.init(suiteName: UD_SUITE_NAME)?.set(false, forKey: UD_LOGEDIN)
        
        if let tabController = window?.rootViewController as? UITabBarController {
            let serviceType = UserDefaults.init(suiteName: UD_SUITE_NAME)!.string(forKey: UD_SERVICE_TYPE)!
            if serviceType == "albireo"{
                tabController.viewControllers?.append(packagedSearchController())
            }else if serviceType == "sonarr" {
                
            }else{
                print("Error: Service type unknown.")
            }
            
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .moviePlayback)
        }
        catch {
            print("Setting category to AVAudioSessionCategoryPlayback failed.")
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        //print("Will open URL from Top Shelf. URL=%@", url as NSURL)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "topshelf"), object: nil, userInfo: ["url":url])
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    // MARK: Convenience
    
    /*
     A method demonstrating how to encapsulate a `UISearchController` for presentation in, for example, a `UITabBarController`
     */
    func packagedSearchController() -> UIViewController {
        
        // Load a `SearchResultsViewController` from its storyboard.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let searchResultsController = storyboard.instantiateViewController(withIdentifier: SearchResultsViewController.storyboardIdentifier) as? SearchResultsViewController else {
            fatalError("Unable to instatiate a SearchResultsViewController from the storyboard.")
        }
        
        /*
         Create a UISearchController, passing the `searchResultsController` to
         use to display search results.
         */
        let searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.searchResultsUpdater = searchResultsController
        searchController.searchBar.placeholder = NSLocalizedString("Enter keyword", comment: "")
        
        // Contain the `UISearchController` in a `UISearchContainerViewController`.
        let searchContainer = UISearchContainerViewController(searchController: searchController)
        searchContainer.title = NSLocalizedString("Search", comment: "")
        
        // Finally contain the `UISearchContainerViewController` in a `UINavigationController`.
        let searchNavigationController = UINavigationController(rootViewController: searchContainer)
        return searchNavigationController
        
    }
}

