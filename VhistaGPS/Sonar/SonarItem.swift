//
//  SonarItem.swift
//  Travelia
//
//  Created by Juan David Cruz Serrano on 10/9/17.
//  Copyright © 2017 Juan David Cruz Serrano. All rights reserved.
//

import UIKit
import Sonar

class SonarItem: SonarItemView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.imageView.layer.cornerRadius = self.imageView.frame.size.width/2
        self.imageView.layer.masksToBounds = true
        self.imageView.contentMode  = .scaleAspectFit
    }

}
