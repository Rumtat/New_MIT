//
//  ScamRepository.swift
//  BYB_mit02
//
//  Created by Vituruch Sinthusate on 7/1/2569 BE.
//

import Foundation

protocol ScamRepository {
    func findMatches(type: ScanType, input: String) async -> [ScamEntry]
}
