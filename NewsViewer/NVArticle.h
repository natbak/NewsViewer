//
//  NVArticle.h
//  NewsViewer
//
//  Created by natbak on 15/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NVArticle : NSObject

@property (strong, nonatomic) NSString *articleText;
@property (strong, nonatomic) NSString *articleTitle;
@property (strong, nonatomic) NSURL *articleUrl;
@property (strong, nonatomic) NSString *articleId;

@end
