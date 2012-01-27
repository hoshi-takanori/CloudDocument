//
//  CloudDocument.m
//  CloudDocument
//
//  Created by Hoshi Takanori on 12/01/28.
//  Copyright (c) 2012 -. All rights reserved.
//

#import "CloudDocument.h"
#import "SimpleHUD.h"

@implementation CloudDocument

@synthesize data;

+ (void)deleteURL:(NSURL *)url
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:nil byAccessor:^(NSURL *newURL) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            [fileManager removeItemAtURL:newURL error:nil];
            [fileManager release];
        }];
        [coordinator release];
    });
}

+ (void)openURL:(NSURL *)url onSuccess:(void (^)(CloudDocument *document))block
{
    CloudDocument *document = [[CloudDocument alloc] initWithFileURL:url];
    [SimpleHUD show];
    [document openWithCompletionHandler:^(BOOL success) {
        [SimpleHUD dismiss];
        if (success) {
            block(document);
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] init];
            alertView.title = @"Cloud Error";
            [alertView addButtonWithTitle:@"OK"];
            [alertView show];
            [alertView release];
        }
        [document closeWithCompletionHandler:nil];
    }];
    [document release];
}

+ (void)createURL:(NSURL *)url data:(NSData *)data
{
    CloudDocument *document = [[CloudDocument alloc] initWithFileURL:url];
    document.data = data;
    [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
        [document closeWithCompletionHandler:nil];
    }];
    [document release];
}

- (BOOL)loadFromContents:(id)contents ofType:(NSString *)typeName error:(NSError **)outError
{
    self.data = contents;
    return YES;
}

- (id)contentsForType:(NSString *)typeName error:(NSError **)outError
{
    return data;
}

- (void)changeData:(NSData *)newData
{
    if (self.documentState & UIDocumentStateInConflict) {
        [NSFileVersion removeOtherVersionsOfItemAtURL:self.fileURL error:nil];
        for (NSFileVersion* version in [NSFileVersion unresolvedConflictVersionsOfItemAtURL:self.fileURL]) {
            version.resolved = YES;
        }
    }

    self.data = newData;
    [self updateChangeCount:UIDocumentChangeDone];
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}

@end
