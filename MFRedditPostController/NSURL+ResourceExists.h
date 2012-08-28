//
//  NSURL+ResourceExists.h
//  EdVOCAL
//
//  Created by Tj Fallon on 8/21/12.
//  Copyright (c) 2012 Tj Fallon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (ResourceExists)
-(void) resourceExistsCompletionBlock:(void (^)(BOOL available))completion;
@end
