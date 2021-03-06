//
//  CaptureManager.m
//  photio
//
//  Created by Troy Stribling on 6/21/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "CaptureManager.h"
#import "PhotioAppDelegate.h"
#import "FilterFactory.h"
#import "ViewGeneral.h"
#import "DataContextManager.h"
#import "Capture.h"
#import "UIImage+Resize.h"
#import "LocationManager.h"
#import "Location.h"
#import "ImageThumbnail.h"
#import "ImageDisplay.h"
#import "NSArray+Extensions.h"

/////////////////////////////////////////////////////////////////////////////////////////
static CaptureManager* thisCaptureManager;

/////////////////////////////////////////////////////////////////////////////////////////
@interface CaptureManager (PrivateAPI)

NSInteger descendingSort(id num1, id num2, void *context);
- (Capture*)createCaptureWithImage:(UIImage*)_capturedImage inContext:(NSManagedObjectContext*)_context;
+ (void)showDocuments;
+ (NSString*)fullSizeImagePathForCapture:(Capture*)_captue;

@end

/////////////////////////////////////////////////////////////////////////////////////////
@implementation CaptureManager

@synthesize captureImageQueue, fullSizeImageQueue;

#pragma mark - 
#pragma mark CaptureManager PrivateAPI

NSInteger descendingSort(id num1, id num2, void* context) {
    int v1 = [num1 intValue];
    int v2 = [num2 intValue];
    if (v1 > v2) {
        return NSOrderedAscending;
    } else if (v1 < v2) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}

- (Capture*)createCaptureWithImage:(UIImage*)_capturedImage inContext:(NSManagedObjectContext*)_context {
    NSDate* createdAt = [NSDate date];
    CLLocationCoordinate2D currentLocation = [[[LocationManager instance] location] coordinate];
    DataContextManager* contextManager = [DataContextManager instance];
    Capture* capture = (Capture*)[NSEntityDescription insertNewObjectForEntityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext];
    
    capture.createdAt = createdAt;
    capture.captureId = [NSNumber numberWithLongLong:(long long)(100.0f * [NSDate timeIntervalSinceReferenceDate])];

    capture.dayIdentifier = [self.class dayIdentifier:capture.createdAt];
    capture.cached = [NSNumber numberWithBool:YES];

    ImageThumbnail* thumbnail = [NSEntityDescription insertNewObjectForEntityForName:@"ImageThumbnail" inManagedObjectContext:contextManager.mainObjectContext];
    thumbnail.image = [_capturedImage thumbnailImage:[ViewGeneral imageThumbnailRect].size.width];
    capture.thumbnail = thumbnail;

    ImageDisplay* displayImage = [NSEntityDescription insertNewObjectForEntityForName:@"ImageDisplay" inManagedObjectContext:contextManager.mainObjectContext];
    displayImage.image = [self.class scaleImage:_capturedImage toFrame:[ViewGeneral instance].containerView.frame];
    capture.displayImage = displayImage;

    Location* location = [NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:contextManager.mainObjectContext];
    location.latitude  = [NSNumber numberWithDouble:currentLocation.latitude];
    location.longitude = [NSNumber numberWithDouble:currentLocation.longitude];
    capture.location = location;

    [contextManager save];
    return capture;
}

+ (void)showDocuments {
    NSError* error;
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSString* documentsDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
    NSLog(@"Documents directory: %@", [fileMgr contentsOfDirectoryAtPath:documentsDirectory error:&error]);
}

+ (NSString*)fullSizeImagePathForCapture:(Capture*)_captue {
    NSString* imageFilename = [NSString stringWithFormat:@"Documents/%@.jpg", _captue.captureId];
    return [NSHomeDirectory() stringByAppendingPathComponent:imageFilename]; 
}

#pragma mark - 
#pragma mark CaptureManager

+ (CaptureManager*)instance {
    @synchronized(self) {
        if (thisCaptureManager == nil) {
            thisCaptureManager = [[self alloc] init];
        }
    }
    return thisCaptureManager;
}

- (id)init {
    self = [super init];
    if (self) {
        self.captureImageQueue = dispatch_queue_create("com.photio.captureImage", NULL);
        self.fullSizeImageQueue = dispatch_queue_create("com.photio.fullSizeImage", NULL);
    }
    return self;
}

+ (UIImage*)scaleImage:(UIImage*)_image toFrame:(CGRect)_frame {
    CGFloat imageAspectRatio = _image.size.height / _image.size.width;
    CGFloat scaledImageWidth = _frame.size.width;
    CGFloat scaledImageHeight = MAX(scaledImageWidth * imageAspectRatio, _frame.size.height);
    if (imageAspectRatio < 1.0) {
        scaledImageHeight = imageAspectRatio * scaledImageWidth;
    }
    CGSize scaledImageSize = CGSizeMake(scaledImageWidth, scaledImageHeight);
    return [_image scaleToSize:scaledImageSize];
}

+ (NSString*)dayIdentifier:(NSDate*)_date {
    NSDateFormatter* julianDayFormatter = [[NSDateFormatter alloc] init];
    [julianDayFormatter setDateFormat:@"g"];
    return [julianDayFormatter stringFromDate:_date];
}

#pragma mark - 
#pragma mark CaptureManager Queues

- (void)waitForCaptureImageQueue {
    dispatch_sync(self.captureImageQueue, ^{});
}

- (void)dispatchAsyncCaptureImageQueue:(void(^)(void))_job {
    dispatch_async(self.captureImageQueue, _job);
}

