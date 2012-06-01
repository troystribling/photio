//
//  ImageFilterPaletteView.h
//  photio
//
//  Created by Troy Stribling on 5/19/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ImageEditView;

@interface ImageFilterPaletteView : UIView <UITableViewDataSource, UITableViewDelegate>

@property(nonatomic, weak)      ImageEditView*  imageEditView;
@property(nonatomic, strong)    NSArray*        filterPalettes;

+ (id)initInView:(ImageEditView*)_imageEditView;

@end