//
//  Copyright (c) 2012 Foley Productions LLC. All rights reserved.
//  http://appstair.com
//

#define CELL_PADDING        ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 62 : 20)

#import "MFRedditPostController.h"
#import "AppDelegate.h"
#import "ASColor+Hex.h"
#import "AlienProgressView.h"
#import "NSURL+ResourceExists.h"
#import "SSTextView.h"



@interface MFRedditPostController ()

@property (nonatomic, assign) bool shouldEnableLogin;
@property (nonatomic, assign) bool shouldEnablePost;
@property (nonatomic, assign) bool loggedIn;
@property (nonatomic, assign) bool shouldPostPhoto;

@property (nonatomic, assign) CGFloat accountCellHeight;
@property (nonatomic, strong) UIView *loginCell;
@property (nonatomic, strong) UIView *defaultCell;
@property (nonatomic, strong) UITextField *username;
@property (nonatomic, strong) UITextField *password;
@property (nonatomic, strong) UIButton *loginButton;

@property (nonatomic, strong) AlienProgressView *alien;

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, strong) NSURLConnection *loginRequest;
@property (nonatomic, strong) NSURLConnection *postRequest;
@property (nonatomic, strong) NSString *modhash;
@property (nonatomic, strong) NSString *cookie;

@property (nonatomic, strong) NSDate *lastLoginTime;

@property (nonatomic, strong) UILabel *loginName;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIView *subredditField;
@property (nonatomic, strong) UIAlertView *loadingAlert;

- (void)setViewStyle;
- (void)loading:(BOOL)isLoading;
- (BOOL)isIpad;

@end


@implementation MFRedditPostController

static int kSubredditLabelTag = 42;
static int kLoginButtonTag = 420;

@synthesize shouldEnableLogin;
@synthesize shouldEnablePost;
@synthesize loggedIn;

@synthesize progressView, uploader;

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (void)dealloc{
    
    _loginName = nil;
    _textView = nil;
    _loadingAlert = nil;
    _thumbnailImage = nil;
    _originalImage = nil;
}

- (id)init{
    imgurString = nil;
    _shouldPostPhoto = YES;
    if(self = [super initWithStyle:UITableViewStyleGrouped]){
        self.title = @"Reddit";
    }
    return self;
}

- (id)initForPhoto{
    imgurString = nil;
    _shouldPostPhoto = YES;
    if(self = [super initWithStyle:UITableViewStyleGrouped]){
        self.title = @"Reddit";
    }
    return self;
}

- (id)initWithImageLink:(NSString*)photoLink{
    _shouldPostPhoto = YES;
    imgurString = photoLink;
    
    if(self = [super initWithStyle:UITableViewStyleGrouped]){
        self.title = @"Reddit";
    }
    return self;
}

- (id)initForLink:(NSString *)string{
    imgurString = nil;
    _shouldPostPhoto = NO;
    _linkToPost = string;
    if(self = [super initWithStyle:UITableViewStyleGrouped]){
        self.title = @"Reddit";
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark View LifeCycle
///////////////////////////////////////////////////////////////////////////////////////////////////


- (void)viewDidLoad{
    
    [super viewDidLoad];
    
    _accountCellHeight = 45;
    
    self.tableView.backgroundColor = [UIColor colorWithHex:0xE1E6EF];
    self.tableView.scrollEnabled = NO;
    
    // navi buttons
    UIBarButtonItem *btn;
    if (self.shouldPostPhoto && imgurString == nil) {
        btn = [[UIBarButtonItem alloc]
               initWithTitle:NSLocalizedString(@"MF_POST", @"")
               style:UIBarButtonItemStyleBordered
               target:self
               action:@selector(uploadToImgur:)];
    }else{
        btn = [[UIBarButtonItem alloc]
               initWithTitle:NSLocalizedString(@"MF_POST", @"")
               style:UIBarButtonItemStyleBordered
               target:self
               action:@selector(postLinkToReddit:)];
    }
    
    self.navigationItem.rightBarButtonItem = btn;
    
    btn = [[UIBarButtonItem alloc]
           initWithTitle:NSLocalizedString(@"MF_CANCEL", @"")
           style:UIBarButtonItemStyleBordered
           target:self
           action:@selector(dismissSelf)];
    self.navigationItem.leftBarButtonItem = btn;
    
    uploader = [[ImgurUploader alloc] init];
	uploader.delegate = self;
    loggedIn = NO;
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setViewStyle];
}

- (void)viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
    [self setViewStyle];
    [[self.subredditField viewWithTag:kSubredditLabelTag] becomeFirstResponder];
}

