//
//  ImageEntriesView.h
//  photio
//
//  Created by Troy Stribling on 2/19/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransitionGestureRecognizer.h"
#import "DiagonalGestureRecognizer.h"
#import "StreamOfViews.h"
#import "ImageEntryView.h"

@protocol ImageEntriesViewDelegate;

@interface ImageEntriesView : UIView <StreamOfViewsDelegate, DiagonalGestureRecognizerDelegate, ImageEntryViewDelegate> {
}

@property(nonatomic, weak)   UIView*                            containerView;
@property(nonatomic, weak)   id<ImageEntriesViewDelegate>       delegate;
@property(nonatomic, strong) DiagonalGestureRecognizer*         diagonalGestures;
@property(nonatomic, strong) StreamOfViews*                     entriesStreamView;
@property(nonatomic, strong) NSMutableArray*                    entries;
@property(nonatomic, assign) NSInteger                          inViewIndex;
@property(nonatomic, assign) NSInteger                          leftMostIndex;
@property(nonatomic, assign) NSInteger                          rightMostIndex;

+ (id)withFrame:(CGRect)_frame andDelegate:(id<ImageEntriesViewDelegate>)_delegate;
- (id)initWithFrame:(CGRect)frame andDelegate:(id<ImageEntriesViewDelegate>)_delegate;
- (NSInteger)entryCount;
- (void)addCaptureToRight:(Capture*)_capture;
- (void)addCaptureToLeft:(Capture*)_capture;

@end

@protocol ImageEntriesViewDelegate <NSObject>

@optional

- (void)didRemoveAllEntries:(ImageEntriesView*)_entries;
- (NSMutableArray*)loadEntries;

- (void)dragEntries:(CGPoint)_drag;
- (void)releaseEntries;
- (void)transitionUpFromEntries;
- (void)transitionDownFromEntries;

- (void)didSingleTapEntries:(ImageEntriesView*)_entries;

@end