- (void)waitForFullSizeImageQueue {
    dispatch_sync(self.fullSizeImageQueue, ^{});    
}

- (void)dispatchAsyncFullSizeImageQueue:(void(^)(void))_job {
    dispatch_async(self.fullSizeImageQueue, _job);
}

- (void)waitForQueues {
    [self waitForCaptureImageQueue];
    [self waitForFullSizeImageQueue];
}

#pragma mark - 
#pragma mark Captures

+ (void)saveCapture:(Capture*)_capture {
    [[DataContextManager instance] save];
    [[ViewGeneral instance] updateCalendarEntryWithDate:_capture.createdAt];
}

+ (void)deleteCapture:(Capture*)_capture; {
    [self deleteFullSizeImageForCapture:_capture];
    DataContextManager* contextManager = [DataContextManager instance];
    NSDate* createdAt = _capture.createdAt;
    [contextManager.mainObjectContext deleteObject:_capture];
    [contextManager save];
    [[ViewGeneral instance] updateCalendarEntryWithDate:createdAt];
}

- (void)createCaptureInBackgroundForImage:(UIImage*)_capturedImage {
    dispatch_async(self.captureImageQueue, ^{
        NSManagedObjectContext* requestMoc = [[DataContextManager instance] createContext];
        NSNotificationCenter *notify = [NSNotificationCenter defaultCenter];
        [notify addObserver:[DataContextManager instance] selector:@selector(mergeChangesWithMainContext:) name:NSManagedObjectContextDidSaveNotification object:requestMoc];        
        
        Capture* capture = [self createCaptureWithImage:_capturedImage inContext:requestMoc];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[ViewGeneral instance] addCapture:[self.class fetchCaptureWithId:capture.captureId]];
        });

        dispatch_async(self.fullSizeImageQueue, ^{
            [UIImageJPEGRepresentation(_capturedImage, 1.0f) writeToFile:[self.class fullSizeImagePathForCapture:capture] atomically:YES];
        });
    });
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

+ (Capture*)fetchCaptureWithId:(NSNumber*)_captureId {
    return [self fetchCaptureWithId:_captureId inContext:[DataContextManager instance].mainObjectContext];
}

+ (Capture*)fetchCaptureWithId:(NSNumber*)_captureId inContext:(NSManagedObjectContext*)_context {
    DataContextManager* contextManager = [DataContextManager instance];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"captureId == %@", _captureId]];
    return [contextManager fetchFirst:fetchRequest];
}

+ (NSArray*)fetchCapturesWithDayIdentifier:(NSString*)_dayIdentifier {
    DataContextManager* contextManager = [DataContextManager instance];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(dayIdentifier == %@)", _dayIdentifier]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO]]];
    return [contextManager fetch:fetchRequest];
}

+ (NSArray*)fetchCapturesWithDayIdentifier:(NSString*)_dayIdentifier betweenDates:(NSDate*)_startdate and:(NSDate*)_endDate {
    DataContextManager* contextManager = [DataContextManager instance];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(dayIdentifier == %@) AND (createdAt BETWEEN {%@, %@})", _dayIdentifier, _startdate, _endDate]];
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO]]];
    return [contextManager fetch:fetchRequest];
}

+ (NSArray*)fetchCaptureForEachDayBetweenDates:(NSDate*)_startdate and:(NSDate*)_endDate {
    DataContextManager* contextManager = [DataContextManager instance];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];    
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext]];    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(createdAt BETWEEN {%@, %@})", _startdate, _endDate]];    
    NSArray* fetchResults = [contextManager fetch:fetchRequest];
    
    NSArray* days = [fetchResults valueForKeyPath:@"@distinctUnionOfObjects.dayIdentifier"];
    NSArray* sortedDays = [days sortedArrayUsingFunction:descendingSort context:NULL];
    NSArray* aggregatedResults = [sortedDays mapObjectsUsingBlock:^id(id _obj, NSUInteger _idx) {
        NSString* day = _obj;
        NSArray* dayValues = [fetchResults filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"dayIdentifier == %@", day]];
        NSDate* latestDate = [dayValues valueForKeyPath:@"@max.createdAt"];
        return [[dayValues filteredArrayUsingPredicate:[NSPredicate predicateWithFormat: @"createdAt == %@", latestDate]] objectAtIndex:0];
    }];
    
    return aggregatedResults;
}

+ (Capture*)fetchCaptureWithDayIdentifierCreatedAt:(NSDate*)_createdAt {
    DataContextManager* contextManager = [DataContextManager instance];
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"Capture" inManagedObjectContext:contextManager.mainObjectContext]];   
    [fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:NO]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dayIdentifier == %@", [self dayIdentifier:_createdAt]]];
    return [contextManager fetchFirst:fetchRequest];
}

#pragma mark - 
#pragma mark Full Size Images

+ (UIImage*)fetchFullSizeImageForCapture:(Capture*)_capture {
    return [UIImage imageWithContentsOfFile:[self fullSizeImagePathForCapture:_capture]];
}

+ (void)deleteFullSizeImageForCapture:(Capture*)_capture {
    NSError* error;
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if ([fileMgr removeItemAtPath:[self fullSizeImagePathForCapture:_capture] error:&error] != YES) {
        [ViewGeneral alertOnError:error];
    }
}

+ (void)applyFilterToFullSizeImage:(Filter*)_filter withValue:(NSNumber*)_value toCapture:(Capture*)_capture {
}

@end
