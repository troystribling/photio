//
//  FilterFactory.h
//  photio
//
//  Created by Troy Stribling on 5/18/12.
//  Copyright (c) 2012 imaginaryProducts. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FilterPalette;
@class Filter;

typedef enum {
    FilterTypeBrightness,
    FilterTypeContrast,
    FilterTypeRedColor,
    FilterTypeGreenColor,
    FilterTypeBlueColor,
    FilterTypeSaturation,
    FilterTypeVignette
} FilterType;

typedef enum {
    FilterPaletteTypeFavotites,
    FilterPaletteTypeImageAjustmentControls
} FilterPaletteType;

@interface FilterFactory : NSObject

@property(nonatomic, strong) NSArray*   loadedFilterPalettes;
@property(nonatomic, strong) NSArray*   loadedFilters;

+ (UIImage*)applyFilter:(Filter*)_filter withValue:(NSNumber*)_value toImage:(UIImage*)_image;
+ (FilterFactory*)instance;
- (FilterPalette*)defaultFilterPalette;
- (Filter*)defaultFilterForPalette:(FilterPalette*)_filterPalette;
- (NSArray*)filterPalettes;
- (NSArray*)filtersForPalette:(FilterPalette*)_filterPalette;

@end
