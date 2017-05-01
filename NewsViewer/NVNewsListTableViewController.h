//
//  NVNewsListTableViewController.h
//  NewsViewer
//
//  Created by natbak on 02/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "MSSlidingPanelController.h"


@interface NVNewsListTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) MSSlidingPanelController *slidingVC;

@end
