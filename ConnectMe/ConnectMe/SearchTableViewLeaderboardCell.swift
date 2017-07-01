//
//  SearchTableViewLeaderboardCell.swift
//  Aquaint
//
//  Created by Yingbo Wang on 5/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class SearchTableViewLeaderboardCell: UITableViewCell {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var userCollectionView: UICollectionView!


}

extension SearchTableViewLeaderboardCell {
  
  // [Swift 3 Migration]
  //func setCollectionViewDataSourceDelegate<D>(_ dataSourceDelegate: D, forRow row: Int) where D:UICollectionViewDataSource, D:UICollectionViewDelegate {
  func setCollectionViewDataSourceDelegate<D: UICollectionViewDataSource & UICollectionViewDelegate>
    (dataSourceDelegate: D, forRow row: Int) {

    userCollectionView.dataSource = dataSourceDelegate
    userCollectionView.delegate = dataSourceDelegate
    // use tag to differentiate CollectionViews on different SearchTableViewLeaderboardCells
    userCollectionView.tag = row
    
    userCollectionView.reloadData()
  }
}
