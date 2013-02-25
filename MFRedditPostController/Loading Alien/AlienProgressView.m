//
//  AlienProgressView.m
//  Reddit
//
//  Created by Ross Boucher on 12/26/08.
//  Copyright 2008 280 North. All rights reserved.
//

#import "AlienProgressView.h"

@implementation AlienProgressView

- (void)awakeFromNib
{
	[self doInit];
}

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) 
	{
		[self doInit];
    }
	
    return self;
}

- (void)doInit
{
	imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
	
	[imageView setImage:[UIImage imageNamed:@"Loading0.png"]];
	
	images = @[[UIImage imageNamed:@"Loading4.png"],
			  [UIImage imageNamed:@"Loading3.png"]];
	
	[self addSubview:imageView];
	
	isAnimating = NO;
}

- (void)startAnimating
{
	if (isAnimating)
		return;
	
	isAnimating = YES;
	status = 0;
	
	[self setHidden:NO];
	[imageView setImage:[UIImage imageNamed:@"Loading0.png"]];
	
    [self updateAnimation];
}

- (void)updateAnimation
{
	switch (status)
	{
		case 0:
        {
			status = 1;
			[imageView setImage:[UIImage imageNamed:@"Loading1.png"]];
			[NSTimer scheduledTimerWithTimeInterval:.15 target:self selector:@selector(updateAnimation) userInfo:nil repeats:NO];
			break;
        }
		case 1:
        {
			status = 2;
            dispatch_async(dispatch_get_main_queue(), ^{
                    [imageView setImage:[UIImage imageNamed:@"Loading2.png"]];
            });
			
			[NSTimer scheduledTimerWithTimeInterval:.15 target:self selector:@selector(updateAnimation) userInfo:nil repeats:NO];
			break;
        }
		case 2:
        {
            status = 3;
            [imageView setImage:[UIImage imageNamed:@"Loading3.png"]];
			[imageView setAnimationImages:images];
			[imageView setAnimationDuration:.6];
            [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(updateAnimation) userInfo:nil repeats:NO];
			break;
        }
        case 3:
        {
            [imageView startAnimating];
            break;
        }
		default:
			break;
	}
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
	//[self setHidden:YES];
	return NO;
}

- (void)stopAnimating
{
	isAnimating = NO;
	
	[imageView stopAnimating];
	[imageView setAnimationImages:nil];
    
    [imageView setImage:[UIImage imageNamed:@"Loading0.png"]];
}

- (BOOL)isAnimating
{
	return isAnimating;
}



@end
