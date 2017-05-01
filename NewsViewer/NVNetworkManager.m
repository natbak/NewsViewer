//
//  NVNetworkManager.m
//  NewsViewer
//
//  Created by natbak on 13/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import "NVNetworkManager.h"

#import "AFNetworking.h"
#import "NVArticle.h"
#import "NVArticleSection.h"
#import "NVDefines.h"

#define MAX_NUM_ARTICLES_ONE_BATCH 10

static NSString * const kBaseUrl = @"http://api.zeit.de";

static NSString * const kOffset = @"offset";
static NSString * const kMatches = @"matches";
static NSString * const kArticleText = @"teaser_text";
static NSString * const kArticleTitle = @"teaser_title";
static NSString * const kArticleId = @"uuid";
static NSString * const kUrl = @"href";
static NSString * const kArticleContent = @"content";
static NSString * const kArticleSection = @"department";
static NSString * const kLimit = @"limit";
static NSString * const kLimitOfSections = @"45";
static NSString * const kSectionID = @"id";
static NSString * const kSectionName = @"value";
static NSString * const kSectionParent = @"parent";
static NSString * const kSorting = @"sort";
static NSString * const kName = @"name";
static NSString * const kErrorOffsets = @"Incosistency in offsets";
static NSString * const kSortingDateDesc = @"release_date desc";
static NSString * const kAuthorization = @"X-Authorization";

@implementation NVNetworkManager {
    AFHTTPSessionManager *_sessionManager;
}

+ (instancetype)sharedNetworkManager {
    static NVNetworkManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _sessionManager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:kBaseUrl]];
        [_sessionManager.requestSerializer setValue:kApiKey forHTTPHeaderField:kAuthorization];
    }
    return  self;
}

- (void)downloadArticlesForSection:(NSString *)section 
                          quantity:(NSUInteger)numberOfArticlesToDownload
                        withOffset:(NSInteger)offset
                           success:(void(^)(NSInteger offset, NSArray *articles))success
                           failure:(void(^)(NSError *error))failure {
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    NSString *articlesToGet = kArticleContent;
    if (![section isEqualToString:kMainSection]) {
        articlesToGet = [NSString stringWithFormat:@"%@/%@",kArticleSection, section];
    }
    
    param[kOffset] = [@(offset) stringValue];
    param[kSorting] = kSortingDateDesc;
    if (numberOfArticlesToDownload > MAX_NUM_ARTICLES_ONE_BATCH) {
        numberOfArticlesToDownload = MAX_NUM_ARTICLES_ONE_BATCH;
    }
    param[kLimit] = [NSString stringWithFormat:@"%lu", numberOfArticlesToDownload];
    [_sessionManager GET:articlesToGet parameters:param progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if (offset == [[responseObject objectForKey:kOffset] integerValue]) {
                NSArray *articles = [self parseArticlesFromResponseObject:responseObject];
                success(offset, articles);
            }
            else {
                failure([NSError errorWithDomain:kErrorOffsets code:0 userInfo:nil]);
            }
        }
    }
        failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)downloadArticlesForSection:(NSString *)section
                        withOffset:(NSInteger)offset
                           success:(void(^)(NSInteger offset, NSArray *articles))success
                           failure:(void(^)(NSError *error))failure {
    [self downloadArticlesForSection:section quantity:MAX_NUM_ARTICLES_ONE_BATCH withOffset:offset success:success failure:failure];
}


- (void)downloadArticlesWithOffset:(NSInteger)offset
                          success:(void(^)(NSInteger offset, NSArray *articles))success
                          failure:(void(^)(NSError *error))failure {
    [self downloadArticlesForSection:nil quantity:MAX_NUM_ARTICLES_ONE_BATCH withOffset:offset success:success failure:failure];
}

- (void)downloadArticleSectionsWithOffset:(NSInteger)offset
                                  success:(void(^)(NSInteger offset, NSArray *artSections))success
                                  failure:(void(^)(NSError *error))failure {
    [_sessionManager GET:kArticleSection parameters:@{kOffset:[@(offset) stringValue], kLimit:kLimitOfSections} progress:^(NSProgress * _Nonnull downloadProgress) {
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            if (offset == [[responseObject objectForKey:kOffset] integerValue]) {
                NSArray *sections = [self parseArticleSectionsFromResponseObject:responseObject];
                success(offset, sections);
            }
            else {
                failure([NSError errorWithDomain:kErrorOffsets code:0 userInfo:nil]);
            }
        }
    }
      failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
          failure(error);
    }];
}

