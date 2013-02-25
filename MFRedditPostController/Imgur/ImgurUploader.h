//
//  ThoughtSender.h
//  ThoughtBackDesktop
//
//  Created by Randall Brown on 11/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@protocol ImgurUploaderDelegate

-(void)imageUploadedWithURLString:(NSString*)urlString;
-(void)uploadProgressedToPercentage:(CGFloat)percentage;
-(void)uploadFailedWithError:(NSError*)error;

@end


@interface ImgurUploader : NSObject <NSXMLParserDelegate> 
{
	id<ImgurUploaderDelegate> __weak delegate;
	NSMutableData *receivedData;
	NSString* imageURL;
	NSString* currentNode;
	
	
}

-(void)uploadImage:(UIImage*)image;

@property (weak) id<ImgurUploaderDelegate> delegate;


@end
