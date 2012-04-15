//
//  CalendarEntryView.h
//  photio
//
//  Created by Troy Stribling on 3/10/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CalandarDateView;
@class CalendarDayBackgroundView;

@interface CalendarEntryView : UIView 

@property(nonatomic, strong) CalandarDateView*          dateView; 
@property(nonatomic, strong) CalendarDayBackgroundView* backgroundView;
@property(nonatomic, strong) UIImageView*               photoView;

+ (id)withFrame:(CGRect)_frame date:(NSString*)_date dayOfWeek:(NSString*)_dayOfWeek andPhoto:(UIImage*)_photo;
- (id)initWithFrame:(CGRect)_frame date:(NSString*)_date dayOfWeek:(NSString*)_dayOfWeek andPhoto:(UIImage*)_photo;

@end
