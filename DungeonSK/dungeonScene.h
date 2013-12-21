//
//  MyScene.h
//  DungeonSK
//

//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

#import "TMXGenerator.h"
#import "JSTileMap.h"
#import "SFMT.h"

#define randomNum	gen_rand32	//arc4random

#define MapTileType	short


#define kWidthKey			@"width"
#define kHeightKey			@"height"
#define kDirectionKey		@"direction"
#define kRoomMinSizeKey		@"roomMinSize"
#define kRoomMaxSizeKey		@"roomMaxSize"
#define kRoomDensityKey		@"roomDensity"
#define kCorridorType		@"corridorType"
#define kRemoveDeadEnds		@"removeDeadEnds"


#define zerobits			0x0000
#define wallbit				0x1000
#define doorbit				0x2000
#define visitedbit			0x4000
#define exitbit				0x8000
#define roombit				0x0100
#define newDoorBit			0x0200
#define special5			0x0400
#define special6			0x0800
// room for 12 more...


// corridor types
typedef enum
{
	randomCorridorType = 0,			// totally random directions every time
	bentCorridorType,			// 50% straight
	straightType,		// 95% straight
	maxCorridorEnumValue
} CorridorType;

// room density
typedef enum
{
	noRooms = 0,			// **NOTE: noRooms does bad things with removal of dead ends!
	sparseRooms,
	someRooms,
	averageRooms,
	lotsOfRooms,
	veryRoomy,
	maxRoomEnumValue
} RoomDensityType;


typedef enum
{
	kDirectionUp = 1,
	kDirectionRight = 2,
	kDirectionDown = 3,
	kDirectionLeft = 4,
} DirectionType;


// HelloWorldLayer
@interface dungeonScene : SKScene <TMXGeneratorDelegate>

@property int width;
@property int height;
@property int roomMinSize;
@property int roomMaxSize;
@property int direction;	// a little hack never hurt anyone...  right?
@property BOOL removeDeadEnds;
@property CorridorType corridorType;
@property RoomDensityType roomDensity;

@property MapTileType* mapData;
@property (nonatomic, retain) JSTileMap* map;

- (void)regenerate;			// re-randomize the map

@end