- (void)setViewStyle{
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithHex:0x2C4287];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    if([self isIpad]){
        return YES;
    }
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}




- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    return YES;
}

#pragma mark Animations

- (void)presentLoginView
{
    _accountCellHeight = 80;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [UIView transitionWithView:_loginCell.superview duration:1 options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
        [_defaultCell setHidden:YES];
        [_loginCell setHidden:NO];
        
    } completion:^(BOOL finished) {
        [_username becomeFirstResponder];
    }];
}

- (void)flipBackLogin
{
    self.loginName.text = [NSString stringWithFormat:@"Login successful - Welcome, %@.", _username.text];
    
    _accountCellHeight = 45;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    [_username resignFirstResponder];
    [_password resignFirstResponder];
    
    UIButton *loginButton = (UIButton*)[_defaultCell viewWithTag:kLoginButtonTag];
    CGRect oldRect = loginButton.frame;
    [loginButton removeFromSuperview];
    
    UIImageView*orangeRed = [[UIImageView alloc]initWithFrame:oldRect];
    [orangeRed setContentMode:UIViewContentModeScaleAspectFit];
    [orangeRed setImage:[UIImage imageNamed:@"Reddit_Envelope_Clear"]];
    [orangeRed setCenter:CGPointMake(orangeRed.center.x+40, orangeRed.center.y)];
    [_defaultCell addSubview:orangeRed];
    
    [UIView transitionWithView:_loginCell.superview duration:1 options:UIViewAnimationOptionTransitionFlipFromTop animations:^{
        
        [_defaultCell setHidden:NO];
        [_loginCell setHidden:YES];
        
    } completion:^(BOOL finished) {
    }];
}

#pragma mark Reddit Guts

- (void)postPhotoToReddit
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alien startAnimating];
    });
    
    NSString *subreddit;
    if (self.subreddit) {
        subreddit = self.subreddit;
    }else{
        subreddit = [[NSString alloc]initWithString:[(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text]];
    }
    
    NSString *title;
    if (self.title) {
        title = self.title;
    }else{
        title = [[NSString alloc]initWithString:self.textView.text];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://www.reddit.com/api/submit"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    
    NSString*httpBody = [NSString stringWithFormat:@"uh=%@&url=%@&kind=link&sr=%@&title=%@&r=%@&api_type=json",self.modhash, imgurString, [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    
    [request setHTTPBody:[httpBody dataUsingEncoding:NSASCIIStringEncoding]];
    
    self.postRequest = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.postRequest start];
}

- (void)postLinkToReddit:(NSString*)link
{
    
    if (![link isKindOfClass:[NSString class]]) {
        link = self.linkToPost;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alien startAnimating];
    });
    
    NSString *subreddit;
    if (self.subreddit) {
        subreddit = self.subreddit;
    }else{
        subreddit = [[NSString alloc]initWithString:[(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text]];
    }
    
    NSString *title;
    if (self.title) {
        title = self.title;
    }else{
        title = [[NSString alloc]initWithString:self.textView.text];
    }
    
    
    
    NSString *urlString = [NSString stringWithFormat:@"http://www.reddit.com/api/submit"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    [request setHTTPMethod:@"POST"];
    
    NSString*httpBody = [NSString stringWithFormat:@"uh=%@&url=%@&kind=link&sr=%@&title=%@&r=%@&api_type=json",self.modhash, link, [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    
    [request setHTTPBody:[httpBody dataUsingEncoding:NSASCIIStringEncoding]];
    
    self.postRequest = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.postRequest start];
}

- (void)storeCookies{
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    cookieProperties[NSHTTPCookieName] = @"c";
    cookieProperties[NSHTTPCookieValue] = self.cookie;
    cookieProperties[NSHTTPCookieDomain] = @"www.reddit.com";
    cookieProperties[NSHTTPCookieOriginURL] = @"www.reddit.com";
    cookieProperties[NSHTTPCookiePath] = @"/";
    cookieProperties[NSHTTPCookieVersion] = @"0";
    
    // set expiration to one month from now or any NSDate of your choosing
    // this makes the cookie sessionless and it will persist across web sessions and app launches
    /// if you want the cookie to be destroyed when your app exits, don't set this
    cookieProperties[NSHTTPCookieExpires] = [[NSDate date] dateByAddingTimeInterval:2629743];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

- (void)loginToRedditWithUserName:(NSString*)username andPassword:(NSString*)password
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alien startAnimating];
    });
    NSString *passwd;
    NSString *user;
    
    if ([username isKindOfClass:[NSString class]] && [password isKindOfClass:[NSString class]] ) {
        user = username;
        passwd = password;
    }else{
        user = [[NSString alloc]initWithString:_username.text];
        passwd = [[NSString alloc]initWithString:_password.text];
    }
    
    NSString *urlString = [NSString stringWithFormat:@"http://www.reddit.com/api/login"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    
    NSString *contentType = [NSString stringWithFormat:@"application/x-www-form-urlencoded;"];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    [request setHTTPMethod:@"POST"];
    NSString*httpBody = [NSString stringWithFormat:@"rem=on&passwd=%@&user=%@&api_type=json",
                         [passwd stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding],
                         [user stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSASCIIStringEncoding]];
    
    _loginRequest = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.loginRequest start];
    
}

