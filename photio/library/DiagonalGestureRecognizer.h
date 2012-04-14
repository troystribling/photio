//
//  DiagonalGestureRecognizer.h
//  photio
//
//  Created by Troy Stribling on 4/11/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@protocol DiagonalGestureRecognizerDelegate;

@interface DiagonalGestureRecognizer : UIGestureRecognizer {
}

@property(nonatomic, weak)   id<DiagonalGestureRecognizerDelegate>      gestureDelegate;
@property(nonatomic, assign) BOOL                                       strokeUp;
@property(nonatomic, assign) CGPoint                                    midPoint;

+ (id)initWithDelegate:(id<DiagonalGestureRecognizerDelegate>)_gestureDelegate;
- (id)initWithDelegate:(id<DiagonalGestureRecognizerDelegate>)_gestureDelegate;
- (void)reset;
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event;
- (void)touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event;

@end

@protocol DiagonalGestureRecognizerDelegate <NSObject>

@optional

-(void)didCheck;
-(void)didDiagonalSwipe;

@end
