//
//  Copyright (c) 2012 Foley Productions LLC. All rights reserved.
//  http://appstair.com
//

#import <UIKit/UIKit.h>
#import "ImgurUploader.h"

//Set me to 0 to receive notifications and take control of handling success/failure
#define SHOULD_USE_DEFAULT_ALERTS               1

#define kRedditLoginSuccessNotification         @"reddit.login.succeeded.notification"
#define kRedditLoginFailededNotification        @"reddit.login.failed.notification"

#define kRedditLinkPostFailededNotification     @"reddit.link.post.failed.notification"
#define kRedditLinkPostSuccessNotification      @"reddit.link.post.success.notification"

#define kRedditPhotoPostFailededNotification     @"reddit.photo.post.failed.notification"
#define kRedditPhotoPostSuccessNotification      @"reddit.photo.post.success.notification"

@interface MFRedditPostController : UITableViewController <NSURLConnectionDataDelegate, UITextFieldDelegate, UITextViewDelegate, ImgurUploaderDelegate>
{
    ImgurUploader *uploader;
    IBOutlet UIProgressView *progressView;
    NSString*imgurString;
}

@property (nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UIImage *thumbnailImage;

@property (nonatomic, strong) ImgurUploader *uploader;
@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) NSString* subreddit;
@property (nonatomic, strong) NSString* title;

@property (nonatomic, strong) NSString* linkToPost;

- (id)initForPhoto;
- (id)initWithImageLink:(NSString*)photoLink;
- (id)initForLink:(NSString*)string;

- (void)uploadToImgur:(UIImage*)imageToUpload;
- (void)loginToRedditWithUserName:(NSString*)username andPassword:(NSString*)password;
- (void)postLinkToReddit:(NSString*)link;

@end
