//
//  ImageInspectView.m
//  photio
//
//  Created by Troy Stribling on 4/5/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "ImageInspectView.h"
#import "UIImage+Resize.h"
#import "Capture.h"
#import "Image.h"
#import "ViewGeneral.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ImageInspectView (PrivateAPI)

- (void)editImage;
- (void)finishedSavingToCameraRoll:image:(UIImage*)_image didFinishSavingWithError:(NSError*)_error contextInfo:(void*)_context;
- (void)singleTapGesture;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ImageInspectView

@synthesize delegate, capture, latitude, longitude, createdAt, comment, rating;

#pragma mark -
#pragma mark ImageInspectView PrivateAPI

- (void)editImage {
    ViewGeneral* viewGeneral = [ViewGeneral instance];
    [viewGeneral initImageEditView:self];
    viewGeneral.imageEditViewController.delegate = self;
    [viewGeneral.imageEditViewController updateRating:self.rating];
    [viewGeneral.imageEditViewController updateComment:self.comment];    
}

- (void)finishedSavingToCameraRoll:image:(UIImage*)_image didFinishSavingWithError:(NSError*)_error contextInfo:(void*)_context {
    if (_error) {
        [[[UIAlertView alloc] initWithTitle:[_error localizedDescription] message:[_error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil] show];
    }
}

- (void)singleTapImageGesture {
    if ([self.delegate respondsToSelector:@selector(didSingleTapImage)]) {
        [self.delegate didSingleTapImage];
    }
}

#pragma mark -
#pragma mark ImageInspectView

+ (id)withFrame:(CGRect)_frame andCapture:(Capture*)_capture {
    return [[ImageInspectView alloc] initWithFrame:_frame capture:_capture.image.image date:_capture.createdAt comment:_capture.comment rating:_capture.rating
               andLocation:CLLocationCoordinate2DMake([_capture.latitude doubleValue], [_capture.longitude doubleValue])];
}

+ (id)cachedWithFrame:(CGRect)_frame capture:(UIImage*)_capture andLocation:(CLLocationCoordinate2D)_location {
    ImageInspectView* view = [[ImageInspectView alloc] initWithFrame:_frame capture:_capture date:[NSDate date] comment:nil rating:nil andLocation:_location];
    view.capture = _capture;
    return view;
}

- (id)initWithFrame:(CGRect)_frame capture:(UIImage*)_capture date:(NSDate*)_date comment:(NSString*)_comment rating:(NSString*)_rating andLocation:(CLLocationCoordinate2D)_location {
    if ((self = [super initWithFrame:(CGRect)_frame])) {
        self.latitude = [NSNumber numberWithDouble:_location.latitude];
        self.longitude = [NSNumber numberWithDouble:_location.longitude];
        self.createdAt = _date;
        self.image = [_capture scaleToSize:_frame.size];
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        UITapGestureRecognizer* editImageGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editImage)];
        editImageGesture.numberOfTapsRequired = 2;
        editImageGesture.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:editImageGesture];
        UITapGestureRecognizer* sigleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapImageGesture)];
        sigleTapGesture.numberOfTapsRequired = 1;
        sigleTapGesture.numberOfTouchesRequired = 1;
        [self addGestureRecognizer:sigleTapGesture];
        [sigleTapGesture requireGestureRecognizerToFail:editImageGesture];
    }
    return self;
}

#pragma mark -
#pragma mark ImageEditViewController

- (void)exportToCameraRoll {
    UIImageWriteToSavedPhotosAlbum(self.capture, self, @selector(finishedSavingToCameraRoll::didFinishSavingWithError:contextInfo:), nil);
}

- (void)saveComment:(NSString*)_comment {
    
}

- (void)saveRating:(NSString*)_rating {
    
}

@end