- (void)loginProbablySucceeded:(NSDictionary*)json
{
    NSDictionary *responseJSON = [json valueForKey:@"json"];
    [_alien performSelectorOnMainThread:@selector(stopAnimating) withObject:nil waitUntilDone:NO];
    
    if ( responseJSON[@"data"])
    {
        self.loggedIn = TRUE;
        self.modhash = [NSString stringWithString:responseJSON[@"data"][@"modhash"]];
        self.cookie = [NSString stringWithString:responseJSON[@"data"][@"cookie"]];
        [self storeCookies];
        [self flipBackLogin];
        
        self.responseData = nil;
        self.lastLoginTime = [NSDate date];
        
    }else{
        if (SHOULD_USE_DEFAULT_ALERTS) {
            [[[UIAlertView alloc]initWithTitle:@"Login Failed"
                                        message:@"Incorrect Username/Password combination, please try again"
                                       delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil]show];
        }else{
            [self sendNotificationNamed:kRedditLoginFailededNotification];
        }
        self.modhash = @"";
        self.lastLoginTime = nil;
    }
    
}

- (void)postProbablySucceeded:(NSDictionary*)json{
    if (json[@"json"][@"data"][@"url"]) {
        
        if (SHOULD_USE_DEFAULT_ALERTS) {
            [[[UIAlertView alloc]initWithTitle:@"Success"
                                        message:@"Your post was successfully submitted to Reddit!"
                                       delegate:nil
                              cancelButtonTitle:@"Okay"
                              otherButtonTitles:nil]show];
        }else{
            if (self.shouldPostPhoto) {
                [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
            }else{
                [self sendNotificationNamed:kRedditLinkPostFailededNotification];
            }
        }
    }else if([json[@"json"][@"errors"][0][0]isEqualToString:@"RATELIMIT"]){
        
        if (SHOULD_USE_DEFAULT_ALERTS) {
            [[[UIAlertView alloc]initWithTitle:@"Rate Limit"
                                        message:[NSString stringWithFormat:@"%@", json[@"json"][@"errors"][0][1]]
                                       delegate:nil
                              cancelButtonTitle:@"Shucks."
                              otherButtonTitles:nil]show];
        }else{
            if (self.shouldPostPhoto) {
                [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
            }else{
                [self sendNotificationNamed:kRedditLinkPostFailededNotification];
            }
        }
        
    }else{
        
        if (SHOULD_USE_DEFAULT_ALERTS) {
            if (self.shouldPostPhoto) {
                [[[UIAlertView alloc]initWithTitle:@"Error"
                                            message:[NSString stringWithFormat:@"That subreddit may not exist, or Reddit may be down, but your image was still uploaded to %@", imgurString]
                                           delegate:nil
                                  cancelButtonTitle:@"Shucks."
                                  otherButtonTitles:nil]show];
            }else{
                [[[UIAlertView alloc]initWithTitle:@"Error"
                                            message:@"That subreddit may not exist, or Reddit may be down, so your link wasn't posted. Sorry."
                                           delegate:nil
                                  cancelButtonTitle:@"Shucks."
                                  otherButtonTitles:nil]show];
            }
        }else{
            if (self.shouldPostPhoto) {
                [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
            }else{
                [self sendNotificationNamed:kRedditLinkPostFailededNotification];
            }
        }
    }
}

- (void)uploadToImgur:(UIImage*)imageToUpload
{
    [UIView animateWithDuration:.3 animations:^{
        [self.progressView setAlpha:1];
    }];
    
    NSString *subreddit;
    if (self.subreddit) {
        subreddit = self.subreddit;
    }else{
        subreddit = [[NSString alloc]initWithString:[(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text]];
    }
    
    NSURL*srURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://reddit.com/r/%@", subreddit]];
    
    [srURL resourceExistsCompletionBlock:^(BOOL available) {
        if (available) {
            if ([imageToUpload isKindOfClass:[UIImage class]]) {
                [uploader uploadImage:imageToUpload];
            }else{
                [uploader uploadImage:self.originalImage];
            }
        }else{
            [self.progressView setAlpha:0];
            
            if (SHOULD_USE_DEFAULT_ALERTS) {
                [[[UIAlertView alloc]initWithTitle:@"Reddit Error"
                                            message:@"That reddit doesn't exist, or Reddit is down."
                                           delegate:nil
                                  cancelButtonTitle:@"Shucks."
                                  otherButtonTitles:nil]show];
            }else{
                
                if (self.shouldPostPhoto) {
                    [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
                }else{
                    [self sendNotificationNamed:kRedditLinkPostFailededNotification];
                }
            }
            
        }
    }];
}

#pragma mark Custom Cells

- (void)createAccountView:(UITableViewCell*)cell
{
    [self createDefaultView];
    [self createLoginView];
    
    [cell.contentView addSubview:self.defaultCell];
    [cell.contentView addSubview:self.loginCell];
    
    [self.loginCell setHidden:YES];
}

- (void)createDefaultView
{
    _defaultCell = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 45)];
    [_defaultCell setBackgroundColor:[UIColor clearColor]];
    
    UILabel *name = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, self.tableView.frame.size.width-80, 45)];
    [name setAdjustsFontSizeToFitWidth:YES];
    [name setFont:[UIFont systemFontOfSize:15]];
    [name setBackgroundColor:[UIColor clearColor]];
    [name setText:NSLocalizedString(@"MF_NEED_LOGIN", @"")];
    
    [self.defaultCell addSubview:name];
    self.loginName = name;
    
    
    UIImage* image = [UIImage imageNamed:@"loginToReddit.png"];
    UIButton *_btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn addTarget:self action:@selector(presentLoginView) forControlEvents:UIControlEventTouchUpInside];
    [_btn setBackgroundImage:image forState:UIControlStateNormal];
    [_btn setTag:kLoginButtonTag];
    
    CGFloat padding = (45/2)-(image.size.height/2);
    [_btn setFrame:CGRectMake((self.tableView.frame.size.width-CELL_PADDING)-(padding+image.size.width), padding, image.size.width, image.size.height)];
    
    [_defaultCell addSubview:_btn];
}

