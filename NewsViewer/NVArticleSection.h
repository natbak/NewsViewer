//
//  NVArticleSection.h
//  NewsViewer
//
//  Created by natbak on 19/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NVArticleSection : NSObject

@property (strong, nonatomic) NSString *sectionID;
@property (strong, nonatomic) NSString *name;
@property (strong, nonatomic) NSURL *url;
@property (strong, nonatomic) NSArray *children;
@property (strong, nonatomic) NSString *parentSection;
@property (nonatomic) BOOL isChild;

@end
