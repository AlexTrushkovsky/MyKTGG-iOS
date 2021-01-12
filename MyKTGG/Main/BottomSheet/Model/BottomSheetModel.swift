//
//  BottomSheetModel.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 20.08.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation

struct BottomSheetModelItem: Decodable {
    var title: String?
    var subtitle: String?
    var image: String?
    var date: Date?
}

struct BottomSheetModel: Decodable {
    var items: [BottomSheetModelItem]?
}
