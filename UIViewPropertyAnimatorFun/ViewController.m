//
//  ViewController.m
//  UIViewPropertyAnimatorFun
//
//  Created by Daniel Larsson on 30/03/2017.
//  Copyright © 2017 larssondaniel. All rights reserved.
//

#import "ViewController.h"

typedef NS_ENUM(NSInteger, PlayerState) {
    PlayerStateThumbnail,
    PlayerStateFullscreen,
};

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIView *playerView;
@property (nonatomic) UIViewPropertyAnimator *playerViewAnimator;
@property (nonatomic) CGRect originalPlayerViewFrame;
@property (nonatomic) PlayerState playerState;
@property (nonatomic) UIPanGestureRecognizer *panGestureRecognizer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.view addGestureRecognizer:self.panGestureRecognizer];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint translation = [recognizer translationInView:self.view.superview];

    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self panningBegan];
    }
    if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint velocity = [recognizer velocityInView:self.view];
        [self panningEndedWithTranslation:translation velocity:velocity];
    }
    else
    {
        CGPoint translation = [recognizer translationInView:self.view.superview];
        [self panningChangedWithTranslation:translation];
    }
}

- (void)panningBegan
{
    if (self.playerViewAnimator.isRunning)
    {
        return;
    }

    CGRect targetFrame;

    switch (self.playerState) {
        case PlayerStateThumbnail:
            self.originalPlayerViewFrame = self.playerView.frame;
            targetFrame = self.view.frame;
            break;
        case PlayerStateFullscreen:
            targetFrame = self.originalPlayerViewFrame;
    }

    self.playerViewAnimator = [[UIViewPropertyAnimator alloc] initWithDuration:0.5 dampingRatio:0.8 animations:^{
        self.playerView.frame = targetFrame;
    }];
}

- (void)panningChangedWithTranslation:(CGPoint)translation
{
    if (self.playerViewAnimator.isRunning)
    {
        return;
    }

    CGFloat translatedY = self.view.center.y + translation.y;

    CGFloat progress;
    switch (self.playerState) {
        case PlayerStateThumbnail:
            progress = 1 - (translatedY / self.view.center.y);
            break;
        case PlayerStateFullscreen:
            progress = (translatedY / self.view.center.y) - 1;
    }

    progress = MAX(0.001, MIN(0.999, progress));

    self.playerViewAnimator.fractionComplete = progress;
}

- (void)panningEndedWithTranslation:(CGPoint)translation velocity:(CGPoint)velocity
{
    self.panGestureRecognizer.enabled = NO;

    CGFloat screenHeight = [[UIScreen mainScreen] bounds].size.height;
    __weak ViewController *weakSelf = self;

    switch (self.playerState) {
        case PlayerStateThumbnail:
            if (translation.y <= -screenHeight / 3 || velocity.y <= -100)
            {
                self.playerViewAnimator.reversed = NO;
                [self.playerViewAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
                    weakSelf.playerState = PlayerStateFullscreen;
                    weakSelf.panGestureRecognizer.enabled = YES;
                }];
            }
            else
            {
                self.playerViewAnimator.reversed = YES;
                [self.playerViewAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
                    weakSelf.playerState = PlayerStateThumbnail;
                    weakSelf.panGestureRecognizer.enabled = YES;
                }];
            }
            break;
        case PlayerStateFullscreen:
            if (translation.y >= screenHeight / 3 || velocity.y >= 100)
            {
                self.playerViewAnimator.reversed = NO;
                [self.playerViewAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
                    weakSelf.playerState = PlayerStateThumbnail;
                    weakSelf.panGestureRecognizer.enabled = YES;
                }];
            }
            else
            {
                self.playerViewAnimator.reversed = YES;
                [self.playerViewAnimator addCompletion:^(UIViewAnimatingPosition finalPosition) {
                    weakSelf.playerState = PlayerStateFullscreen;
                    weakSelf.panGestureRecognizer.enabled = YES;
                }];
            }
        default:
            break;
    }

    CGVector velocityVector = CGVectorMake(velocity.x / 100, velocity.y / 100);
    UISpringTimingParameters *springParameters = [[UISpringTimingParameters alloc] initWithDampingRatio:0.8 initialVelocity:velocityVector];

    [self.playerViewAnimator continueAnimationWithTimingParameters:springParameters durationFactor:1.0];
}

@end
