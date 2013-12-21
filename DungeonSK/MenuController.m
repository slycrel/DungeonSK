//
//  MenuController.m
//  DungeonSK
//
//  Created by Jeremy on 12/20/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import "MenuController.h"
#import "dungeonScene.h"
#import "ViewController.h"


@interface MenuController ()

@property (weak, nonatomic) IBOutlet UILabel *mapWidthLabel;
@property (weak, nonatomic) IBOutlet UILabel *mapHeightLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomMinLabel;
@property (weak, nonatomic) IBOutlet UILabel *roomMaxLabel;


- (IBAction)saveButtonAction:(id)sender;
- (IBAction)cancelButtonAction:(id)sender;

- (IBAction)roomDensityValueChanged:(id)sender;
- (IBAction)corridorTypeValueChanged:(id)sender;
- (IBAction)mapWidthValueChanged:(id)sender;
- (IBAction)mapHeightValueChanged:(id)sender;
- (IBAction)roomMinSizeValueChanged:(id)sender;
- (IBAction)roomMaxSizeValueChanged:(id)sender;

@end


@implementation MenuController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	// set up slider bounds
	self.roomDensitySlider.minimumValue = noRooms;
	self.roomDensitySlider.maximumValue = maxRoomEnumValue-1;
	self.corridorTypeSlider.minimumValue = randomCorridorType;
	self.corridorTypeSlider.maximumValue = maxCorridorEnumValue-1;

	// load saved values from disk
	NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
	if ([settings integerForKey:kWidthKey] != 0)
	{
		// load saved values
		self.mapWidthSlider.value = [settings integerForKey:kWidthKey];
		self.mapHeightSlider.value = [settings integerForKey:kHeightKey];
		self.roomMinSizeSlider.value = [settings integerForKey:kRoomMinSizeKey];
		self.roomMaxSizeSlider.value = [settings integerForKey:kRoomMaxSizeKey];

		RoomDensityType roomDensity = [settings integerForKey:kRoomDensityKey];
		self.roomDensityLabel.text = [self roomDensityTextFromType:roomDensity];
		self.roomDensitySlider.value = roomDensity;
		
		CorridorType corridorType = [settings integerForKey:kCorridorType];
		self.corridorTypeLabel.text = [self corridorTextFromType:corridorType];
		self.corridorTypeSlider.value = corridorType;

		[self.removeDeadEndsSwitch setOn:[settings boolForKey:kRemoveDeadEnds] animated:YES];
	}
	
	[self updateSliderValue:self.mapWidthSlider withLabel:self.mapWidthLabel forceOdd:YES];
	[self updateSliderValue:self.mapHeightSlider withLabel:self.mapHeightLabel forceOdd:YES];
	[self updateSliderValue:self.roomMinSizeSlider withLabel:self.roomMinLabel forceOdd:NO];
	[self updateSliderValue:self.roomMaxSizeSlider withLabel:self.roomMaxLabel forceOdd:NO];
}


#pragma mark -


- (NSString*) roomDensityTextFromType:(RoomDensityType)type
{
	switch (type)
	{
		default:
		case noRooms:
			return @"No Rooms";
			break;
			
		case sparseRooms:
			return @"Sparse rooms";
			break;
			
		case someRooms:
			return @"Some rooms";
			break;
			
		case averageRooms:
			return @"Average rooms";
			break;
			
		case lotsOfRooms:
			return @"Lots of rooms";
			break;
			
		case veryRoomy:
			return @"Very roomy!";
			break;
	}
	
	return @"Unknown rooms value";
}


- (NSString*) corridorTextFromType:(CorridorType)type
{
	switch (type)
	{
		default:
		case randomCorridorType:
			return @"Random corridors";
			break;
			
		case bentCorridorType:
			return @"50% bendy corridors";
			break;
			
		case straightType:
			return @"95% straight corridors";
			break;
	}
	
	return @"Unknown Corridor type";
}


#pragma mark -


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	NSCharacterSet* numberSet = [NSCharacterSet characterSetWithCharactersInString:@"1234567890."];	// is this the same as decimal character set?
	if (string.length &&
		[string rangeOfCharacterFromSet:numberSet options:NSCaseInsensitiveSearch].location == NSNotFound)
	{
		return NO;
	}
	
	return YES;
}


#pragma mark -


- (IBAction)saveButtonAction:(id)sender
{
	NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];

	// save the new defaults, with bounds checking
	NSInteger mapWidth = MIN(MAX(self.mapWidthSlider.value, 0), 127);
	NSInteger mapHeight = MIN(MAX(self.mapHeightSlider.value, 0), 127);
	NSInteger roomMinSize = 5;
	NSInteger roomMaxSize = MAX(MIN(mapWidth, self.roomMaxSizeSlider.value), roomMinSize);
	
	[settings setInteger:mapWidth forKey:kWidthKey];
	[settings setInteger:mapHeight forKey:kHeightKey];
	[settings setInteger:roomMinSize forKey:kRoomMinSizeKey];
	[settings setInteger:roomMaxSize forKey:kRoomMaxSizeKey];
	[settings setInteger:lrint(self.roomDensitySlider.value) forKey:kRoomDensityKey];
	[settings setInteger:lrint(self.corridorTypeSlider.value) forKey:kCorridorType];
	[settings setBool:self.removeDeadEndsSwitch.isOn forKey:kRemoveDeadEnds];
	[settings synchronize];
	
	// now close the modal
	[self dismissViewControllerAnimated:YES completion:^{
		[(ViewController*)self.parentViewController regenAction:nil];
	}];
}


- (void)updateSliderValue:(UISlider*)slider withLabel:(UILabel*)label forceOdd:(BOOL)forceOdd
{
	NSInteger val = lrint(slider.value);
	if (val % 2 == 0 && forceOdd)
		val++;			// always an odd value
	
	label.text = [@(val) stringValue];
	slider.value = val;
}



- (IBAction)cancelButtonAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:^{ }];
}

- (IBAction)roomDensityValueChanged:(id)sender
{
	self.roomDensitySlider.value = lrint(self.roomDensitySlider.value);
	self.roomDensityLabel.text = [self roomDensityTextFromType:self.roomDensitySlider.value];
}

- (IBAction)corridorTypeValueChanged:(id)sender
{
	self.corridorTypeSlider.value = lrint(self.corridorTypeSlider.value);
	self.corridorTypeLabel.text = [self corridorTextFromType:self.corridorTypeSlider.value];
}

- (IBAction)mapWidthValueChanged:(id)sender
{
	[self updateSliderValue:self.mapWidthSlider withLabel:self.mapWidthLabel forceOdd:YES];
}

- (IBAction)mapHeightValueChanged:(id)sender
{
	[self updateSliderValue:self.mapHeightSlider withLabel:self.mapHeightLabel forceOdd:YES];
}

- (IBAction)roomMinSizeValueChanged:(id)sender
{
	[self updateSliderValue:self.roomMinSizeSlider withLabel:self.roomMinLabel forceOdd:NO];
}

- (IBAction)roomMaxSizeValueChanged:(id)sender
{
	[self updateSliderValue:self.roomMaxSizeSlider withLabel:self.roomMaxLabel forceOdd:NO];
}


@end
