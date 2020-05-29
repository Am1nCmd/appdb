//
//  API+Install.swift
//  appdb
//
//  Created by ned on 28/09/2018.
//  Copyright © 2018 ned. All rights reserved.
//

import Alamofire
import SwiftyJSON

extension API {

    static func install(id: String, type: ItemType, alongsideId: String = "", displayName: String = "", completion:@escaping (_ error: String?) -> Void) {
        AF.request(endpoint, parameters: ["action": Actions.install.rawValue, "type": type.rawValue, "id": id, "is_alongside": alongsideId.lowercased(), "display_name": displayName], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        completion(json["errors"][0].stringValue)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    completion(error.localizedDescription)
                }
            }
    }

    static func requestInstallJB(plist: String, icon: String, link: String, completion:@escaping (_ error: String?) -> Void) {
        AF.request(endpoint, method: .post, parameters: ["action": Actions.customInstall.rawValue, "plist": plist, "icon": icon, "link": link], headers: headersWithCookie)
            .responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    if !json["success"].boolValue {
                        completion(json["errors"][0].stringValue)
                    } else {
                        completion(nil)
                    }
                case .failure(let error):
                    completion(error.localizedDescription)
                }
            }
    }

    static func getPlistFromItmsHelper(bundleId: String, localIpaUrlString: String, title: String, completion:@escaping (_ plistUrl: String?) -> Void) {
        AF.request(itmsHelperEndpoint + "request", method: .get, parameters: ["bundle": bundleId, "link": localIpaUrlString, "title": title], headers: headers).responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                let uuid = json["uuid"].stringValue
                if !uuid.isEmpty {
                    completion(itmsHelperEndpoint + "plists/" + uuid + ".plist")
                } else {
                    completion(nil)
                }
            case .failure:
                completion(nil)
            }
        }
    }
}
