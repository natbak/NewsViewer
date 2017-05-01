//
//  NVFullArticleViewController.h
//  NewsViewer
//
//  Created by natbak on 17/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NVFullArticleViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIWebView *articleWebView;
@property (strong, nonatomic) NSURL *articleUrl;

@end