- (void)createLoginView
{
    
    CGFloat textSize = [self isIpad] ? 200 : 120;
    CGFloat edgepadding = 10;
    CGFloat centerPadding = self.tableView.frame.size.width-((textSize*2)+(edgepadding*2));
    
    _loginCell = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 100)];
    [_loginCell setBackgroundColor:[UIColor clearColor]];
    
    UIView* tvBorder = [[UIView alloc]initWithFrame:CGRectMake(edgepadding, 6, textSize, 29)];
    [tvBorder setBackgroundColor:[UIColor colorWithHex:0xefefef]];
    
    UITextField *tv = [[UITextField alloc] initWithFrame:CGRectMake(5, 4, textSize-10, 21)];
    [tv setPlaceholder:@"Username"];
    [tv setDelegate:self];
    [tv setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    tv.font = [UIFont systemFontOfSize:16];
    [tv setTextAlignment:UITextAlignmentCenter];
    [tv setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [tv setBorderStyle:UITextBorderStyleNone];
    [tv setBackgroundColor:[UIColor clearColor]];
    [tvBorder addSubview:tv];
    
    _username = tv;
    [_loginCell addSubview:tvBorder];
    
    
    CGFloat passOrigin = edgepadding + centerPadding + textSize;
    tvBorder = [[UIView alloc]initWithFrame:CGRectMake(passOrigin-CELL_PADDING, 6, textSize, 29)];
    [tvBorder setBackgroundColor:[UIColor colorWithHex:0xefefef]];
    
    tv = [[UITextField alloc] initWithFrame:CGRectMake(5, 4, textSize-10, 21)];
    
    [tv setPlaceholder:@"Password"];
    [tv setDelegate:self];
    [tv setSecureTextEntry:YES];
    [tv setAutocapitalizationType:UITextAutocapitalizationTypeNone];
    tv.font = [UIFont systemFontOfSize:16];
    [tv setTextAlignment:UITextAlignmentCenter];
    [tv setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
    [tv setBorderStyle:UITextBorderStyleNone];
    [tv setBackgroundColor:[UIColor clearColor]];
    [tvBorder addSubview:tv];
    
    _password = tv;
    [_loginCell addSubview:tvBorder];
    
    
    _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.loginButton setImage:[UIImage imageNamed:@"loginToReddit@2x.png"] forState:UIControlStateNormal];
    [self.loginButton setImage:[UIImage imageNamed:@"loginDisabled@2x.png"] forState:UIControlStateDisabled];
    [self.loginButton setImage:[UIImage imageNamed:@"loginPressed.png"] forState:UIControlStateHighlighted];
    [self.loginButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [self.loginButton setEnabled:NO];
    [self.loginButton addTarget:self action:@selector(loginToRedditWithUserName:andPassword:) forControlEvents:UIControlEventTouchUpInside];
    [self.loginButton setFrame:CGRectMake(edgepadding+(self.tableView.frame.size.width/2-(CELL_PADDING/2+edgepadding+centerPadding)), 20+25, centerPadding*2, 29)];
    [self setupNotifications];
    [_loginCell addSubview:self.loginButton];
    
    
}

- (void)createMessageCell:(UITableViewCell*)cell
{
    CGFloat thumbSize = [self isIpad] ? 100 : 60;
    CGFloat textSzie = [self isIpad] ? 348 : 210;
    
    
    progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    [progressView setAlpha:.0];
    [progressView setProgressTintColor:[UIColor colorWithHex:0xff7a10]];
    [progressView setFrame:CGRectMake(10, 10+thumbSize, thumbSize, 10)];
    
    [cell.contentView addSubview:progressView];
    
    if (self.shouldPostPhoto) {
        UIImageView *_back = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, thumbSize, thumbSize)];
        _back.image = self.thumbnailImage;
        [cell.contentView addSubview:_back];
    }
    
    if(!self.textView){
        SSTextView *tv;
        
        if (self.shouldPostPhoto) {
            tv = [[SSTextView alloc] initWithFrame:CGRectMake(thumbSize + 20, 10, textSzie, thumbSize)];
        }else{
            tv = [[SSTextView alloc] initWithFrame:CGRectMake(10, 10, textSzie+thumbSize+10, thumbSize)];
        }
        
        tv.placeholder = @"Title 0/300";
        
        tv.font = [UIFont systemFontOfSize:16];
        tv.backgroundColor = [UIColor colorWithHex:0xefefef];
        self.textView = tv;
    }else{
        [self.textView removeFromSuperview];
    }
    [cell.contentView addSubview:self.textView];
}

