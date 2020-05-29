//
//  API.swift
//  appdb
//
//  Created by ned on 15/10/2016.
//  Copyright © 2016 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON
import Localize_Swift

enum API {
    static let endpoint = "https://api.dbservices.to/v1.2/"
    static let statusEndpoint = "https://status.dbservices.to/API/v1.0/"
    static let itmsHelperEndpoint = "https://itms-plist-helper.herokuapp.com/"

    static var languageCode: String {
        Localize.currentLanguage()
    }

    static let headers: HTTPHeaders = ["User-Agent": "appdb iOS Client v\(Global.appVersion)"]

    static var headersWithCookie: HTTPHeaders {
        guard Preferences.deviceIsLinked else { return headers }
        return [
            "User-Agent": "appdb iOS Client v\(Global.appVersion)",
            "Cookie": "lt=\(Preferences.linkToken)"
        ]
    }
}

enum DeviceType: String {
    case iphone
    case ipad
}

enum ItemType: String, Codable {
    case ios = "ios"
    case books = "books"
    case cydia = "cydia"
    case myAppstore = "MyAppStore"
}

enum Order: String {
    case added = "added"
    case day = "clicks_day"
    case week = "clicks_week"
    case month = "clicks_month"
    case year = "clicks_year"
    case all = "clicks_all"
}

enum Price: String {
    case all = "0"
    case paid = "1"
    case free = "2"
}

enum Actions: String {
    case search = "search"
    case listGenres = "list_genres"
    case promotions = "promotions"
    case getLinks = "get_links"
    case getNews = "get_news"
    case link = "link"
    case getLinkCode = "get_link_code"
    case getConfiguration = "get_configuration"
    case configure = "configure"
    case getStatus = "get_status"
    case clear = "clear"
    case fix = "fix_command"
    case retry = "retry_command"
    case install = "install"
    case customInstall = "custom_install"
    case report = "report"
    case checkRevoke = "is_apple_fucking_serious"
    case getUpdatesTicket = "get_update_ticket"
    case getUpdates = "get_updates"
    case getIpas = "get_ipas"
    case deleteIpa = "delete_ipa"
    case addIpa = "add_ipa"
    case analyzeIpa = "get_ipa_analyze_jobs"
    case createPublishRequest = "create_publish_request"
    case getPublishRequests = "get_publish_requests"
    case validatePro = "validate_voucher"
    case activatePro = "activate_pro"
    case emailLinkCode = "email_link_code"
    case getAppdbAppsBundleIdsTicket = "get_appdb_apps_bundle_ids_ticket"
    case getAppdbAppsBundleIds = "get_appdb_apps_bundle_ids"
}

enum ConfigurationParameters: String {
    case appsync = "params[appsync]"
    case ignoreCompatibility = "params[ignore_compatibility]"
    case askForOptions = "params[ask_for_installation_options]"
}