- (NSArray *)parseArticlesFromResponseObject:(id)responseObject {
    NSMutableArray *mutArray = [NSMutableArray array];
    
    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        
        NSArray *articles = [responseObject objectForKey:kMatches];
        
        if ([articles isKindOfClass:[NSArray class]] && [articles count] > 0) {
            for (NSDictionary *articleDict in articles) {
                if ([articleDict isKindOfClass:[NSDictionary class]]) {
                    NVArticle *article = [[NVArticle alloc] init];
                    article.articleText = [articleDict objectForKey:kArticleText];
                    article.articleTitle = [articleDict objectForKey:kArticleTitle];
                    article.articleId = [articleDict objectForKey:kArticleId];
                    NSString *artUrl = [articleDict objectForKey:kUrl];
                    if (artUrl.length > 0) {
                        article.articleUrl = [NSURL URLWithString:artUrl];
                    }
                    [mutArray addObject:article];
                }
            }
        }
    }
    return [NSArray arrayWithArray:mutArray];
}

- (NSArray *)parseArticleSectionsFromResponseObject:(id)responseObject {
    NSMutableArray *sectionsArray = [NSMutableArray array];
    NSMutableDictionary *subSectionsDict = [NSMutableDictionary dictionary];

    if ([responseObject isKindOfClass:[NSDictionary class]]) {
        NSArray *responseArray = [responseObject objectForKey:kMatches];
        
        if ([responseArray isKindOfClass:[NSArray class]]) {
            for (NSDictionary *dict in responseArray) {
                if ([dict isKindOfClass:[NSDictionary class]]) {
                    NVArticleSection *section = [[NVArticleSection alloc] init];
                    section.sectionID = [dict objectForKey:kSectionID];
                    section.name = [dict objectForKey:kSectionName];
                    section.url = [dict objectForKey:kUrl];
                    NSString *sectionUrl = [dict objectForKey:kUrl];
                    if (sectionUrl.length > 0) {
                        section.url = [NSURL URLWithString:sectionUrl];
                    }
                    if ([[dict objectForKey:kSectionParent] length] < 1) { // only first tier sections are allowed
                        section.isChild = NO;
                        [sectionsArray addObject:section];
                    } else {
                        section.isChild = YES;
                        NSString *parentSectionName = [dict[kSectionParent] capitalizedString]; /* Parent section name
                                                                                                 has to be capitalized in order
                                                                                                 to match with parent section name later */
                        section.parentSection = parentSectionName;
                            if (subSectionsDict[parentSectionName] && [subSectionsDict[parentSectionName] isKindOfClass:[NSMutableArray class]]) {
                                [[subSectionsDict objectForKey:parentSectionName] addObject:section];
                            } else {
                                subSectionsDict[parentSectionName] = [NSMutableArray arrayWithObjects:section, nil];
                            }
                    }
                }
            }
        }
    }
    //Sorting subsections alphabetically
    NSMutableDictionary *sortedSubSectionsDict = [NSMutableDictionary dictionary];
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:kName ascending:YES];
    for (NSString *key in subSectionsDict) {
        if ([subSectionsDict[key] count] > 1) {
            NSArray *sortedArray = [subSectionsDict[key] sortedArrayUsingDescriptors:@[sort]];
            sortedSubSectionsDict[key] = sortedArray;
        }
    }
    //Sorting sections alphabetically
    NSArray *sortedSectionsArray = [sectionsArray sortedArrayUsingDescriptors:@[sort]];

    //Adding subsections
    NSMutableArray *mutSortedSectionArray = [NSMutableArray arrayWithArray:sortedSectionsArray];
    int offset = 0;
    for (int i = 0; i < sortedSectionsArray.count; i++) {
        NVArticleSection *section = sortedSectionsArray[i];
        NSArray *subSectionsArray = sortedSubSectionsDict[section.name];
        if (subSectionsArray) {
            //adding subsections to the main array of sections
            for (int n = 0, newI = i + offset; n < subSectionsArray.count; n++) {
                newI += 1;
                [mutSortedSectionArray insertObject:subSectionsArray[n] atIndex:newI];
                offset +=1; //adding subsections increments offset 
            }
            //adding subsections as children to the parent section
            section.children = [NSArray arrayWithArray:sortedSubSectionsDict[section.name]];
        }
    }
    
    return [NSArray arrayWithArray:mutSortedSectionArray];
}

@end
