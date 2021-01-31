//
//  PagesViewController.swift
//  MyKTGG
//
//  Created by Алексей Трушковский on 23.01.2021.
//  Copyright © 2021 Алексей Трушковский. All rights reserved.
//

import UIKit
import Firebase

class PagesViewController: UIViewController, UIScrollViewDelegate {
  
    @IBOutlet weak var constraint: NSLayoutConstraint!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var skipButton: UIButton!
    @IBAction func skipButton(_ sender: UIButton) {
        dismiss(animated: true)
        if Auth.auth().currentUser == nil  {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "showAuthVC"), object: nil)
        }
    }
    @IBOutlet weak var nextButton: UIButton!
    @IBAction func nextButton(_ sender: Any) {
        if Int((scrollView?.contentOffset.x)!/scrollWidth) == 2 {
            dismiss(animated: true)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let newvc = storyboard.instantiateViewController(withIdentifier: "RegViewController") as! AuthViewController
            present(newvc, animated: true, completion: nil)
        } else {
            pageControl.currentPage+=1
            scrollView!.scrollRectToVisible(CGRect(x: scrollWidth * CGFloat ((pageControl?.currentPage)!), y: 0, width: scrollWidth, height: scrollHeight), animated: true)
            setupButton(page: pageControl!.currentPage)
        }
    }
    
    var scrollWidth: CGFloat! = 0.0
    var scrollHeight: CGFloat! = 0.0

    //data for the slides
    var titles = ["РОЗКЛАД","НОВИНИ","МІЙ КТГГ"]
    var descs = ["Актуальний розклад та заміни прямо у вас в кишені.","Будь в курсі останніх подій твого навчального закладу.","І ще купа корисних функцій про які ти дізнаєшся зовсім скоро."]
    var imgs = ["firstPage","secondPage","thirdPage"]

    //get dynamic width and height of scrollview and save it
    override func viewDidLayoutSubviews() {
        scrollWidth = scrollView.frame.size.width
        scrollHeight = scrollView.frame.size.height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.layoutIfNeeded()
        self.scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        //crete the slides and add them
        var frame = CGRect(x: 0, y: 0, width: 0, height: 0)

        for index in 0..<titles.count {
            frame.origin.x = scrollWidth * CGFloat(index)
            frame.size = CGSize(width: scrollWidth, height: scrollHeight)

            let slide = UIView(frame: frame)

            //subviews
            let imageView = UIImageView.init(image: UIImage.init(named: imgs[index]))
            imageView.frame = CGRect(x:0,y:0,width:300,height:300)
            imageView.contentMode = .scaleAspectFit
            imageView.center = CGPoint(x:scrollWidth/2,y: scrollHeight/2 - 70)
          
            let txt1 = UILabel.init(frame: CGRect(x:32,y:imageView.frame.maxY+30,width:scrollWidth-64,height:30))
            txt1.textAlignment = .center
            txt1.font = UIFont(name:"SourceSansPro-SemiBold",size:20)
            txt1.text = titles[index]

            let txt2 = UILabel.init(frame: CGRect(x:32,y:txt1.frame.maxY+10,width:scrollWidth-64,height:50))
            txt2.textAlignment = .center
            txt2.numberOfLines = 3
            txt2.font = UIFont(name: "SourceSansPro-Regular", size: 18)
            txt2.text = descs[index]

            slide.addSubview(imageView)
            slide.addSubview(txt1)
            slide.addSubview(txt2)
            scrollView.addSubview(slide)
        }

        //set width of scrollview to accomodate all the slides
        scrollView.contentSize = CGSize(width: scrollWidth * CGFloat(titles.count), height: scrollHeight)

        //disable vertical scroll/bounce
        self.scrollView.contentSize.height = 1.0

        //initial state
        pageControl.numberOfPages = titles.count
        pageControl.currentPage = 0
        skipButton.isHidden = false
        nextButton.isHidden = false
        nextButton.layer.cornerRadius = nextButton.frame.height/2
    }

    //indicator
    @IBAction func pageChanged(_ sender: Any) {
        scrollView!.scrollRectToVisible(CGRect(x: scrollWidth * CGFloat ((pageControl?.currentPage)!), y: 0, width: scrollWidth, height: scrollHeight), animated: true)
        setupButton(page: pageControl!.currentPage)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setIndiactorForCurrentPage()
    }
    
    func setupButton(page: Int) {
        if Int(page) == 2 {
            self.constraint.constant = 40
            UIView.animate(withDuration: 0.3) {
                self.skipButton.alpha = 0
                self.view.layoutIfNeeded()
            }
            UIView.transition(with: nextButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
                self.nextButton.setTitle("РОЗПОЧАТИ", for: .normal)
            }, completion: nil)
        } else {
            self.constraint.constant = 159
            UIView.animate(withDuration: 0.3) {
                self.skipButton.alpha = 1
                self.view.layoutIfNeeded()
            }
            UIView.transition(with: nextButton, duration: 0.1, options: .transitionCrossDissolve, animations: {
                self.nextButton.setTitle("ДАЛІ", for: .normal)
            }, completion: nil)
        }
    }

    func setIndiactorForCurrentPage()  {
        let page = (scrollView?.contentOffset.x)!/scrollWidth
        pageControl?.currentPage = Int(page)
        setupButton(page: Int(page))
    }

}
