//
//  CloudDocument.m
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

#import "CloudDocument.h"
#import "SimpleHUD.h"

@implementation CloudDocument

@synthesize data;

+ (void)deleteURL:(NSURL *)url
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
        [coordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
            NSFileManager *fileManager = [[NSFileManager alloc] init];
            [fileManager removeItemAtURL:newURL error:NULL];
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
        [NSFileVersion removeOtherVersionsOfItemAtURL:self.fileURL error:NULL];
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
