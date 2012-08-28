![Example Image](http://i.imgur.com/lzZ7m.png)

MFRedditPostController
======================

#Information

This has been built for use in Ragecam Pro
http://ragecampro.com


I built this because there wasn't a simple drop in library for submitting to Reddit anywhere, and wanted it to be as easy as posting to Facebook or Twitter. Feel free to add to this, customize it, or anything you'd like.

For now this is designed to take a UIImage, upload it to Imgur, and post it to any subreddit you choose. Soon I will add extra methods to handle posting an NSUrl, or just a text post. 

#Instructions

First, copy everything from the MFRedditPostController into your project file.

Get yourself an Imgur API key here, there is a warning defined in the source to point you to where your API key needs to go.

https://imgur.com/register/api/

Be sure to include this in your delegates AppDidBecomeActive method:

	[[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

This is how you should present the controller to the user:

	- (void)showRedditPost{
  	  	MFRedditPostController *c = [[MFRedditPostController alloc] init];
    		c.thumbnailImage = [UIImage imageNamed:@"sample_thumb.jpg"];    
    		c.originalImage = [UIImage imageNamed:@"sample.jpg"];
    
   		UINavigationController *n = [[UINavigationController alloc]initWithRootViewController:c];
   		n.modalPresentationStyle = UIModalPresentationFormSheet;
		[c release];
    		[self presentModalViewController:n animated:YES];
    		[n release];
	}


License
==================
The MFRedditPostController is licensed under the Apache License, Version 2.0.

Apache License
http://www.apache.org/licenses/LICENSE-2.0.html

Thanks to ASFBPostController from Appstair, for the inspiration for the visual theme.

Thanks to AppStair LLC
http://appstair.com
