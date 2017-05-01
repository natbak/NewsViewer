//
//  ViewController.m
//  NewsViewer
//
//  Created by natbak on 02/10/16.
//  Copyright © 2016 natbak. All rights reserved.
//

#import "SidePanelTableViewController.h"

#import "NVArticleSection.h"
#import "NVDefines.h"
#import "NVNetworkManager.h"
#import "NVUtilities.h"

#define NUM_OF_SECTIONS 1
#define NUM_OF_ADDITIONAL_ROWS 1
#define CELL_IDENTIFIER @"SidePanelTableViewCell"
#define STARTUP_PAGE @"Startseite"
#define HEADER_HEIGHT 50.0f

@interface SidePanelTableViewController ()

@property (strong, nonatomic) NSArray *articleSections;
@property (weak, nonatomic) IBOutlet UITableView *sidePanelTableView;

@end


@implementation SidePanelTableViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self updateArticleSections];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.sidePanelTableView.contentOffset = CGPointZero;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return NUM_OF_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.articleSections.count + NUM_OF_ADDITIONAL_ROWS; //add 1 for Startseite section
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = CELL_IDENTIFIER;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if (indexPath.row <= [self.articleSections count]) {
        if (indexPath.row == 0) {
            cell.textLabel.text = STARTUP_PAGE;
        } else {
            NVArticleSection *section = [self.articleSections objectAtIndex:indexPath.row - NUM_OF_ADDITIONAL_ROWS];
            if (section.isChild == YES) {
                cell.textLabel.text = [NSString stringWithFormat:@"    %@", section.name];
            } else {
                cell.textLabel.text = section.name;
            }
        }
    }
    cell.textLabel.font = [UIFont systemFontOfSize:kLabelNormalFontSize weight:UIFontWeightMedium];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row <= [self.articleSections count]) {
        if (indexPath.row == 0) {
            [self sendNotificationWithChosenSection:kMainSection];
        } else {
            NVArticleSection *section = [self.articleSections objectAtIndex:indexPath.row - NUM_OF_ADDITIONAL_ROWS];
            [self sendNotificationWithChosenSection:section.sectionID];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, HEADER_HEIGHT)];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return HEADER_HEIGHT;
}

- (void)updateArticleSections {
    [[NVNetworkManager sharedNetworkManager] downloadArticleSectionsWithOffset:0
                                                                       success:^(NSInteger offset, NSArray *artSections) {
        self.articleSections = artSections;
    } failure:^(NSError *error) {
        NSString *errorTitle = NSLocalizedString(@"Failed to retrieve sections", @"error title");
        NSString *errorMessage = NSLocalizedString(@"Sorry, please try again later", @"generic error message");
        UIAlertController *alert = AlertControllerWithTitleAndMessage(errorTitle, errorMessage);
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)sendNotificationWithChosenSection:(NSString *)section {
    [[NSNotificationCenter defaultCenter] postNotificationName:UpdateForArticlesNeededNotification
                                                        object:nil
                                                      userInfo:@{kSection: section}];
}

@end