- (void)createSubredditCell:(UITableViewCell*)cell
{
    
    CGFloat paddingSize = [self isIpad] ? 100 : 60;
    CGFloat textSize = [self isIpad] ? 348 : 210;
    
    if (!self.alien) {
        _alien = [[AlienProgressView alloc]initWithFrame:CGRectMake((paddingSize/2+10)-15, 2, 30, 40)];
        [cell.contentView addSubview:_alien];
    }
    
    UIView*tvBorder;
    if(!self.subredditField){
        tvBorder = [[UIView alloc]initWithFrame:CGRectMake(paddingSize + 20, 8, textSize, 29)];
        [tvBorder setBackgroundColor:[UIColor colorWithHex:0xefefef]];
        
        UITextField *tv = [[UITextField alloc] initWithFrame:CGRectMake(15, 4, textSize-20, 21)];
        [tv setPlaceholder:@"/r/subreddit (ie: 'askreddit' or 'ragecam')"];
        tv.font = [UIFont systemFontOfSize:16];
        [tv setTextAlignment:UITextAlignmentRight];
        [tv setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [tv setBorderStyle:UITextBorderStyleNone];
        [tv setBackgroundColor:[UIColor clearColor]];
        [tv setTag:kSubredditLabelTag];
        [tvBorder addSubview:tv];
        self.subredditField = tvBorder;
    }
    [cell.contentView addSubview:self.subredditField];
    
}

#pragma mark UITableView


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.row == 0){
        return _accountCellHeight;
    }else if(indexPath.row == 1){
        return 45;
    }
    return [self isIpad] ? 120 : 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"indexCell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"indexCell"];
        cell.textLabel.font = [UIFont systemFontOfSize:14];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
 	}
    
    
    if(indexPath.row == 0){
        // Account
        [self createAccountView:cell];
        
    }else if(indexPath.row == 1){
        //Subreddit
        [self createSubredditCell:cell];
    }else{
        // message
        [self createMessageCell:cell];
    }
	return cell;
}

