//
//  NVNetworkManager.h
//  NewsViewer
//
//  Created by natbak on 13/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SidePanelTableViewController.h"

@interface NVNetworkManager : NSObject

+ (instancetype)sharedNetworkManager;

- (void)downloadArticlesForSection:(NSString *)section 
                        withOffset:(NSInteger)offset
                          success:(void(^)(NSInteger offset, NSArray *articles))success
                          failure:(void(^)(NSError *error))failure;

- (void)downloadArticlesForSection:(NSString *)section //designated method
                          quantity:(NSUInteger)numberOfArticlesToDownload //10 is maximum
                        withOffset:(NSInteger)offset
                           success:(void(^)(NSInteger offset, NSArray *articles))success
                           failure:(void(^)(NSError *error))failure;

- (void)downloadArticlesWithOffset:(NSInteger)offset
                           success:(void(^)(NSInteger offset, NSArray *articles))success
                           failure:(void(^)(NSError *error))failure;

- (void)downloadArticleSectionsWithOffset:(NSInteger)offset
                                  success:(void(^)(NSInteger offset, NSArray *artSections))success
                                  failure:(void(^)(NSError *error))failure;

@end
