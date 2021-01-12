//
//  BottomSheetNetworkController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 20.08.2020.
//  Copyright © 2020 Алексей Трушковский. All rights reserved.
//

import Foundation

class BottomSheetContentController {
    var sheetModel = BottomSheetModel()
    var itemArray = [BottomSheetModelItem]()
    func addItem(title: String, subtitle: String, image: String) {
        let newItem = BottomSheetModelItem(title: title, subtitle: subtitle, image: image)
        itemArray.append(newItem)
        sheetModel.items = itemArray
    }
}
