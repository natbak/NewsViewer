//
//  NVUtilities.m
//  NewsViewer
//
//  Created by natbak on 29/04/2017.
//  Copyright © 2017 natbak. All rights reserved.
//

#import "NVUtilities.h"

UIAlertController* AlertControllerWithTitleAndMessage(NSString *title, NSString *message) {
    UIAlertController *alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    NSString *okButtonText = NSLocalizedString(@"Ok", @"generic confirmation");
    
    UIAlertAction* okButton = [UIAlertAction
                                actionWithTitle:okButtonText
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                }];
    
    [alert addAction:okButton];
    
    return alert;
}

