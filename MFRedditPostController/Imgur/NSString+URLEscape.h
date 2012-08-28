//
//  NSString+URLEscape.h
//  ThoughtBackDesktop
//
//  Created by Randall Brown on 1/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSString(NSString_URLEscape)

-(NSString*)stringByEscapingValidURLCharacters;

@end
