//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import Foundation
import Fabric
import Crashlytics

final class AppConfigurator {

    static func configure() {
        guard let appInfo = Bundle.main.infoDictionary,
            let shortVersionString = appInfo["CFBundleShortVersionString"] as? String,
            let bundleVersion = appInfo["CFBundleVersion"] as? String else {
                return
        }
        let appVersion = "\(shortVersionString) (\(bundleVersion))"
        UserDefaults.standard.appVersion = appVersion
        Fabric.with([Crashlytics.self])
    }
}

private extension UserDefaults {

    var appVersion: String? {
        get {
            return string(forKey: #function)
        }
        set {
            set(newValue, forKey: #function)
        }
    }
}
