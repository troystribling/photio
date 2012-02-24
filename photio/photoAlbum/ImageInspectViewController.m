//
//  ImageInspectViewController.m
//  photio
//
//  Created by Troy Stribling on 2/19/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//
#import "ImageInspectViewController.h"
#import "UIImage+Resize.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface ImageInspectViewController (PrivateAPI)

- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo;
- (void)loadFile:(NSString*)_fileName;
- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType;

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation ImageInspectViewController

@synthesize overlayViewController, capture, imageView, toolBar, containerView;

#pragma mark -
#pragma mark ImageInspectViewController

+ (id)inView:(UIView*)_containerView {
    return [[ImageInspectViewController alloc] initWithNibName:@"ImageInspectViewController" bundle:nil inView:_containerView];;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil inView:(UIView*)_containerView {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.containerView = _containerView;
        self.view.frame = self.containerView.frame;
    }
    return self;
}
#pragma mark -
#pragma mark ImageInspectViewController (PrivateAPI)

- (void)image:(UIImage*)image didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo {
    if (error != NULL) {
    }
}

- (void)loadFile:(NSString*)_fileName {
    NSString* pngPath = [NSHomeDirectory() stringByAppendingPathComponent:_fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pngPath]) {
        self.imageView.image = [UIImage imageWithContentsOfFile:pngPath];
    }
}

- (void)showImagePicker:(UIImagePickerControllerSourceType)sourceType {
    if ([UIImagePickerController isSourceTypeAvailable:sourceType]) {
        [self.overlayViewController setupImagePicker:sourceType];
        [self presentModalViewController:self.overlayViewController.imagePickerController animated:YES];
    }
}

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overlayViewController = [[CameraOverlayViewController alloc] initWithNibName:@"CameraOverlayViewController" bundle:nil];
    self.overlayViewController.overlayDelegate = self;    
//    [self loadFile:@"Documents/Test.png"];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark -
#pragma mark Toolbar Actions

- (IBAction)cameraAction:(id)sender { 
    [self showImagePicker:UIImagePickerControllerSourceTypeCamera];
}

#pragma mark -
#pragma mark OverlayViewControllerDelegate

- (void)didTakePicture:(UIImage*)picture { 
    self.capture = picture;
}

- (void)didFinishWithCamera { 
    [self dismissModalViewControllerAnimated:YES];
    UIImageWriteToSavedPhotosAlbum(self.capture, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    UIImage* saveImage = [self.capture scaleBy:SAVED_IMAGE_SCALE andCropToSize:SAVED_IMAGE_CROP];
    NSString* pngPath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Test.png"];
    [UIImagePNGRepresentation(saveImage) writeToFile:pngPath atomically:YES];
    self.imageView.image = saveImage;
    [self.view addSubview:imageView];        
}

@end
