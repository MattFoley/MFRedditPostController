//
//  Copyright (c) 2012 Foley Productions LLC. All rights reserved.
//

#import "MainController.h"
#import "MFRedditPostController.h"


@implementation MainController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    UIButton *_btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_btn setTitle:@"Open" forState:UIControlStateNormal];
    [_btn addTarget:self action:@selector(showRedditPost) forControlEvents:UIControlEventTouchUpInside];
    [_btn setFrame:CGRectMake(10, 10, 140, 40)];
    [self.view addSubview:_btn];
}

- (void)showRedditPost{
    MFRedditPostController *c = [[MFRedditPostController alloc] initForLink:@"http://www.notgoogle.com"];
    //c.thumbnailImage = [UIImage imageNamed:@"sample_thumb.jpg"];
    //c.originalImage = [UIImage imageNamed:@"sample.jpg"];
    
    UINavigationController *n = [[UINavigationController alloc] initWithRootViewController:c];
    n.modalPresentationStyle = UIModalPresentationFormSheet;
    [c release];
    [self presentModalViewController:n animated:YES];
    [n release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

@end
