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

#Posting Options

Due to request, posting options are now expanded. 

* The default init is used for posting a photo which you set to originalImage

        MFRedditPostController *c = [[MFRedditPostController alloc] init];
    	c.originalImage = [UIImage imageNamed:@"sample.jpg"];
    	c.thumbnailImage = [UIImage imageNamed:@"sample_thumb.jpg"];
    	
* You can skip the Imgur upload and use your own photo link like this

        //NOTE: You are still responsible for setting a thumbnail image

        MFRedditPostController *c = [[MFRedditPostController alloc] initWithImageLink:@"http://someimagelink.com"];
        c.thumbnailImage = [UIImage imageNamed:@"sample_thumb.jpg"];
        
* You can now post just a link by using this format. This presents the UI without a thumbnail as well.

        MFRedditPostController *c = [[MFRedditPostController alloc] initForLink:@"http://somelink.com"];
        
* You now have the ability to skip my UI entirely, and just use the guts of this class to communicate with Reddit and imgur. This will get cleaner, but for now here's a bit of information on how to do that.

        //Whether link or photo, this must be called first.
        - (void)loginToRedditWithUserName:(NSString*)username andPassword:(NSString*)password;
        
        //Set these properties before calling either post function
        @property (nonatomic, retain) NSString* subreddit;
        @property (nonatomic, retain) NSString* title;
        
        //To post a link, call this method
        - (void)postLinkToReddit:(NSString*)link;
        
        //Alternatively, set this and pass nil to the method.
        @property (nonatomic, retain) NSString* linkToPost; 
        
        //To use Imgur uploading in this class, call this method. It will complete your photo post automatically.
        - (void)uploadToImgur:(UIImage*)imageToUpload
        
        //Alternatively, set originalImage and pass nil
        @property (nonatomic, retain) UIImage *originalImage;
        
* You now have the option to turn off the default UIAlertViews and register for notifications observers to use your own

        //Find me in MFRedditPostController.h 
        //Set me to 1 to use default alerts
        //Set me to 0 to turn them off
        
        #define SHOULD_USE_DEFAULT_ALERTS               1


* These are the notifications you will need to observer if creating your own UI or presenting your own notifications

       #define kRedditLoginSuccessNotification         @"reddit.login.succeeded.notification"
       #define kRedditLoginFailededNotification        @"reddit.login.failed.notification"

       #define kRedditLinkPostFailededNotification     @"reddit.link.post.failed.notification"
       #define kRedditLinkPostSuccessNotification      @"reddit.link.post.success.notification"

       #define kRedditPhotoPostFailededNotification     @"reddit.photo.post.failed.notification"
       #define kRedditPhotoPostSuccessNotification      @"reddit.photo.post.success.notification"
       
License
==================
The MFRedditPostController is licensed under the Apache License, Version 2.0.

Apache License
http://www.apache.org/licenses/LICENSE-2.0.html

Thanks to ASFBPostController from Appstair, for the inspiration for the visual theme.

Thanks to AppStair LLC
http://appstair.com
