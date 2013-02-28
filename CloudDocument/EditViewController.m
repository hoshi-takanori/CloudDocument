//
//  EditViewController.m
//  CloudDocument
//
//  Copyright (c) 2012 Hoshi Takanori
//
//  Permission is hereby granted, free of charge, to any person obtaining
//  a copy of this software and associated documentation files (the
//  "Software"), to deal in the Software without restriction, including
//  without limitation the rights to use, copy, modify, merge, publish,
//  distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to
//  the following conditions:
//
//  The above copyright notice and this permission notice shall be included
//  in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "EditViewController.h"
#import "LoadViewController.h"

@interface EditViewController () <LoadViewDelegate> {
    UITextView *textView;
    BOOL isOpened;
}

@end

@implementation EditViewController

- (CGRect)textViewFrameForOrientation:(UIInterfaceOrientation)orientation
{
    if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGRectMake(8, 8, 304, 184);
    } else {
        return CGRectMake(8, 8, 464, 90);
    }
}

- (void)loadView
{
    CGRect frame = [UIScreen mainScreen].applicationFrame;
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor groupTableViewBackgroundColor];

    textView = [[UITextView alloc] initWithFrame:[self textViewFrameForOrientation:self.interfaceOrientation]];
    textView.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    [view addSubview:textView];

    self.view = view;
    [view release];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"CloudDocument";

    UIBarButtonItem *openItem = [[UIBarButtonItem alloc] initWithTitle:@"Open"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(handleOpen:)];
    self.navigationItem.leftBarButtonItem = openItem;
    [openItem release];

    UIBarButtonItem *saveItem = [[UIBarButtonItem alloc] initWithTitle:@"Save"
                                                                 style:UIBarButtonItemStyleBordered
                                                                target:self
                                                                action:@selector(handleSave:)];
    self.navigationItem.rightBarButtonItem = saveItem;
    [saveItem release];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (! isOpened) {
        [textView becomeFirstResponder];
        isOpened = YES;
    } else {
        textView.frame = [self textViewFrameForOrientation:self.interfaceOrientation];
    }
}

- (void)openLoadView:(BOOL)isSaveAs
{
    LoadViewController *viewController = [[LoadViewController alloc] init];
    viewController.delegate = self;
    viewController.isSaveAs = isSaveAs;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [viewController release];
}

- (void)handleOpen:(id)sender
{
    [self openLoadView:NO];
}

- (void)handleSave:(id)sender
{
    [self openLoadView:YES];
}

- (void)loadData:(NSData *)data
{
    NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    textView.text = string;
    [string release];
}

- (NSData *)dataToSave
{
    return [textView.text dataUsingEncoding:NSUTF8StringEncoding];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

    if ([UIView respondsToSelector:@selector(animateWithDuration:animations:)]) {
        [UIView animateWithDuration:duration animations:^{
            textView.frame = [self textViewFrameForOrientation:toInterfaceOrientation];
        }];
    } else {
        [UIView beginAnimations:@"orientation" context:NULL];
        [UIView setAnimationDuration:duration];
        textView.frame = [self textViewFrameForOrientation:toInterfaceOrientation];
        [UIView commitAnimations];
    }
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [textView release];
    textView = nil;
}

- (void)dealloc
{
    [textView release];
    [super dealloc];
}

@end
