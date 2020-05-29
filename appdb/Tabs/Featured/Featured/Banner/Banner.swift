//
//  Banner.swift
//  appdb
//
//  Created by ned on 11/10/2016.
//  Copyright © 2016 ned. All rights reserved.
//

import UIKit
import Cartography

extension Banner: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "image", for: indexPath) as? BannerImage else { return UICollectionViewCell() }

        // TODO: add more / fetch from APIs?
        switch indexPath.row {
        case 0: cell.image.image = #imageLiteral(resourceName: "banner")
        default: cell.image.image = #imageLiteral(resourceName: "placeholderBanner")
        }

        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    // TODO dynamic
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        pauseTimer()
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        setTimerIfNeeded()

        // Update current index to the correct one
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        guard let indexPath = collectionView.indexPathForItem(at: visiblePoint) else { return }
        currentIndex = indexPath.row
    }
}

class Banner: UITableViewCell {
    var collectionView: UICollectionView!

    // Cell height
    let height: CGFloat = {
        let w = Double(UIScreen.main.bounds.width)
        let h = Double(UIScreen.main.bounds.height)

        let screenWidth: Double = min(w, h)

        // Experimental
        return (230 ~~ CGFloat(screenWidth / 2.517 + 2))
    }()

    // Timer to scroll automatically
    private var slideshowTimer: Timer?

    // Keeps track of the current element's index
    private var currentIndex: Int = 0

    var slideshowInterval = 0.0 {
        didSet {
            self.slideshowTimer?.invalidate()
            self.slideshowTimer = nil
        }
    }

    deinit { pauseTimer() }

    convenience init() {
        self.init(style: .default, reuseIdentifier: Featured.CellType.banner.rawValue)

        contentView.backgroundColor = .clear
        backgroundColor = .clear

        let layout = LNZInfiniteCollectionViewLayout()
        layout.itemSize = CGSize(width: height * 2.5, height: height)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(BannerImage.self, forCellWithReuseIdentifier: "image")
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.scrollsToTop = false
        collectionView.alwaysBounceVertical = false

        collectionView.theme_backgroundColor = Color.tableViewBackgroundColor
        contentView.addSubview(collectionView)

        // Add constraints
        constrain(collectionView) { collectionView in
            collectionView.top ~== collectionView.superview!.top
            collectionView.left ~== collectionView.superview!.left
            collectionView.right ~== collectionView.superview!.right
            collectionView.height ~== height
        }

        slideshowInterval = 4.5

        //
        // Get Promotions
        // TODO: ask fred to add banner image to API
        //

        /*API.getPromotions( success: { items in
            
            if items.isEmpty {
                debugLog("no promotions to show")
            } else {
                debugLog("found \(items.count) promotions.")
            }
            
        }, fail: { error in
                debugLog(error.localizedDescription)
        })*/
    }

    // Set up timer if needed
    open func setTimerIfNeeded() {
        if slideshowInterval > 0 && slideshowTimer == nil {
            slideshowTimer = Timer.scheduledTimer(timeInterval: slideshowInterval, target: self, selector: #selector(self.slideshowTick(_:)), userInfo: nil, repeats: true)
        }
    }

    // Increase current index & scroll
    @objc func slideshowTick(_ timer: Timer) {
        let numberOfItems = collectionView.numberOfItems(inSection: 0)
        guard numberOfItems != 0 else { return }
        currentIndex += 1
        if currentIndex == numberOfItems { currentIndex = 0 }
        collectionView.scrollToItem(at: IndexPath(row: currentIndex, section: 0), at: .centeredHorizontally, animated: true)
    }

    // Invalidate timer
    open func pauseTimer() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
    }
}
