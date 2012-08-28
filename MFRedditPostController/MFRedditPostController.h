//
//  Copyright (c) 2012 Foley Productions LLC. All rights reserved.
//  http://appstair.com
//

#import <UIKit/UIKit.h>
#import "ImgurUploader.h"
@interface MFRedditPostController : UITableViewController <NSURLConnectionDataDelegate, UITextFieldDelegate, UITextViewDelegate, ImgurUploaderDelegate>
{
    ImgurUploader *uploader;
    IBOutlet UIProgressView *progressView;
    NSString*imgurString;
}

@property (nonatomic, retain) UIImage *originalImage;
@property (nonatomic, retain) UIImage *thumbnailImage;

@property (nonatomic, retain) ImgurUploader *uploader;
@property (nonatomic, retain) UIProgressView *progressView;


@end
