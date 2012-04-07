//
//  ImageInspectViewController.h
//  photio
//
//  Created by Troy Stribling on 2/19/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransitionGestureRecognizer.h"
#import "StreamOfViews.h"

@protocol ImageInspectViewControllerDelegate;
 
@interface ImageInspectViewController : UIViewController <UIImagePickerControllerDelegate, StreamOfViewsDelegate> {
}

@property(nonatomic, weak)     UIView*                                  containerView;
@property(nonatomic, weak)     id<ImageInspectViewControllerDelegate>   delegate;
@property(nonatomic, retain)   StreamOfViews*                           imageView;

+ (id)inView:(UIView*)_containerView withDelegate:(id<ImageInspectViewControllerDelegate>)_delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inView:(UIView*)_containerView withDelegate:(id<ImageInspectViewControllerDelegate>)_delegate;
- (void)addImage:(UIImage*)_picture;
- (BOOL)hasCaptures;

@end

@protocol ImageInspectViewControllerDelegate <NSObject>

@optional

- (void)dragInspectImage:(CGPoint)_drag;
- (void)releaseInspectImage;
- (void)transitionFromInspectImage;

@end
