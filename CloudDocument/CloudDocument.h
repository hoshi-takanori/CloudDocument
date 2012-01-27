//
//  CloudDocument.h
//  CloudDocument
//
//  Created by Hoshi Takanori on 12/01/28.
//  Copyright (c) 2012 -. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CloudDocument : UIDocument

@property (nonatomic, retain) NSData *data;

+ (void)deleteURL:(NSURL *)url;
+ (void)openURL:(NSURL *)url onSuccess:(void (^)(CloudDocument *document))block;
+ (void)createURL:(NSURL *)url data:(NSData *)data;

- (void)changeData:(NSData *)newData;

@end
