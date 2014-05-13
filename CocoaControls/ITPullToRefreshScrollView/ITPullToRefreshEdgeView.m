//
//  ITPullToRefreshEdgeView.m
//  ITPullToRefreshScrollView
//
//  Created by Ilija Tovilo on 9/25/13.
//  Copyright (c) 2013 Ilija Tovilo. All rights reserved.
//

#import "ITPullToRefreshEdgeView.h"
#import <QuartzCore/QuartzCore.h>
#import "ITProgressIndicator.h"
#import "NSBKeyframeAnimation.h"

#define kDefaultEdgeViewHeight 30
#define kSpinnerSize 30

#define kMinSpinAnimationDuration 2.0
#define kMaxSpinAnimationDuration 8.0
#define kSpringRange 0.4

@interface ITPullToRefreshEdgeView () {
    CGFloat _cachedProgress;
}
@property (strong) ITProgressIndicator *progressIndicator;
@end

@implementation ITPullToRefreshEdgeView


#pragma mark - Init

- (instancetype)initWithEdge:(ITPullToRefreshEdge)edge {
    if (self = [super init]) {
        _edgeViewEdge = edge;
        [self installComponents];
    }
    
    return self;
}

- (void)installComponents {
    self.progressIndicator = [[ITProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, kSpinnerSize, kSpinnerSize)];
    
    [self.progressIndicator setWantsLayer:YES];
    self.progressIndicator.animates = NO;
    self.progressIndicator.hideWhenStopped = NO;
    self.progressIndicator.isIndeterminate = NO;
    self.progressIndicator.progress = 0.0;
    self.progressIndicator.numberOfLines = 12;
    self.progressIndicator.widthOfLine = 2.0;
    self.progressIndicator.innerMargin = 5;
    self.progressIndicator.color = [NSColor colorWithDeviceWhite:0.4 alpha:1.0];
    self.progressIndicator.layer.contentsGravity = kCAGravityCenter;
    [self.progressIndicator.layer setAnchorPoint:CGPointMake(0.5, 0.5)];
    
    [self addSubview:self.progressIndicator];
    
    
    // Install Layout Constraints
    {
        [self.progressIndicator setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.progressIndicator addConstraint:[NSLayoutConstraint constraintWithItem:self.progressIndicator
                                                                           attribute:NSLayoutAttributeWidth
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1
                                                                            constant:kSpinnerSize]];
        [self.progressIndicator addConstraint:[NSLayoutConstraint constraintWithItem:self.progressIndicator
                                                                           attribute:NSLayoutAttributeHeight
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:nil
                                                                           attribute:NSLayoutAttributeNotAnAttribute
                                                                          multiplier:1
                                                                            constant:kSpinnerSize]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressIndicator
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:0
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1
                                                          constant:0]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressIndicator
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:0
                                                            toItem:self
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1
                                                          constant:0]];
    }
}


#pragma mark - Constraints

- (void)viewDidMoveToSuperview {
    [self setUpConstraints];
}

- (void)setUpConstraints {
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:nil
                                                     attribute:NSLayoutAttributeNotAnAttribute
                                                    multiplier:1
                                                      constant:[self edgeViewHeight]]];
    
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeLeft
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeLeft
                                                              multiplier:1.0
                                                                constant:0.0]];
    [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                               attribute:NSLayoutAttributeRight
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self.superview
                                                               attribute:NSLayoutAttributeRight
                                                              multiplier:1.0
                                                                constant:0.0]];
    
    if (self.edgeViewEdge & ITPullToRefreshEdgeTop)
    {
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:[(NSClipView *)self.superview documentView]
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:0.0]];
    }
    else if (self.edgeViewEdge & ITPullToRefreshEdgeBottom)
    {
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:[(NSClipView *)self.superview documentView]
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:0.0]];
    }
}


#pragma mark - Customisation Methods

- (CGFloat)edgeViewHeight {
    return kDefaultEdgeViewHeight;
}

- (void)pullToRefreshScrollView:(ITPullToRefreshScrollView *)scrollView didScrollWithProgress:(CGFloat)progress {
    _cachedProgress = progress;
    
    if (progress < 1.0) {
        self.progressIndicator.isIndeterminate = NO;
        self.progressIndicator.progress = progress;
    }
}

- (void)pullToRefreshScrollViewDidTriggerRefresh:(ITPullToRefreshScrollView *)scrollView {
    self.progressIndicator.isIndeterminate = NO;
    self.progressIndicator.progress = 1.0;
}

- (void)pullToRefreshScrollViewDidUntriggerRefresh:(ITPullToRefreshScrollView *)scrollView {
    
}

- (void)pullToRefreshScrollViewDidStartRefreshing:(ITPullToRefreshScrollView *)scrollView {
    CGFloat tension = (_cachedProgress - 1.0 <= kSpringRange)?_cachedProgress - 1:kSpringRange;
    CGFloat duration = kMaxSpinAnimationDuration - ((kMaxSpinAnimationDuration - kMinSpinAnimationDuration) * (1.0 / kSpringRange * tension));
    
    [self.progressIndicator.layer addAnimation:[self rotationAnimationWithDuration:duration] forKey:@"rotation"];
    self.progressIndicator.isIndeterminate = YES;
    self.progressIndicator.animates = YES;
}

- (void)pullToRefreshScrollViewDidStopRefreshing:(ITPullToRefreshScrollView *)scrollView {
    self.progressIndicator.animates = NO;
    self.progressIndicator.isIndeterminate = NO;

    [self.progressIndicator.layer addAnimation:[self shrinkAnimation] forKey:@"shrink"];
}

- (void)pullToRefreshScrollViewDidStopAnimating:(ITPullToRefreshScrollView *)scrollView {
    [self.progressIndicator.layer removeAnimationForKey:@"rotation"];
}

- (CAAnimation *)shrinkAnimation {
    NSBKeyframeAnimation *animation = [NSBKeyframeAnimation animationWithKeyPath:@"transform.scale"
                                                                        duration:0.3
                                                                      startValue:1
                                                                        endValue:0.0
                                                                        function:NSBKeyframeAnimationFunctionEaseOutCubic];
    
    return animation;
}

- (CAAnimation *)rotationAnimationWithDuration:(CGFloat)duration {
    NSBKeyframeAnimation *animation = [NSBKeyframeAnimation animationWithKeyPath:@"transform"
                                                                        duration:duration
                                                                      startValue:0
                                                                        endValue:-2 * M_PI
                                                                        function:NSBKeyframeAnimationFunctionEaseOutCubic];
    
    [animation setValueFunction:[CAValueFunction functionWithName: kCAValueFunctionRotateZ]];
    
    return animation;
}

@end
