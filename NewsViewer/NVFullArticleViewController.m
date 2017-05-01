//
//  NVFullArticleViewController.m
//  NewsViewer
//
//  Created by natbak on 17/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import "NVFullArticleViewController.h"

@implementation NVFullArticleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    if (self.articleUrl != nil) {
        NSURLRequest *request = [NSURLRequest requestWithURL:self.articleUrl];
        [self.articleWebView loadRequest:request];
    }
}

@end
