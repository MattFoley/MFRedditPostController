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



@interface MFRedditPostController ()

@property (nonatomic, assign) bool shouldEnableLogin;
@property (nonatomic, assign) bool shouldEnablePost;
@property (nonatomic, assign) bool loggedIn;

@property (nonatomic, assign) CGFloat accountCellHeight;
@property (nonatomic, retain) UIView *loginCell;
@property (nonatomic, retain) UIView *defaultCell;
@property (nonatomic, retain) UITextField *username;
@property (nonatomic, retain) UITextField *password;
@property (nonatomic, retain) UIButton *loginButton;

@property (nonatomic, retain) AlienProgressView *alien;

@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, assign) NSURLConnection *loginRequest;
@property (nonatomic, assign) NSURLConnection *postRequest;
@property (nonatomic, retain) NSString *modhash;
@property (nonatomic, retain) NSString *cookie;

@property (nonatomic, retain) NSDate *lastLoginTime;

@property (nonatomic, retain) UILabel *loginName;
@property (nonatomic, retain) UITextView *textView;
@property (nonatomic, retain) UIView *subredditField;
@property (nonatomic, retain) UIAlertView *loadingAlert;

- (void)setViewStyle;
- (void)loading:(BOOL)isLoading;
- (BOOL)isIpad;

@end


@implementation MFRedditPostController

static int kSubredditLabelTag = 42;
static int kLoginButtonTag = 420;


@synthesize username        = _username;
@synthesize password        = _password;
@synthesize loginCell       = _loginCell;
@synthesize defaultCell     = _defaultCell;
@synthesize loginButton     = _loginButton;

@synthesize shouldEnableLogin;
@synthesize shouldEnablePost;
@synthesize loggedIn;

@synthesize alien           = _alien;
@synthesize loginRequest    = _loginRequest;
@synthesize postRequest     = _postRequest;
@synthesize modhash         = _modhash;
@synthesize responseData    = _responseData;
@synthesize lastLoginTime   = _lastLoginTime;


@synthesize accountCellHeight = _accountCellHeight;

@synthesize loginName       = _loginName;
@synthesize textView        = _textView;
@synthesize loadingAlert    = _loadingAlert;
@synthesize originalImage   = _originalImage;
@synthesize thumbnailImage  = _thumbnailImage;

@synthesize progressView, uploader;

- (void)viewDidUnload{
    [super viewDidUnload];
}

- (void)dealloc{

    [_loginName release], _loginName = nil;
    [_textView release], _textView = nil;
    [_loadingAlert release], _loadingAlert = nil;
    [_thumbnailImage release], _thumbnailImage = nil;
    [_originalImage release], _originalImage = nil;
    [super dealloc];
}

- (id)init{
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
    btn = [[UIBarButtonItem alloc]
           initWithTitle:NSLocalizedString(@"MF_POST", @"")
           style:UIBarButtonItemStyleBordered
           target:self
           action:@selector(uploadToImgur)];
    self.navigationItem.rightBarButtonItem = btn;
    [btn release];
    
    btn = [[UIBarButtonItem alloc]
           initWithTitle:NSLocalizedString(@"MF_CANCEL", @"")
           style:UIBarButtonItemStyleBordered
           target:self 
           action:@selector(dismissSelf)];
    self.navigationItem.leftBarButtonItem = btn;
    [btn release];
    
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

- (void)postPhotoToReddit:(NSString*)imgLink
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alien startAnimating];
    });
    
    NSString *subreddit = [[NSString alloc]initWithString:[(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text]];
    
    NSString *title = [[NSString alloc]initWithString:self.textView.text];
    
    
    NSString *urlString = [NSString stringWithFormat:@"http://www.reddit.com/api/submit"];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    [request setHTTPMethod:@"POST"];
    
    NSString*httpBody = [NSString stringWithFormat:@"uh=%@&url=%@&kind=link&sr=%@&title=%@&r=%@&api_type=json",self.modhash, @"http://google.com", [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [title stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], [subreddit stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    
    
    [request setHTTPBody:[httpBody dataUsingEncoding:NSASCIIStringEncoding]];
    
    self.postRequest = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    [self.postRequest start];

}

- (void)storeCookies{
    NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
    [cookieProperties setObject:@"c" forKey:NSHTTPCookieName];
    [cookieProperties setObject:self.cookie forKey:NSHTTPCookieValue];
    [cookieProperties setObject:@"www.reddit.com" forKey:NSHTTPCookieDomain];
    [cookieProperties setObject:@"www.reddit.com" forKey:NSHTTPCookieOriginURL];
    [cookieProperties setObject:@"/" forKey:NSHTTPCookiePath];
    [cookieProperties setObject:@"0" forKey:NSHTTPCookieVersion];
    
    // set expiration to one month from now or any NSDate of your choosing
    // this makes the cookie sessionless and it will persist across web sessions and app launches
    /// if you want the cookie to be destroyed when your app exits, don't set this
    [cookieProperties setObject:[[NSDate date] dateByAddingTimeInterval:2629743] forKey:NSHTTPCookieExpires];
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
}

- (void)loginToReddit
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alien startAnimating];
    });
    
    NSString *user = [[NSString alloc]initWithString:_username.text];
    NSString *passwd = [[NSString alloc]initWithString:_password.text];


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
    
    if ( [responseJSON objectForKey:@"data"])
    {
        self.loggedIn = TRUE;
        self.modhash = [NSString stringWithString:[[responseJSON objectForKey:@"data"] objectForKey:@"modhash"]];
        self.cookie = [NSString stringWithString:[[responseJSON objectForKey:@"data"] objectForKey:@"cookie"]];
        [self storeCookies];
        [self flipBackLogin];
        
        self.responseData = nil;
        self.lastLoginTime = [NSDate date];

    }
    else
    {
        [[[[UIAlertView alloc]initWithTitle:@"Login Failed" message:@"Incorrect Username/Password combination, please try again" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease]show];
        self.modhash = @"";
        self.lastLoginTime = nil;
    }

}

