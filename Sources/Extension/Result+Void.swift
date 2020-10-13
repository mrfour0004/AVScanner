//
//  Result+Void.swift
//  AVScanner
//
//  Created by mrfour on 2019/10/6.
//

import Foundation

extension Result where Success == Void {
    static var success: Result<Void, Failure> {
        .success(())
    }
}
