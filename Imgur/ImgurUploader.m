//
//  ThoughtSender.m
//  ThoughtBackDesktop
//
//  Created by Randall Brown on 11/6/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ImgurUploader.h"
#import "NSString+URLEncoding.h"
#import "NSData+Base64.h"
#import <dispatch/dispatch.h>

@implementation ImgurUploader

@synthesize delegate;

-(void)uploadImage:(UIImage*)image
{
	dispatch_queue_t queue = dispatch_queue_create("com.Blocks.task",NULL);
	dispatch_queue_t main = dispatch_get_main_queue();
	
	dispatch_async(queue,^{
		NSData   *imageData  = UIImageJPEGRepresentation(image, 0.3); // High compression due to 3G.
		
		NSString *imageB64   = [imageData base64EncodingWithLineLength:0];
		imageB64 = [imageB64 encodedURLString];
		
		dispatch_async(main,^{
			
			NSString *uploadCall = [NSString stringWithFormat:@"key=%@&image=%@",@"0c6d4ce7b2f04b350573826b28fbe321",imageB64];
			
			NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://api.imgur.com/2/upload"]];
			[request setHTTPMethod:@"POST"];
			[request setValue:[NSString stringWithFormat:@"%d",[uploadCall length]] forHTTPHeaderField:@"Content-length"];
			[request setHTTPBody:[uploadCall dataUsingEncoding:NSUTF8StringEncoding]];
			
			NSURLConnection *theConnection=[[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
			if (theConnection) 
			{
				receivedData=[[NSMutableData data] retain];
			} 
			else 
			{
				
			}
			
		});
	});  		
}


-(void)dealloc
{
	[super dealloc];
	[imageURL release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[delegate uploadFailedWithError:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	[delegate uploadProgressedToPercentage:(CGFloat)totalBytesWritten/(CGFloat)totalBytesExpectedToWrite];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	//	NSString *dataString = [[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding];
	//	NSLog( @"%@", dataString );
	
	NSXMLParser* parser = [[NSXMLParser alloc] initWithData:receivedData];
	[parser setDelegate:self];
	[parser parse];
}

-(void)parserDidEndDocument:(NSXMLParser*)parser
{
	//NSLog(@"Parse Finished");
	//	NSLog(@"%@", thought);
	[delegate imageUploadedWithURLString:imageURL];
}


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	currentNode = elementName;
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	if( [currentNode isEqualToString:elementName] )
	{
		currentNode = @"";
	}
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
	if( [currentNode isEqualToString:@"original"] )
	{
		imageURL = [string retain];
	}
}

@end
