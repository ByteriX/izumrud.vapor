//
//  ProgressService.swift
//  Izumrud
//
//  Created by Sergey Balalaev on 31.05.2023.
//  Copyright © 2023 Byterix. All rights reserved.
//

import Foundation
import CircularSpinner
import PromiseKit

struct ProgressService {

    func start(with title: String) -> Promise<Data> {
        return Promise { seal in
            #warning("May be is sync? Please fixed and test! I think it can show only first message")
            DispatchQueue.main.async {
                CircularSpinner.show(title, animated: true, type: .indeterminate, showDismissButton: false)
                seal.fulfill(Data())
            }
        }
    }

}
