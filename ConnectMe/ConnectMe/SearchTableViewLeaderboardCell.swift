//
//  SearchTableViewLeaderboardCell.swift
//  Aquaint
//
//  Created by Yingbo Wang on 5/28/17.
//  Copyright © 2017 ConnectMe. All rights reserved.
//

import UIKit

class SearchTableViewLeaderboardCell: UITableViewCell {
  
  @IBOutlet weak var userCollectionView: UICollectionView!


}

extension SearchTableViewLeaderboardCell {
  
  func setCollectionViewDataSourceDelegate<D where D:UICollectionViewDataSource, D:UICollectionViewDelegate>(dataSourceDelegate: D, forRow row: Int) {

    userCollectionView.dataSource = dataSourceDelegate
    userCollectionView.delegate = dataSourceDelegate
    userCollectionView.tag = row
    
    userCollectionView.reloadData()
  }
}