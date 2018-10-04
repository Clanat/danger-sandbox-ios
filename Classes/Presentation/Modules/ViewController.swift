//
//  Copyright © 2018 Rosberry. All rights reserved.
//

import UIKit

final class ViewController: UIViewController {

    enum BadEnum {
        case first, second, third
        case a, b, c

    }

    private enum AnyError: Error {
        case any
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    private func reallyBadCode() {
        let closure = {
            throw AnyError.any
        }
        try! closure()

    }
}