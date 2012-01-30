//
//  SimpleHUD.m
//  CloudDocument
//
//  Created by Hoshi Takanori on 12/01/28.
//  Copyright (c) 2012 -. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "SimpleHUD.h"

#define HUD_WIDTH   100
#define HUD_HEIGHT  100

#define HUD_CORNER  10
#define HUD_ALPHA   0.6

#define HUD_DELAY   0.2

@implementation SimpleHUD

static SimpleHUD *sharedHUD;

+ (void)show
{
    if (sharedHUD == nil) {
        sharedHUD = [[SimpleHUD alloc] initWithFrame:[UIScreen mainScreen].bounds];
        sharedHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        sharedHUD.windowLevel = UIWindowLevelAlert;

        sharedHUD.hidden = NO;

        [sharedHUD performSelector:@selector(start) withObject:nil afterDelay:HUD_DELAY];
    }
}

+ (void)dismiss
{
    if (sharedHUD != nil) {
        [NSObject cancelPreviousPerformRequestsWithTarget:sharedHUD selector:@selector(start) object:nil];

        sharedHUD.hidden = YES;

        [sharedHUD release];
        sharedHUD = nil;
    }
}

static CGRect center_rect(CGRect bounds, CGFloat width, CGFloat height)
{
    CGFloat x = bounds.origin.x + (bounds.size.width - width) / 2;
    CGFloat y = bounds.origin.y + (bounds.size.height - height) / 2;
    return CGRectMake(x, y, width, height);
}

- (void)start
{
    UIView *hudView = [[UIView alloc] initWithFrame:center_rect(self.bounds, HUD_WIDTH, HUD_HEIGHT)];
    hudView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                               UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    hudView.backgroundColor = [UIColor colorWithWhite:0 alpha:HUD_ALPHA];
    hudView.layer.cornerRadius = HUD_CORNER;
    [self addSubview:hudView];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.center = CGPointMake(HUD_WIDTH / 2, HUD_HEIGHT / 2);
    [hudView addSubview:spinner];

    [spinner startAnimating];

    [spinner release];
    [hudView release];
}

@end
