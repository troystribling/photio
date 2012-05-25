//
//  FilterImageView.m
//  photio
//
//  Created by Troy Stribling on 5/20/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import "FilterImageView.h"
#import "FilterUsage.h"

@interface FilterImageView (PrivateAPI)

- (void)didSelect;

@end

@implementation FilterImageView

@synthesize delegate, filter;

+ (id)withDelegate:(id<FilterImageViewDelegate>)_delegate andFilter:(FilterUsage*)_filter {
    UIImage* filterImage = [UIImage imageNamed:_filter.imageFilename];
    FilterImageView* view = [[FilterImageView alloc] initWithImage:filterImage];
    view.delegate = _delegate;
    return view;
}

- (void)didMoveToSuperview {
    UITapGestureRecognizer* selectGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelect)];
    selectGesture.numberOfTapsRequired = 1;
    selectGesture.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:selectGesture];
}

- (void)didSelect {
    [self.delegate applyFilter:self.filter];
}

@end
