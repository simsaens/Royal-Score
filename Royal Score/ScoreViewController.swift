//
//  ScoreViewController.swift
//  Royal Score
//
//  Created by Simeon Saint-Saens on 12/2/19.
//  Copyright © 2019 Two Lives Left. All rights reserved.
//

import UIKit
import SnapKit

extension UIStackView {
    fileprivate func addFieldViews(type: UIKeyboardType) {
        for i in 1...4 {
            let field = UITextField()
            field.tag = i - 1
            field.textAlignment = .center
            field.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
            field.keyboardType = type
            field.keyboardAppearance = .dark
            
            if i%2 == 1 {
                field.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
            } else {
                field.backgroundColor = .white
            }
            
            addArrangedSubview(field)
        }
    }
}

class ScoreHeader: UIView {
    let nameViews = UIStackView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let container = UIView()
        
        container.clipsToBounds = true
        container.layer.maskedCorners = [CACornerMask.layerMinXMinYCorner, CACornerMask.layerMaxXMinYCorner]
        container.layer.cornerRadius = 16.0
        
        addSubview(container)
        container.addSubview(nameViews)
        
        nameViews.axis = .horizontal
        nameViews.distribution = .fillEqually
        nameViews.alignment = .fill
        
        nameViews.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        container.snp.makeConstraints {
            make in
            make.left.equalToSuperview().offset(112)
            make.top.bottom.right.equalToSuperview()
        }
        
        nameViews.addFieldViews(type: .alphabet)
        
        let separatorBottom = UIView()
        separatorBottom.backgroundColor = .black
        addSubview(separatorBottom)
        
