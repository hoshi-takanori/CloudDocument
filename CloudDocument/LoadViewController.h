//
//  LoadViewController.h
//  CloudDocument
//
//  Created by Hoshi Takanori on 12/01/28.
//  Copyright (c) 2012 -. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LoadViewDelegate <NSObject>

- (void)loadData:(NSData *)data;
- (NSData *)dataToSave;

@end

@interface LoadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, assign) id <LoadViewDelegate> delegate;
@property (nonatomic, assign) BOOL isSaveAs;

@end
