//
//  CameraViewController.m
//  photio
//
//  Created by Troy Stribling on 3/2/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "CameraViewController.h"
#import "Camera.h"
#import "TransitionGestureRecognizer.h"
#import "ViewGeneral.h"
#import <AVFoundation/AVFoundation.h>

static void *AVCamFocusModeObserverContext = &AVCamFocusModeObserverContext;

@interface CameraViewController () <UIGestureRecognizerDelegate>
@end

@interface CameraViewController (PrivateAPI)

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates;
- (void)tapToAutoFocus:(UIGestureRecognizer*)gestureRecognizer;
- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer*)gestureRecognizer;
- (void)toggleCamera:(id)sender;

@end

@interface CameraViewController (CameraDelegate) <CameraDelegate>
@end

@interface CameraViewController (TransitionGestureRecognizerDelegate) <TransitionGestureRecognizerDelegate>
@end

@implementation CameraViewController

@synthesize camera, containerView, transitionGestureRecognizer, cameraDelegate, captureVideoPreviewLayer;

#pragma mark -
#pragma mark UIView

- (void)viewDidLoad {
    
	if (self.camera == nil) {
		self.camera = [[Camera alloc] init];		
		self.camera.delegate = self;
		[self.camera setupSession];

        AVCaptureVideoPreviewLayer* newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[self.camera session]];
        CALayer *viewLayer = [self.view layer];
        [viewLayer setMasksToBounds:YES];
        
        CGRect bounds = [self.view bounds];
        [newCaptureVideoPreviewLayer setFrame:bounds];
        if ([newCaptureVideoPreviewLayer isOrientationSupported]) {
            [newCaptureVideoPreviewLayer setOrientation:AVCaptureVideoOrientationPortrait];
        }
        [newCaptureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [viewLayer insertSublayer:newCaptureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
        [self setCaptureVideoPreviewLayer:newCaptureVideoPreviewLayer];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[self.camera session] startRunning];
        });
                    
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToAutoFocus:)];
        [singleTap setDelegate:self];
        [singleTap setNumberOfTapsRequired:1];
        [self.view addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToContinouslyAutoFocus:)];
        [doubleTap setDelegate:self];
        [doubleTap setNumberOfTapsRequired:2];
        [singleTap requireGestureRecognizerToFail:doubleTap];
        [self.view addGestureRecognizer:doubleTap];
	}
    [super viewDidLoad];
}

#pragma mark -
#pragma mark CameraViewController

+ (id)inView:(UIView*)_containerView {
    return [[CameraViewController alloc] initWithNibName:@"CameraViewController" bundle:nil inView:_containerView];;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inView:(UIView*)_containerView {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {        
        self.containerView = _containerView;
        self.view.frame = self.containerView.frame;
        self.transitionGestureRecognizer = [TransitionGestureRecognizer initWithDelegate:self inView:self.view relativeToView:self.containerView];
    }
    return self;
}

- (IBAction)captureStillImage:(id)sender {
    [self.camera captureStillImage];
}

- (void)setFlashImage {
}

- (IBAction)changeFlashMode:(id)sender {
}

@end

#pragma mark -
#pragma mark CameraViewController PrivateAPI
@implementation CameraViewController (PrivateAPI)

- (CGPoint)convertToPointOfInterestFromViewCoordinates:(CGPoint)viewCoordinates  {
    CGPoint pointOfInterest = CGPointMake(.5f, .5f);
    CGSize frameSize = self.view.frame.size;
    if ([captureVideoPreviewLayer isMirrored]) {
        viewCoordinates.x = frameSize.width - viewCoordinates.x;
    }    
    if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResize] ) {
        pointOfInterest = CGPointMake(viewCoordinates.y / frameSize.height, 1.f - (viewCoordinates.x / frameSize.width));
    } else {
        CGRect cleanAperture;
        for (AVCaptureInputPort *port in [self.camera.videoInput ports]) {
            if ([port mediaType] == AVMediaTypeVideo) {
                cleanAperture = CMVideoFormatDescriptionGetCleanAperture([port formatDescription], YES);
                CGSize apertureSize = cleanAperture.size;
                CGPoint point = viewCoordinates;
                CGFloat apertureRatio = apertureSize.height / apertureSize.width;
                CGFloat viewRatio = frameSize.width / frameSize.height;
                CGFloat xc = .5f;
                CGFloat yc = .5f;
                if ( [[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspect] ) {
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = frameSize.height;
                        CGFloat x2 = frameSize.height * apertureRatio;
                        CGFloat x1 = frameSize.width;
                        CGFloat blackBar = (x1 - x2) / 2;
						// If point is inside letterboxed area, do coordinate conversion; otherwise, don't change the default value returned (.5,.5)
                        if (point.x >= blackBar && point.x <= blackBar + x2) {
							// Scale (accounting for the letterboxing on the left and right of the video preview), switch x and y, and reverse x
                            xc = point.y / y2;
                            yc = 1.f - ((point.x - blackBar) / x2);
                        }
                    } else {
                        CGFloat y2 = frameSize.width / apertureRatio;
                        CGFloat y1 = frameSize.height;
                        CGFloat x2 = frameSize.width;
                        CGFloat blackBar = (y1 - y2) / 2;
						// If point is inside letterboxed area, do coordinate conversion. Otherwise, don't change the default value returned (.5,.5)
                        if (point.y >= blackBar && point.y <= blackBar + y2) {
							// Scale (accounting for the letterboxing on the top and bottom of the video preview), switch x and y, and reverse x
                            xc = ((point.y - blackBar) / y2);
                            yc = 1.f - (point.x / x2);
                        }
                    }
                } else if ([[captureVideoPreviewLayer videoGravity] isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
					// Scale, switch x and y, and reverse x
                    if (viewRatio > apertureRatio) {
                        CGFloat y2 = apertureSize.width * (frameSize.width / apertureSize.height);
                        xc = (point.y + ((y2 - frameSize.height) / 2.f)) / y2; // Account for cropped height
                        yc = (frameSize.width - point.x) / frameSize.width;
                    } else {
                        CGFloat x2 = apertureSize.height * (frameSize.height / apertureSize.width);
                        yc = 1.f - ((point.x + ((x2 - frameSize.width) / 2)) / x2); // Account for cropped width
                        xc = point.y / frameSize.height;
                    }
                }                
                pointOfInterest = CGPointMake(xc, yc);
                break;
            }
        }
    }
    return pointOfInterest;
}