- (void)postProbablySucceeded:(NSDictionary*)json{
    if ([[[json objectForKey:@"json"]objectForKey:@"data"]objectForKey:@"url"]) {
        [[[[UIAlertView alloc]initWithTitle:@"Success" message:@"Your post was successfully submitted to Reddit!" delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease]show];
    }else if([[[[[json objectForKey:@"json"]objectForKey:@"errors"]objectAtIndex:0]objectAtIndex:0]isEqualToString:@"RATELIMIT"]){
        
     [[[[UIAlertView alloc]initWithTitle:@"Rate Limit" message:[NSString stringWithFormat:@"%@", [[[[json objectForKey:@"json"]objectForKey:@"errors"]objectAtIndex:0]objectAtIndex:1]] delegate:nil cancelButtonTitle:@"Shucks." otherButtonTitles:nil] autorelease]show];
    }else{
        [[[[UIAlertView alloc]initWithTitle:@"Error" message:[NSString stringWithFormat:@"That subreddit may not exist, or Reddit may be down, but your image was still uploaded to %@", imgurString] delegate:nil cancelButtonTitle:@"Shucks." otherButtonTitles:nil] autorelease]show];
    }
}

- (void)uploadToImgur
{
    [UIView animateWithDuration:.3 animations:^{
        [self.progressView setAlpha:1];
    }];
    
    NSString *subreddit = [[NSString alloc]initWithString:[(UILabel*)[self.subredditField viewWithTag:kSubredditLabelTag]text]];
    
    NSURL*srURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://reddit.com/r/%@", subreddit]];
    
    [srURL resourceExistsCompletionBlock:^(BOOL available) {
        if (available) {
            [uploader uploadImage:self.originalImage];
        }else{
            [self.progressView setAlpha:0];
            [[[[UIAlertView alloc]initWithTitle:@"Reddit Error" message:@"That reddit doesn't exist, or Reddit is down." delegate:nil cancelButtonTitle:@"Shucks." otherButtonTitles:nil] autorelease]show];
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
    [name release];
    
    
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
    [self.loginButton addTarget:self action:@selector(loginToReddit) forControlEvents:UIControlEventTouchUpInside];
    [self.loginButton setFrame:CGRectMake(edgepadding+(self.tableView.frame.size.width/2-(CELL_PADDING/2+edgepadding+centerPadding)), 20+25, centerPadding*2, 29)];
    [self setupNotifications];
    [_loginCell addSubview:self.loginButton];
    
    
}

- (void)createMessageCell:(UITableViewCell*)cell
{
    CGFloat thumbSize = [self isIpad] ? 100 : 60;
    CGFloat textSzie = [self isIpad] ? 348 : 210;
    
    UIImageView *_back = [[UIImageView alloc] initWithFrame:CGRectMake(10, 10, thumbSize, thumbSize)];
    _back.image = self.thumbnailImage;
    
    progressView = [[UIProgressView alloc]initWithProgressViewStyle:UIProgressViewStyleBar];
    [progressView setAlpha:.0];
    [progressView setProgressTintColor:[UIColor colorWithHex:0xff7a10]];
    [progressView setFrame:CGRectMake(10, 10+thumbSize, thumbSize, 10)];
    
    [cell.contentView addSubview:progressView];
    
    [cell.contentView addSubview:_back];
    [_back release];
    
    if(!self.textView){
        UITextView *tv = [[UITextView alloc] initWithFrame:CGRectMake(thumbSize + 20, 10, textSzie, thumbSize)];
        tv.font = [UIFont systemFontOfSize:16];
        tv.backgroundColor = [UIColor colorWithHex:0xefefef];
        self.textView = tv;
        [tv release];
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
        [tv setPlaceholder:@"/r/subreddit"];
        tv.font = [UIFont systemFontOfSize:16];
        [tv setTextAlignment:UITextAlignmentRight];
        [tv setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        [tv setBorderStyle:UITextBorderStyleNone];
        [tv setBackgroundColor:[UIColor clearColor]];
        [tv setTag:kSubredditLabelTag];
        [tvBorder addSubview:tv];
        self.subredditField = tvBorder;
        [tv release];
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
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"indexCell"] autorelease];
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
    NSString*responsestring = [[[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding] autorelease];
    NSLog(@"%@", [responsestring description]);
    
    if (self.responseStatusCode == 200) {

        if (connection == _loginRequest) {
            [self loginProbablySucceeded:json];
        }else{
            [self postProbablySucceeded:json];
        }
    }else{
        [[[[UIAlertView alloc]initWithTitle:@"Error" message:@"Sorry, either we dropped the ball, their servers are down, or you aren't connected to the internet. We just don't know!" delegate:nil cancelButtonTitle:@"Awh, hell." otherButtonTitles:nil] autorelease]show];
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
	[self postPhotoToReddit:urlString];
}

-(void)uploadFailedWithError:(NSError *)error
{
	[[[[UIAlertView alloc]initWithTitle:@"Imgur Failue" message:@"Your photo was not uploaded to Imgur, it may be down. Try again later." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil] autorelease]show];
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
        [_alien release];
        _alien = nil;
    }
    
    [progressView release];
    progressView = nil;
    
    _subredditField = nil;
    _username = nil;
    _password = nil;
    

    [_loginCell release];
    _loginCell = nil;
    

    [_defaultCell release];
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

@end
