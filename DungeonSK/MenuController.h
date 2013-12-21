//
//  MenuController.h
//  DungeonSK
//
//  Created by Jeremy on 12/20/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MenuController : UIViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UISlider *mapWidthSlider;
@property (weak, nonatomic) IBOutlet UISlider *mapHeightSlider;
@property (weak, nonatomic) IBOutlet UISlider *roomMinSizeSlider;
@property (weak, nonatomic) IBOutlet UISlider *roomMaxSizeSlider;

@property (weak, nonatomic) IBOutlet UISlider *roomDensitySlider;
@property (weak, nonatomic) IBOutlet UISlider *corridorTypeSlider;

@property (weak, nonatomic) IBOutlet UILabel *roomDensityLabel;
@property (weak, nonatomic) IBOutlet UILabel *corridorTypeLabel;

@property (weak, nonatomic) IBOutlet UISwitch *removeDeadEndsSwitch;

@end


#define kWidthKey			@"width"
#define kHeightKey			@"height"
#define kRoomMinSizeKey		@"roomMinSize"
#define kRoomMaxSizeKey		@"roomMaxSize"
#define kRoomDensityKey		@"roomDensity"
#define kCorridorType		@"corridorType"
#define kRemoveDeadEnds		@"removeDeadEnds"