        separatorBottom.snp.makeConstraints {
            make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ScoreFooter: UIView {
    let scoreViews = UIStackView()
    let totalLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        addSubview(totalLabel)
        addSubview(scoreViews)
        
        scoreViews.axis = .horizontal
        scoreViews.distribution = .fillEqually
        scoreViews.alignment = .fill
        
        totalLabel.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        totalLabel.text = "Total"
        totalLabel.backgroundColor = .darkGray
        totalLabel.textColor = .white
        totalLabel.textAlignment = .center
        
        totalLabel.snp.makeConstraints {
            make in

            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(112)
        }
        
        scoreViews.snp.makeConstraints {
            make in
            
            make.left.equalTo(totalLabel.snp.right)
            make.top.bottom.right.equalToSuperview()
        }
        
        for i in 1...4 {
            let label = UILabel()
            label.tag = i
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
            
            if i%2 == 1 {
                label.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
            } else {
                label.backgroundColor = .white
            }
            
            scoreViews.addArrangedSubview(label)
        }
        
        let separatorTop = UIView()
        separatorTop.backgroundColor = .black
        addSubview(separatorTop)
        
        separatorTop.snp.makeConstraints {
            make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateTotal(at index: Int, value: Int) {
        if let label = scoreViews.arrangedSubviews[index] as? UILabel {
            label.text = String(value)
        }
    }
}

extension Notification.Name {
    static let scoreChanged = Notification.Name(rawValue: "ScoreChangedNotification")
    
    static let scoreRowKey = "ScoreRowKey"
    static let scoreColumnKey = "ScoreColumnKey"
    static let scoreKey = "ScoreKey"
}

class ScoreCell: UITableViewCell {
    let iconView = UIImageView()
    let scoreViews = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(iconView)
        contentView.addSubview(scoreViews)
        
        scoreViews.axis = .horizontal
        scoreViews.distribution = .fillEqually
        scoreViews.alignment = .fill
        
        iconView.snp.makeConstraints {
            make in
            
            make.top.left.bottom.equalToSuperview()
            make.width.equalTo(112)
        }
        
        scoreViews.snp.makeConstraints {
            make in
            
            make.left.equalTo(iconView.snp.right)
            make.top.bottom.right.equalToSuperview()
        }
        
        scoreViews.addFieldViews(type: .numberPad)
        
        for field in scoreViews.arrangedSubviews.compactMap({$0 as? UITextField}) {
            field.addTarget(self, action: #selector(valueChanged(_:)), for: .editingChanged)
        }
        
        let separatorTop = UIView()
        let separatorBottom = UIView()
        separatorTop.backgroundColor = .black
        separatorBottom.backgroundColor = .black
        
        contentView.addSubview(separatorTop)
        contentView.addSubview(separatorBottom)
        
        separatorTop.snp.makeConstraints {
            make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
        
        separatorBottom.snp.makeConstraints {
            make in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(1)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func valueChanged(_ field: UITextField) {
        let row = self.tag
        let column = field.tag
        
        let score = Int(field.text ?? "") ?? 0
        
        NotificationCenter.default.post(name: .scoreChanged, object: self, userInfo: [
            Notification.Name.scoreRowKey : row,
            Notification.Name.scoreColumnKey : column,
            Notification.Name.scoreKey : score
            ])
    }
}

class ScoreViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private let footer = ScoreFooter()
    private let scoreTable = UITableView()
    private var kbLayout: KeyboardLayout?
    
    private var scores: [[Int]] = []
    
    let icons = [
        "Coins",
        "Beach Crowns",
        "Forest Crowns",
        "Water Crowns",
        "Grass Crowns",
        "Desert Crowns",
        "Mine Crowns",
        "Town Crowns",
        "Regions",
        "Towers",
        "Knights",
        "Points",
    ]
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let topInset: CGFloat = 20
        
        for _ in 1...12 {
            scores.append([0,0,0,0])
        }
        
        NotificationCenter.default.addObserver(forName: .scoreChanged, object: nil, queue: nil) {
            [weak self] note in
            
            if let row = note.userInfo?[Notification.Name.scoreRowKey] as? Int,
                let column = note.userInfo?[Notification.Name.scoreColumnKey] as? Int,
                let score = note.userInfo?[Notification.Name.scoreKey] as? Int {
                
                self?.scores[row][column] = score
                self?.updateTotals()
            }
        }
        
        kbLayout = KeyboardLayout(viewForKeyboardIntersection: {
            [weak self] () -> UIView in
            
            return self?.view ?? UIView()
            
        }, layoutForKeyboardFrameChange: {
            [weak self] height, duration in
            
            self?.scoreTable.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: height, right: 0)
        })
        
        view.backgroundColor = UIColor(white: 0.2, alpha: 1.0)
        
        scoreTable.backgroundColor = .clear
        scoreTable.delegate = self
        scoreTable.dataSource = self
        scoreTable.rowHeight = 50.0
        scoreTable.separatorStyle = .none
        scoreTable.keyboardDismissMode = .interactive
        scoreTable.contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
        
        view.addSubview(scoreTable)
        
        scoreTable.snp.makeConstraints {
            make in
            
            make.edges.equalToSuperview()
        }
        
        scoreTable.register(ScoreCell.self, forCellReuseIdentifier: "ScoreCell")
        
        let header = ScoreHeader()
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 50)
        
        scoreTable.tableHeaderView = header
        
        footer.frame = CGRect(x: 0, y: 0, width: view.bounds.size.width, height: 50)
        
        scoreTable.tableFooterView = footer
    }
    
    //MARK: - Table View
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScoreCell", for: indexPath)
        
        if let cell = cell as? ScoreCell {
            cell.iconView.image = UIImage(named: icons[indexPath.row])
            cell.tag = indexPath.row
        }
        
        return cell
    }
    
    //MARK: - Totals
    
    private func updateTotals() {
        let totals = scores.reduce([0,0,0,0]) {
            (result, row) -> [Int] in
            
            return result.enumerated().map {
                i, v -> Int in
                
                return row[i] + v
            }
        }
        
        for i in 0..<4 {
            footer.updateTotal(at: i, value: totals[i])
        }
    }
}