- (void)tapToAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.camera.videoInput.device isFocusPointOfInterestSupported]) {
        CGPoint tapPoint = [gestureRecognizer locationInView:self.view];
        CGPoint convertedFocusPoint = [self convertToPointOfInterestFromViewCoordinates:tapPoint];
        [self.camera autoFocusAtPoint:convertedFocusPoint];
    }
}

- (void)tapToContinouslyAutoFocus:(UIGestureRecognizer *)gestureRecognizer {
    if ([self.camera.videoInput.device isFocusPointOfInterestSupported])
        [self.camera continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

- (void)toggleCamera:(id)sender {
    [self.camera toggleCamera];
    [self.camera continuousFocusAtPoint:CGPointMake(.5f, .5f)];
}

@end

#pragma mark -
#pragma mark CameraViewController CameraDelegate
@implementation CameraViewController (CameraDelegate)

- (void)camera:(Camera*)_camera didFailWithError:(NSError *)error {
    CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^(void) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:[error localizedFailureReason]
                                                delegate:nil
                                                cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title")
                                                otherButtonTitles:nil];
        [alertView show];
    });
}

@end

#pragma mark -
#pragma mark TransitionGestureRecognizerDelegate
@implementation CameraViewController (TransitionGestureRecognizerDelegatez)

- (void)didDragRight:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] dragCamera:_drag];
}

- (void)didDragLeft:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {    
    [[ViewGeneral instance] dragCamera:_drag];
}

- (void)didDragUp:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {
}

- (void)didDragDown:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] dragCameraToInspectImage:_drag];
}

- (void)didReleaseRight:(CGPoint)_location {    
    [[ViewGeneral instance] releaseCamera];
}

- (void)didReleaseLeft:(CGPoint)_location {
    [[ViewGeneral instance] releaseCamera];
}

- (void)didReleaseUp:(CGPoint)_location {
}

- (void)didReleaseDown:(CGPoint)_location {
    [[ViewGeneral instance] releaseCamera];
}

- (void)didSwipeRight:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] transitionCameraToLocales];    
}

- (void)didSwipeLeft:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] transitionCameraToCalendar];    
}

- (void)didSwipeUp:(CGPoint)_location withVelocity:(CGPoint)_velocity {
}

- (void)didSwipeDown:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] transitionCameraToInspectImage];
}

- (void)didReachMaxDragRight:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {
    [[ViewGeneral instance] transitionCameraToLocales];    
}

- (void)didReachMaxDragLeft:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {    
    [[ViewGeneral instance] transitionCameraToCalendar];    
}

- (void)didReachMaxDragUp:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {    
}

- (void)didReachMaxDragDown:(CGPoint)_drag from:(CGPoint)_location withVelocity:(CGPoint)_velocity {    
    [[ViewGeneral instance] transitionCameraToInspectImage];
}

@end

