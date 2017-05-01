//
//  NVListTableViewCell.h
//  NewsViewer
//
//  Created by natbak on 06/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NVListTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *summaryLabel;

@end