#pragma mark NSURLConnection Delegate
- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSError *error = nil;
    
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:self.responseData options:NSJSONReadingAllowFragments error:&error];
    NSString*responsestring = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", [responsestring description]);
    self.responseData = nil;
    
    if (self.responseStatusCode == 200) {
        
        if (connection == _loginRequest) {
            [self loginProbablySucceeded:json];
        }else{
            [self postProbablySucceeded:json];
        }
    }else{
        if (SHOULD_USE_DEFAULT_ALERTS) {
            [[[UIAlertView alloc]initWithTitle:@"Error"
                                        message:@"Sorry, either we dropped the ball, their servers are down, or you aren't connected to the internet. We just don't know!"
                                       delegate:nil
                              cancelButtonTitle:@"Awh, hell."
                              otherButtonTitles:nil]show];
        }else{
            if (connection == _loginRequest) {
                [self sendNotificationNamed:kRedditLoginFailededNotification];
            }else if(self.shouldPostPhoto){
                [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
            }else{
                [self sendNotificationNamed:kRedditLinkPostFailededNotification];
            }
        }
        
        
    }
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (!self.responseData) {
        self.responseData = [NSMutableData dataWithData:data];
    }
    else {
        [self.responseData appendData:data];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    self.responseStatusCode = [response statusCode];
}

#pragma mark ImgurDelegate

-(void)imageUploadedWithURLString:(NSString*)urlString
{
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationCurveLinear animations:^{
        [self.progressView setAlpha:0];
    } completion:^(BOOL finished) {
        [_alien performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];
    }];
    imgurString = urlString;
	[self postPhotoToReddit];
}

-(void)uploadFailedWithError:(NSError *)error
{
    if (SHOULD_USE_DEFAULT_ALERTS) {
        [[[UIAlertView alloc]initWithTitle:@"Imgur Failue"
                                    message:@"Your photo was not uploaded to Imgur, it may be down. Try again later."
                                   delegate:nil
                          cancelButtonTitle:@"Okay"
                          otherButtonTitles:nil]show];
    }else{
        [self sendNotificationNamed:kRedditPhotoPostFailededNotification];
    }
}

-(void)uploadProgressedToPercentage:(CGFloat)percentage
{
	progressView.hidden = !( percentage > 0.0 && percentage < 1.0 );
	progressView.progress = percentage;
}

#pragma mark Utils

- (void)dismissSelf{
    
    if (_alien) {
        [_alien stopAnimating];
        [_alien removeFromSuperview];
        _alien = nil;
    }
    
    progressView = nil;
    
    _subredditField = nil;
    _username = nil;
    _password = nil;
    
    
    _loginCell = nil;
    
    
    _defaultCell = nil;
    
    [self dismissModalViewControllerAnimated:YES];
}

- (void)setupNotifications
{
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextViewTextDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [self.navigationItem.rightBarButtonItem setEnabled:[self shouldEnablePost]];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UITextFieldTextDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      [self.navigationItem.rightBarButtonItem setEnabled:[self shouldEnablePost]];
                                                      
                                                      if (self.username != nil) {
                                                          _loginButton.enabled = [self shouldEnableLogin];
                                                          
                                                      }
                                                  }];
}

- (bool)shouldEnableLogin
{
    return (self.username.text.length>0 && self.password.text.length>0);
}

- (bool)shouldEnablePost
{
    return ([(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text].length>0 && self.textView.text.length >0 && self.loggedIn);
}


- (BOOL)isIpad{
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

#pragma mark Notifications

- (void)sendNotificationNamed:(NSString*)noteName
{
    [[NSNotificationCenter defaultCenter]postNotification:noteName];
}

@end
