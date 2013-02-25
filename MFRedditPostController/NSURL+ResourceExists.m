//
//  NSURL+ResourceExists.m
//  EdVOCAL
//
//  Created by Tj Fallon on 8/21/12.
//  Copyright (c) 2012 Tj Fallon. All rights reserved.
//

#import "NSURL+ResourceExists.h"

@implementation NSURL (ResourceExists)

-(void) resourceExistsCompletionBlock:(void (^)(BOOL available))completion
{
    NSURLRequest* request = [NSURLRequest requestWithURL:self cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:5.0];
    NSHTTPURLResponse* response = nil;
    NSError* error = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    NSLog(@"statusCode = %d", [response statusCode]);
    if ([response statusCode] == 404) {
        completion(NO);
    } else {
        completion(YES);
    }
}

@end
