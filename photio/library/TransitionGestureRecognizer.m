//
//  TransitionGestureRecognizer.m
//  photio
//
//  Created by Troy Stribling on 3/2/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "TransitionGestureRecognizer.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TransitionGestureRecognizer (PrivateAPI)

- (void)delegateDrag:(CGPoint)_delta;
- (void)delegateRelease;
- (void)delegateSwipe;
- (CGPoint)dragDelta:(CGPoint)_touchPoint;
- (void)determineDragDirection:(CGPoint)_velocity;
- (BOOL)detectedSwipe:(CGPoint)_velocity;
- (BOOL)detectedMaximumDrag;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TransitionGestureRecognizer 

@synthesize lastTouch, delegate, gestureRecognizer, view, relativeView, totalDragDistance, dragDirection, acceptTouches;

#pragma mark -
#pragma mark TransitionGestureRecognizer PrivateAPI

- (void)delegateDrag:(CGPoint)_delta {
    switch (self.dragDirection) {
        case DragDirectionRight:
            if ([self.delegate respondsToSelector:@selector(didDragRight:)]) {
                [self.delegate didDragRight:CGPointMake(_delta.x, 0.0)];
            }
            break;
        case DragDirectionLeft:
            if ([self.delegate respondsToSelector:@selector(didDragLeft:)]) {
                [self.delegate didDragLeft:CGPointMake(_delta.x, 0.0)];
            }
            break;
        case DragDirectionUp:
            if ([self.delegate respondsToSelector:@selector(didDragUp:)]) {
                [self.delegate didDragUp:CGPointMake(0.0, _delta.y)];
            }
            break;
        case DragDirectionDown:
            if ([self.delegate respondsToSelector:@selector(didDragDown:)]) {
                [self.delegate didDragDown:CGPointMake(0.0, _delta.y)];
            }
            break;
    }
}

- (void)delegateRelease {
    switch (self.dragDirection) {
        case DragDirectionRight:
            if ([self.delegate respondsToSelector:@selector(didReleaseRight)]) {
                [self.delegate didReleaseLeft];
            }
            break;
        case DragDirectionLeft:
            if ([self.delegate respondsToSelector:@selector(didReleaseLeft)]) {
                [self.delegate didReleaseLeft];
            }
            break;
        case DragDirectionUp:
            if ([self.delegate respondsToSelector:@selector(didReleaseUp)]) {
                [self.delegate didReleaseUp];
            }
            break;
        case DragDirectionDown:
            if ([self.delegate respondsToSelector:@selector(didReleaseDown)]) {
                [self.delegate didReleaseDown];
            }
            break;
    }    
}

- (void)delegateSwipe {
    switch (self.dragDirection) {
        case DragDirectionRight:
            if ([self.delegate respondsToSelector:@selector(didSwipeRight)]) {
                [self.delegate didSwipeRight];
            }
            break;
        case DragDirectionLeft:
            if ([self.delegate respondsToSelector:@selector(didSwipeLeft)]) {
                [self.delegate didSwipeLeft];
            }
            break;
        case DragDirectionUp:
            if ([self.delegate respondsToSelector:@selector(didSwipeUp)]) {
                [self.delegate didSwipeUp];
            }
            break;
        case DragDirectionDown:
            if ([self.delegate respondsToSelector:@selector(didSwipeDown)]) {
                [self.delegate didSwipeDown];
            }
            break;
    }    
}

- (CGPoint)dragDelta:(CGPoint)_touchPoint {
    CGFloat deltaX = _touchPoint.x - self.lastTouch.x;
    CGFloat deltaY = _touchPoint.y - self.lastTouch.y;
    return CGPointMake(deltaX > MAX_TOUCH_DELTA ? MAX_TOUCH_DELTA : deltaX, deltaY > MAX_TOUCH_DELTA ? MAX_TOUCH_DELTA : deltaY);
}

