//
//  ServiceManager.m
//  photio
//
//  Created by Troy Stribling on 6/18/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "ServiceManager.h"
#import "ViewGeneral.h"
#import "CaptureManager.h"
#import "DataContextManager.h"
#import "Service.h"
#import "Capture.h"

/////////////////////////////////////////////////////////////////////////////////////////
static ServiceManager* thisServiceManager = nil;

/////////////////////////////////////////////////////////////////////////////////////////
@interface ServiceManager (PrivateAPI)

+ (NSArray*)loadServices;
- (void)finishedSavingToCameraRoll:image:(UIImage*)_image didFinishSavingWithError:(NSError*)_error contextInfo:(void*)_context;
- (void)useServiceCameraRoll:(Service*)_service withCapture:(Capture*)_capture;
- (void)useServiceEMail:(Service*)_service withCapture:(Capture*)_capture;
- (void)useServiceTwitter:(Service*)_service withCapture:(Capture*)_capture;
- (void)useServiceFacebook:(Service*)_service withCapture:(Capture*)_capture;
- (void)useServiceTumbler:(Service*)_service withCapture:(Capture*)_capture;
- (void)useServiceInstagram:(Service*)_service withCapture:(Capture*)_capture;

@end

/////////////////////////////////////////////////////////////////////////////////////////
@implementation ServiceManager

@synthesize loadedServices, onComplete;

#pragma mark - 
#pragma mark ServiceManager Private

+ (NSArray*)loadServices {
    DataContextManager* contextManager = [DataContextManager instance];
    
    NSString* serviceFile = [[NSBundle  mainBundle] pathForResource:@"Services" ofType:@"plist"];
    NSArray* configuredServices = [[NSDictionary dictionaryWithContentsOfFile:serviceFile] objectForKey:@"services"];
    NSInteger configuredServicesCount = [configuredServices count];
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription* serviceEntity = [NSEntityDescription entityForName:@"Service" inManagedObjectContext:contextManager.mainObjectContext];
    [fetchRequest setEntity:serviceEntity];   
    NSInteger serviceCount = [contextManager count:fetchRequest];
    
    if (serviceCount < configuredServicesCount) {
        for (int i = 0; i < (configuredServicesCount - serviceCount); i++) {
            Service* service = (Service*)[NSEntityDescription insertNewObjectForEntityForName:@"Service" inManagedObjectContext:contextManager.mainObjectContext];
            NSDictionary* configuredService = [configuredServices objectAtIndex:(serviceCount + i)];
            service.name              = [configuredService objectForKey:@"name"];
            service.serviceId         = [configuredService objectForKey:@"serviceId"];
            service.imageFilename     = [configuredService objectForKey:@"imageFilename"];
            service.hidden            = [configuredService objectForKey:@"hidden"];
            service.usageRate         = [NSNumber numberWithFloat:0.0];
            service.usageCount        = [NSNumber numberWithFloat:0.0];
            [contextManager save];
        }
    }
    
    return [contextManager fetch:fetchRequest];    
}

- (void)finishedSavingToCameraRoll:image:(UIImage*)_image didFinishSavingWithError:(NSError*)_error contextInfo:(void*)_context {
    [[ViewGeneral instance] removeProgressView];
    self.onComplete();
    if (_error) {
        [[[UIAlertView alloc] initWithTitle:[_error localizedDescription] message:[_error localizedFailureReason] delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", @"OK button title") otherButtonTitles:nil] show];
    }
}

- (void)useServiceCameraRoll:(Service*)_service withCapture:(Capture*)_capture {
    [[ViewGeneral instance] showProgressViewWithMessage:@"Saving to Camera Roll"];
    UIImage* fullSizeImage = [CaptureManager fetchFullSizeImageForCapture:_capture];
    UIImageWriteToSavedPhotosAlbum(fullSizeImage, self, @selector(finishedSavingToCameraRoll::didFinishSavingWithError:contextInfo:), nil);
}

- (void)useServiceEMail:(Service*)_service withCapture:(Capture*)_capture {    
}

- (void)useServiceTwitter:(Service*)_service withCapture:(Capture*)_capture {
}

- (void)useServiceFacebook:(Service*)_service withCapture:(Capture*)_capture {
}

- (void)useServiceTumbler:(Service*)_service withCapture:(Capture*)_capture {
}

- (void)useServiceInstagram:(Service*)_service withCapture:(Capture*)_capture {
}

#pragma mark - 
#pragma mark ServiceManager

+ (ServiceManager*)instance {	
    @synchronized(self) {
        if (thisServiceManager == nil) {
            thisServiceManager = [[self alloc] init];
            thisServiceManager.loadedServices = [self loadServices];
        }
    }
    return thisServiceManager;
}

- (NSArray*)services {
    return self.loadedServices;
}

- (void)useService:(Service*)_service withCapture:(Capture*)_capture onComplete:(CompletionCallback)_onComplete {
    self.onComplete = _onComplete;
    switch ([_service.serviceId intValue]) {
        case ServiceTypeCameraRoll:
            [self useServiceCameraRoll:_service withCapture:_capture];
            break;
        case ServiceTypeEMail:
            [self useServiceEMail:_service withCapture:_capture];
            break;
        case ServiceTypeTwitter:
            [self useServiceTwitter:_service withCapture:_capture];
            break;
        case ServiceTypeFacebook:
            [self useServiceFacebook:_service withCapture:_capture];
            break;
        case ServiceTypeInstagram:
            [self useServiceInstagram:_service withCapture:_capture];
            break;
        case ServiceTypeTumbler:
            [self useServiceTumbler:_service withCapture:_capture];
            break;
    }
}

@end
