//
//  Extensions.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 07.01.2021.
//  Copyright © 2021 Алексей Трушковский. All rights reserved.
//

import UIKit

extension UIView {
   func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension UIView {
    class func loadFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

extension UIButton {
    func applyGradient(colors: [CGColor]) {
        self.backgroundColor = nil
        self.layoutIfNeeded()
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = self.bounds
        gradientLayer.cornerRadius = self.frame.height/2

        gradientLayer.shadowColor = UIColor.darkGray.cgColor
        gradientLayer.shadowOffset = CGSize(width: 2.5, height: 2.5)
        gradientLayer.shadowRadius = 5.0
        gradientLayer.shadowOpacity = 0.3
        gradientLayer.masksToBounds = false

        self.layer.insertSublayer(gradientLayer, at: 0)
        self.contentVerticalAlignment = .center
        self.setTitleColor(UIColor.white, for: .normal)
        self.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17.0)
        self.titleLabel?.textColor = UIColor.white
    }
}

extension Date {
    func format(dateFormat: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "uk_UA")
        return formatter.string(from: self)
    }
    var ignoringTime: Date? {
        let dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        return Calendar.current.date(from: dateComponents)
    }
}
extension TimetableViewController: CustomAlertDelegate {
    func cancelAction() {
        self.animateOut()
    }
    
    func okAction() {
        self.okAction(type: self.alertStatus)
    }
}
extension UITabBarController {

    private struct AssociatedKeys {
        // Declare a global var to produce a unique address as the assoc object handle
        static var orgFrameView:     UInt8 = 0
        static var movedFrameView:   UInt8 = 1
    }

    var orgFrameView:CGRect? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.orgFrameView) as? CGRect }
        set { objc_setAssociatedObject(self, &AssociatedKeys.orgFrameView, newValue, .OBJC_ASSOCIATION_COPY) }
    }

    var movedFrameView:CGRect? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.movedFrameView) as? CGRect }
        set { objc_setAssociatedObject(self, &AssociatedKeys.movedFrameView, newValue, .OBJC_ASSOCIATION_COPY) }
    }

    override open func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let movedFrameView = movedFrameView {
            view.frame = movedFrameView
        }
    }

    func setTabBarVisible(visible:Bool, animated:Bool) {
        //since iOS11 we have to set the background colour to the bar color it seams the navbar seams to get smaller during animation; this visually hides the top empty space...
//        view.backgroundColor =  self.tabBar.barTintColor
        // bail if the current state matches the desired state
        if (tabBarIsVisible() == visible) { return }

        //we should show it
        if visible {
            tabBar.isHidden = false
            UIView.animate(withDuration: animated ? 0.3 : 0.0) {
                self.tabBar.alpha = 1
                //restore form or frames
                self.view.frame = self.orgFrameView!
                //errase the stored locations so that...
                self.orgFrameView = nil
                self.movedFrameView = nil
                //...the layoutIfNeeded() does not move them again!
                self.view.layoutIfNeeded()
                
            }
        } else {
            //safe org positions
            orgFrameView = view.frame
            // get a frame calculation ready
            let offsetY = self.tabBar.frame.size.height
            movedFrameView = CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height + offsetY)
            //animate
            UIView.animate(withDuration: animated ? 0.3 : 0.0, animations: {
                self.tabBar.alpha = 0.35
                self.view.frame = self.movedFrameView!
                self.view.layoutIfNeeded()
            }) {
                (_) in
                self.tabBar.isHidden = true
            }
        }
    }

    func tabBarIsVisible() ->Bool {
        return orgFrameView == nil
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound])
    }
}

extension Date {
    
    static func today() -> Date {
        let cal = NSCalendar.current
        let components = cal.dateComponents([.year, .month, .day], from: Date())
        let today = cal.date(from: components)
        return today!
    }
    
    func plain() -> Date {
        let cal = NSCalendar.current
        let components = cal.dateComponents([.year, .month, .day], from: self)
        let plain = cal.date(from: components)
        return plain!
    }
    
    func firstDateOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components)!
    }
    
    func addDays(_ days: Int) -> Date? {
        let dayComponenet = NSDateComponents()
        dayComponenet.day = days
        let theCalendar = NSCalendar.current
        let nextDate = theCalendar.date(byAdding: dayComponenet as DateComponents, to: self)
        return nextDate
    }
    
    func addMonth(_ month: Int) -> Date? {
        let dayComponenet = NSDateComponents()
        dayComponenet.month = month
        let theCalendar = NSCalendar.current
        let nextDate = theCalendar.date(byAdding: dayComponenet as DateComponents, to: self)
        return nextDate
    }
    
    func isWeekend() -> Bool {
        return Calendar.current.isDateInWeekend(self)
    }
}

extension String {
    
    var numbersOnly: String {
        
        let numbers = self.replacingOccurrences(
            of: "[^0-9]",
            with: "",
            options: .regularExpression,
            range:nil)
        return numbers
    }
}

extension ListViewController: Draggable{
    func draggableView() -> UIScrollView? {
        return tableView
    }
}

extension ListViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let model = sheetContentController.sheetModel
        self.itemsCount = model.items?.count ?? 0
        return self.itemsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.register(UINib(nibName: "MainItemCell", bundle: nil), forCellReuseIdentifier: "MainItemCell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainItemCell", for: indexPath) as! MainItemCell
        configureCell(cell: cell, indexPath: indexPath)
        return cell
    }
}

extension UIViewController {
    func ub_add(_ child: UIViewController, in container: UIView, animated: Bool = true, topInset: CGFloat, completion: (()->Void)? = nil) {
        addChild(child)
        container.addSubview(child.view)
        child.didMove(toParent: self)
        let f = CGRect(x: view.frame.minX, y: view.frame.minY, width: view.frame.width, height: view.frame.maxY - topInset)
        if animated{
            container.frame = f.offsetBy(dx: 0, dy: f.height)
            child.view.frame = container.bounds
            UIView.animate(withDuration: 0.3, animations: {
                container.frame = f
            }) { (_) in
                completion?()
            }
        }else{
            container.frame = f
            child.view.frame = container.bounds
            completion?()
        }
        
    }

    func ub_remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

}

extension UIView{
    func pinToEdges(to view: UIView, insets: UIEdgeInsets = .zero){
        self.translatesAutoresizingMaskIntoConstraints = false
        self.topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top).isActive = true
        self.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom).isActive = true
        self.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left).isActive = true
        self.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right).isActive = true
    }
    
    func constraint(_ parent: UIViewController, for attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint?{
        return parent.view.constraints.first(where: { (c) -> Bool in
             c.firstItem as? UIView == self && c.firstAttribute == attribute
         })
    }
    
    func roundCorners(corners: UIRectCorner, radius: CGFloat, rect: CGRect) {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
}

extension Array where Element == CGFloat{
    func nearest(to x: CGFloat) -> CGFloat{
        return self.reduce(self.first!) { abs($1 - x) < abs($0 - x) ? $1 : $0 }
    }
}