- (void)determineDragDirection:(CGPoint)_velocity {
    if (abs(_velocity.x) > abs(_velocity.y) && _velocity.x < 0) {
        self.dragDirection = DragDirectionLeft;        
    } else if (abs(_velocity.x) > abs(_velocity.y) && _velocity.x >= 0) {
        self.dragDirection = DragDirectionRight;        
    } else if (abs(_velocity.x) < abs(_velocity.y) && _velocity.y < 0) {
        self.dragDirection = DragDirectionUp;        
    } else {
        self.dragDirection = DragDirectionDown;                
    }
}

- (BOOL)detectedSwipe:(CGPoint)_velocity {
    BOOL swipeDetected = NO;
    switch (self.dragDirection) {
        case DragDirectionRight:
            if (_velocity.x > DETECT_SWIPE_SPEED) {
                swipeDetected = YES;
            }
            break;
        case DragDirectionLeft:
            if (-_velocity.x > DETECT_SWIPE_SPEED) {
                swipeDetected = YES;
            }
            break;
        case DragDirectionUp:
            if (-_velocity.y > DETECT_SWIPE_SPEED) {
                swipeDetected = YES;
            }
            break;
        case DragDirectionDown:
            if (_velocity.y > DETECT_SWIPE_SPEED) {
                swipeDetected = YES;
            }
            break;
    }
    return swipeDetected;
}

- (BOOL)detectedMaximumDrag {
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    BOOL atMaximumDrag = YES;
    switch (self.dragDirection) {
        case DragDirectionRight:
        case DragDirectionLeft:
            if (abs(self.totalDragDistance.x) < screenBounds.size.width/2.0) {
                atMaximumDrag = NO;
            }
            break;
        case DragDirectionUp:
        case DragDirectionDown:
            if (abs(self.totalDragDistance.y) < screenBounds.size.height/2.0) {
                atMaximumDrag = NO;
            }
            break;
    }
    self.acceptTouches = atMaximumDrag ? NO : YES;
    return atMaximumDrag;
}

#pragma mark -
#pragma mark TransitionGestureRecognizer

+ (id)initWithDelegate:(id<TransitionGestureRecognizerDelegate>)_delegate inView:(UIView*)_view relativeToView:(UIView*)_relativeView {
    return [[self alloc] initWithDelegate:_delegate inView:_view relativeToView:(UIView*)_relativeView];
}

- (id)initWithDelegate:(id<TransitionGestureRecognizerDelegate>)_delegate inView:(UIView*)_view relativeToView:(UIView*)_relativeView {
    if (self = [super init]) {
        self.delegate = _delegate;
        self.view = _view;
        self.relativeView = _relativeView;
        self.gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(touched:)];
        [self.view addGestureRecognizer:self.gestureRecognizer];
        self.totalDragDistance = CGPointMake(0.0, 0.0);
    }
    return self;
}

- (void)touched:(UIPanGestureRecognizer*)_recognizer {
    CGPoint velocity = [_recognizer velocityInView:self.relativeView];
    CGPoint touchPoint = [_recognizer locationInView:self.relativeView];
    CGPoint delta = [self dragDelta:touchPoint];
    switch (_recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self determineDragDirection:velocity];
            self.totalDragDistance = CGPointMake(0.0, 0.0);
            self.lastTouch = touchPoint;
            self.acceptTouches = YES;
            break;
        case UIGestureRecognizerStateChanged:
            self.totalDragDistance = CGPointMake(self.totalDragDistance.x + delta.x, self.totalDragDistance.y + delta.y);
            [self detectedMaximumDrag] ? [self delegateSwipe] : [self delegateDrag:delta];
            self.lastTouch = CGPointMake(touchPoint.x, touchPoint.y);
            break;
        case UIGestureRecognizerStateEnded:
            if (self.acceptTouches) {
                [self detectedSwipe:velocity] ?  [self delegateSwipe] : [self delegateRelease];
            }
            break;
        default:
            break;
    }
}

@end
