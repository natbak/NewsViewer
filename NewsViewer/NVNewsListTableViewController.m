//
//  NVNewsListTableViewController.m
//  NewsViewer
//
//  Created by natbak on 02/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import "NVNewsListTableViewController.h"

#import "NVArticle.h"
#import "NVDefines.h"
#import "NVFullArticleViewController.h"
#import "NVListTableViewCell.h"
#import "NVNetworkManager.h"
#import "NVUtilities.h"

#define NUM_OF_SECTIONS 1
#define MAIN_SECTION @"mainSection"
#define CELL_IDENTIFIER @"NVListTableViewCell"
#define ESTIMATED_ROW_HEIGHT 44.0

@interface NVNewsListTableViewController ()

@property (weak, nonatomic) IBOutlet UITableView *listTableView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sectionsBarButtonItem;

@property (strong, nonatomic) NSMutableArray *articles;
@property (nonatomic) BOOL updatingArticles;
@property (strong, nonatomic) NSString *currentSection;

@end


@implementation NVNewsListTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentSection = MAIN_SECTION;
    self.articles = [NSMutableArray array];
    
    if (kApiKey.length > 0) {
        [self updateArticles];
    } else {
        NSString *errorTitle = NSLocalizedString(@"No api key", @"No api key");
        NSString *errorMessage = NSLocalizedString(@"Please setup your own api key in NVDefines", nil);
        UIAlertController *alert = AlertControllerWithTitleAndMessage(errorTitle, errorMessage);
        [self presentViewController:alert animated:YES completion:nil];
    }

    self.sectionsBarButtonItem.target = self;
    self.sectionsBarButtonItem.action = @selector(openCloseSidePanel);
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateForArticlesInSectionNeeded:)
                                                 name:UpdateForArticlesNeededNotification object:nil];
    
    self.listTableView.estimatedRowHeight = ESTIMATED_ROW_HEIGHT;
    self.listTableView.rowHeight = UITableViewAutomaticDimension;
    
    UIRefreshControl *refreshContr = [[UIRefreshControl alloc] init];
    [refreshContr addTarget:self
                     action:@selector(pullToRefreshTriggered)
           forControlEvents:UIControlEventValueChanged];
    self.listTableView.refreshControl = refreshContr;
    
    self.updatingArticles = NO;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    if (self.articles.count) {
        return NUM_OF_SECTIONS;
    } else {
        UILabel *noArticlesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width,
                                                                             self.view.bounds.size.height)];
        noArticlesLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *errorText = NSLocalizedString(@"No articles available", @"data unavailable");
        if (kApiKey.length <= 0) {
            NSString *errorMessage = NSLocalizedString(@"No api key.\nPlease setup your own api key in NVDefines.", nil);
            errorText = [errorText stringByAppendingString:@"\n"];
            errorText = [errorText stringByAppendingString:errorMessage];
        }
        noArticlesLabel.text = errorText;
        noArticlesLabel.textColor = [UIColor blackColor];
        noArticlesLabel.numberOfLines = 0;
        noArticlesLabel.textAlignment = NSTextAlignmentCenter;
        noArticlesLabel.font = [UIFont systemFontOfSize:kLabelLargeFontSize];
        [noArticlesLabel sizeToFit];

        self.listTableView.backgroundView = noArticlesLabel;
        self.listTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.articles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = CELL_IDENTIFIER;
    NVListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    if (indexPath.row < [self.articles count]) {
        NVArticle *article = [self.articles objectAtIndex:indexPath.row];
        cell.titleLabel.text = article.articleTitle;
        cell.summaryLabel.text = article.articleText;
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSInteger lastRow = [self.articles count] - 1;
    if (indexPath.row == lastRow && !(lastRow < 0) && !self.updatingArticles) {
        self.updatingArticles = YES;
        [self updateArticles];
    }
}

#pragma mark - update methods

- (void)updateArticles {
    [self updateArticlesForSection:self.currentSection];
}

- (void)updateArticlesForSection:(NSString *)section {
    BOOL shouldDeletePreviousArticles = NO;
    if (![section isEqualToString:self.currentSection]) {
        shouldDeletePreviousArticles = YES;
    }
    
    [[NVNetworkManager sharedNetworkManager] downloadArticlesForSection:section
                                                             withOffset: shouldDeletePreviousArticles ? 0 : [self getNextOffset]
                                                                success:^(NSInteger offset, NSArray * articles) {
        [self.refreshControl endRefreshing];
        if (shouldDeletePreviousArticles == YES) {
            [self deleteCachedArticles];
        }
        
        [self.articles addObjectsFromArray:articles];
        self.currentSection = section;
        [self.listTableView reloadData];
        
        if (shouldDeletePreviousArticles == YES) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.003 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.listTableView.contentOffset = CGPointZero;
            });
        }
        self.updatingArticles = NO;
    } failure:^(NSError *error) {
        self.updatingArticles = NO;
        [self.refreshControl endRefreshing]; 
        if (shouldDeletePreviousArticles == YES) {
            [self deleteCachedArticles];
            [self.listTableView reloadData];
        }
    }];
}

- (void)updateForArticlesInSectionNeeded:(NSNotification *)notification {
    [self openCloseSidePanel];
    NSString *section = [notification userInfo][kSection];
    [self updateArticlesForSection:section];
}

- (void)checkNewArticlesForSection:(NSString *)section {
    [[NVNetworkManager sharedNetworkManager] downloadArticlesForSection:section
                                                               quantity:1
                                                             withOffset:0
                                                                success:^(NSInteger offset, NSArray *articlesDownloaded) {
        if (articlesDownloaded.count && self.articles.count) {
            NVArticle *oldArticle = self.articles[0];
            NVArticle *newArticle = articlesDownloaded[0];
            //if ids are equal article database is up to date. if not update is needed
            if (![oldArticle.articleId isEqualToString:newArticle.articleId]) {
                [self updateArticlesForSection:section];
            } else {
                [self.refreshControl endRefreshing];
            }
        }
    } failure:^(NSError *error) {
        [self.refreshControl endRefreshing];

        NSString *errorTitle = NSLocalizedString(@"Failed to retrieve articles", @"error title");
        NSString *errorMessage = NSLocalizedString(@"Sorry, please try again later", @"generic error message");
        UIAlertController *alert = AlertControllerWithTitleAndMessage(errorTitle, errorMessage);
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)deleteCachedArticles {
    [self.articles removeAllObjects];
}

- (NSInteger)getNextOffset {
    return [self.articles count];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NVFullArticleViewController *fullArtVC = segue.destinationViewController;
    if ([sender isKindOfClass:[UITableViewCell class]] & [fullArtVC isKindOfClass:[NVFullArticleViewController class]]) {
        NSIndexPath *path = [self.listTableView indexPathForCell:sender];
        if (path.row < self.articles.count) {
            NVArticle *article = [self.articles objectAtIndex:path.row];
            fullArtVC.articleUrl = article.articleUrl;
        }
    }
}

#pragma mark - Side Panel

- (void)openCloseSidePanel {
    if (self.slidingVC.sideDisplayed == MSSPSideDisplayedNone) {
        [self.slidingVC openRightPanel];
    } else {
        [self.slidingVC closePanel];
    }
}

#pragma mark - UI 

- (void)pullToRefreshTriggered {
    [self checkNewArticlesForSection:self.currentSection];
}

@end
