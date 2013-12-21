//
//  MyScene.m
//  DungeonSK
//
//  Created by Jeremy on 10/10/13.
//  Copyright (c) 2013 Jeremy. All rights reserved.
//

#import "dungeonScene.h"
#import "AppDelegate.h"


@implementation dungeonScene

-(id)initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size])
	{
		[self doStuff];
    }
    return self;
}


-(void)update:(CFTimeInterval)currentTime {
    /* Called before each frame is rendered */
}


// on "init" you need to initialize your instance
-(id) init
{
	self = [super init];
	if(self)
	{
		[self doStuff];
	}
	return self;
}


#pragma mark -


- (void)regenerate
{
	[self.map removeFromParent];
	[self importSettings:NO];
	[self setupMapData];
	[self addMap];
}


- (void)randomizeSettings
{
	[self.map removeFromParent];
	[self importSettings:YES];
	[self setupMapData];
	[self addMap];
}


- (void) doStuff
{
	// import map settings
	[self importSettings:NO];
	
	// set up the data
	[self setupMapData];
	
	// set up the map
	[self addMap];
}

// alloc memory for our map data array.
- (MapTileType*) newMapData
{
	MapTileType* data = malloc(sizeof(MapTileType) * self.width * self.height);
	
	for (int x = 0; x < self.width; x++)
		for (int y = 0; y < self.height; y++)
			data[x + (y * self.height)] = wallbit;
	
	//	memset(data, zerobits, sizeof(MapTileType)* self.width * self.height);
	
	return data;
}


//#define kWidthKey			@"width"
//#define kHeightKey			@"height"
//#define kDirectionKey		@"direction"
//#define kRoomMinSizeKey		@"roomMinSize"
//#define kRoomMaxSizeKey		@"roomMaxSize"
//#define kRoomDensityKey		@"roomDensity"
//#define kCorridorType		@"corridorType"
//#define kRemoveDeadEnds		@"removeDeadEnds"

static long seed = 1010414;


// get the map settings for creation.
//
// **NOTE: map size must be odd for walls to match properly.
//
- (void) importSettings:(BOOL)randomSettings
{
	// added this so we can call it multiple times with the same random
	// settings rather than just defaults or totally random
	
	self.direction = 1;
	
	NSUserDefaults* settings = [NSUserDefaults standardUserDefaults];
	if (!randomSettings)
	{
		// load saved values from disk
		if ([settings integerForKey:kWidthKey] != 0)
		{
			// load saved values
			self.width = [settings integerForKey:kWidthKey];
			self.height = [settings integerForKey:kHeightKey];
			self.roomMaxSize = [settings integerForKey:kRoomMaxSizeKey];
			self.roomMinSize = [settings integerForKey:kRoomMinSizeKey];
			self.roomDensity = [settings integerForKey:kRoomDensityKey];
			self.corridorType = [settings integerForKey:kCorridorType];
			self.removeDeadEnds = [settings integerForKey:kRemoveDeadEnds];
		}
		else
		{
			// defaults
			self.width = 27;
			self.height = 27;
			self.roomMinSize = 5;
			self.roomMaxSize = MAX(MIN(24, self.width / 4), self.roomMinSize);
			self.roomDensity = lotsOfRooms;
			self.corridorType = bentCorridorType;
			self.removeDeadEnds = NO;
		}
	}
	else
	{
		// random settings, with some limits.
		int arbitraryCeiling = lrint(self.width + self.height / 2.0);
		int mapSize = MAX(25, randomNum() % 127);		// 25..127 map size
		if (mapSize % 2 == 0)	// make sure the map size is always odd for the right dimensions.
			mapSize++;
		self.width = mapSize;
		self.height = mapSize;
		self.roomMinSize = MIN(mapSize, MIN(3, randomNum() % arbitraryCeiling));
		if (self.roomMinSize % 2 == 0)
			self.roomMinSize--;
		self.roomMaxSize = MIN(mapSize, MAX(self.roomMinSize, randomNum() % arbitraryCeiling));
		if (self.roomMaxSize % 2 == 0)
			self.roomMaxSize++;
		
		self.roomDensity = randomNum() % 6;				// 0..5 to map to enum
		self.corridorType = randomNum() % 3;			// 0..2 to map to enum
		self.removeDeadEnds = PercentChance(50);
		
		// can't remove dead ends if no rooms (the whole maze is a dead end!)
		if (self.roomDensity == noRooms)
			self.removeDeadEnds = NO;
	}
	
	// save the values set above.
	[settings setInteger:self.width forKey:kWidthKey];
	[settings setInteger:self.height forKey:kHeightKey];
	[settings setInteger:self.roomMinSize forKey:kRoomMinSizeKey];
	[settings setInteger:self.roomMaxSize forKey:kRoomMaxSizeKey];
	[settings setInteger:self.roomDensity forKey:kRoomDensityKey];
	[settings setInteger:self.corridorType forKey:kCorridorType];
	[settings setBool:self.removeDeadEnds forKey:kRemoveDeadEnds];
	[settings synchronize];

	
#warning add setting for allowing connecting dead ends to rooms or other corridors.
	
#warning bug for room placement -- doesn't seem to bounds check correctly on the bottom/left for rooms?  min room size 3 at heavy weight doesn't fill like it should
#warning bug with non-square maps!  has to do with corridor pathing looks like...
#warning bug with dead end removal -- it doesn't work quite right.
#warning bug with maps sized > 127.  Is this a cocos2d bug or TMXGenerator bug?
	
	// to keep generating the same map set the seed to whatever default you'd like.
	init_gen_rand(seed);
	seed = [[NSDate date] timeIntervalSince1970];
	
	self.mapData = [self newMapData];
	
}


- (void) addMap
{
	NSError* error = nil;
	TMXGenerator* gen = [[TMXGenerator alloc] init];
	gen.delegate = self;
	
	[gen generateAndSaveTMXMap:&error];
	if (!error)
		self.map = [JSTileMap mapNamed:@"map.tmx"];//[[[CCTMXTiledMap alloc] initWithXML:mapXML resourcePath:@"."] autorelease];
	else
		NSLog(@"Error generating map, %d, %@", [error code], [error localizedDescription]);
	
	if (!self.map)
	{
		NSLog(@"Error generating TMX Map!  Error: %@, %d", [error localizedDescription], [error code]);
		return;
	}
	
	[self addChild:self.map];
}


#pragma mark - gestures and pinch/pan/zoom


- (void)didMoveToView:(SKView *)view
{
    UIPanGestureRecognizer *gestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanFrom:)];
    [self.view addGestureRecognizer:gestureRecognizer];
}


- (void)handlePanFrom:(UIPanGestureRecognizer *)recognizer
{
	if (recognizer.state == UIGestureRecognizerStateChanged)
	{
        CGPoint translation = [recognizer translationInView:recognizer.view];
        translation = CGPointMake(translation.x, -translation.y);
        [self panForTranslation:translation];
        [recognizer setTranslation:CGPointZero inView:recognizer.view];
    }
}


- (void)panForTranslation:(CGPoint)translation
{
    CGPoint position = [self.map position];
	CGPoint newPos = CGPointMake(position.x + translation.x, position.y + translation.y);
	[self.map setPosition:[self borderSafePosition:newPos]];
}


- (CGPoint)borderSafePosition:(CGPoint)newPos
{
    CGSize winSize = self.size;
	// map tile size * tiles in points *
	CGSize mapSize = CGSizeMake(self.map.mapSize.width * self.map.tileSize.width * self.map.xScale, self.map.mapSize.height * self.map.tileSize.height * self.map.yScale);
    CGPoint retval;
	
	CGFloat minX = -mapSize.width + winSize.width;
	CGFloat minY = -mapSize.height + winSize.height;
	retval.x = MAX( MIN(newPos.x, 0), minX);
	retval.y = MAX( MIN(newPos.y, 0), minY);
	
    return retval;
}


#pragma mark -
#pragma mark BEGIN Interesting Stuff
#pragma mark -


// directional order, pseudo-random
//
- (void) reorder:(int*)order percent:(int)percent
{
	int temp;
	if (percent < 50)
	{
		if (percent < 25)
		{
			temp = order[0];
			order[0] = order[3];
			order[3] = temp;
		}
		else
		{
			temp = order[1];
			order[1] = order[3];
			order[3] = temp;
		}
	}
	else //if (percent < 50)
	{
		if (percent < 75)
		{
			temp = order[2];
			order[2] = order[3];
			order[3] = temp;
		}
		else
		{
			temp = order[0];
			order[0] = order[2];
			order[2] = temp;
		}
	}
}


// given an array of 4 ints, sets the directional order to traverse the maze.
// attempts to honor the corridorType.
//
- (void) pseudoRandomOrder:(int*)order recurse:(BOOL)again
{
	int rnd = randomNum() % 100;							// we love percentages!
	
	// stay straight or go random?
	if ((self.corridorType == bentCorridorType && rnd >= 50) ||		// bent, keep the same starting direction 50% of the time
		(self.corridorType == straightType && rnd >= 10))	// straight, keep the same starting direction 90% of the time
	{
		if (order[0] != self.direction)
		{
			int oldDir = order[0];
			order[0] = self.direction;
			for (int a = kDirectionUp; a < kDirectionLeft; a++)
			{
				if (order[a] == order[0])
				{
					order[a] = oldDir;
					break;
				}
			}
		}
	}
	else	// random
	{
		[self reorder:order percent:rnd];
		
		// do it again on a semi-random basis.  Again only applies when we are choosing randomly, for... better randomization.
		if (again)
		{
			do
			{
				rnd = randomNum() % 100;
				[self reorder:order percent:rnd];
			} while (rnd % 2 != 0);
		}
	}
}


// step once through the maze.  Calls itself recursively.
- (BOOL) iterateCellX:(int)x Y:(int)y
{
	BOOL retVal = NO;
	int valids[4][4];
	memset(valids, 0, 4*4);
	
	int order[4] = {kDirectionUp, kDirectionRight, kDirectionDown, kDirectionLeft};
	[self pseudoRandomOrder:order recurse:YES];
	
	for (int i = 0; i < 4; i++)
	{
		BOOL thisPassRetVal = NO;
		int x1 = 0;
		int x2 = 0;
		int y1 = 0;
		int y2 = 0;
		
		bool visited = false;
		
		// remember the current direction for when we decide to recurse later.
		self.direction = order[i];
		
		switch (order[i])
		{
			case kDirectionUp:	// up
			default:
				visited = [self tileInfoForX:x Y:y + 2] & visitedbit;
				if (y + 2 < self.height)
				{
					y1 = y + 1;
					y2 = y + 2;
					x1 = x;
					x2 = x;
				}
				break;
				
			case kDirectionRight:	// right
				visited = [self tileInfoForX:x + 2 Y:y] & visitedbit;
				if (x + 2 < self.width)
				{
					y1 = y;
					y2 = y;
					x1 = x + 1;
					x2 = x + 2;
				}
				break;
				
			case kDirectionDown:	// down
				visited = [self tileInfoForX:x Y:y - 2] & visitedbit;
				if (y - 2 > 0)
				{
					y1 = y - 1;
					y2 = y - 2;
					x1 = x;
					x2 = x;
				}
				break;
				
			case kDirectionLeft:	// left
				visited = [self tileInfoForX:x - 2 Y:y] & visitedbit;
				if (x - 2 < self.width)
				{
					y1 = y;
					y2 = y;
					x1 = x - 1;
					x2 = x - 2;
				}
				break;
		}
		
		// if we found a valid possible route, within our map bounds, follow it.
		if (x1 && x2 && y1 && y2)
		{
			MapTileType info = [self tileInfoForX:x2 Y:y2];
			MapTileType info2 = [self tileInfoForX:x1 Y:y1];
			MapTileType extra = (info & exitbit) | (info2 & exitbit);
			if (extra)
				thisPassRetVal = YES;
			
			if (!visited)
			{
				// follow it as walled and visited, after the recursion it will mark it as free space
				[self setTileInfo:visitedbit|extra forX:x1 Y:y1];
				[self setTileInfo:visitedbit|extra forX:x2 Y:y2];
				
				if ([self iterateCellX:x2 Y:y2] || thisPassRetVal)
				{
					thisPassRetVal = YES;
				}
				else if (!thisPassRetVal && !extra)
				{
					if (self.removeDeadEnds)
					{
						[self setTileInfo:wallbit|visitedbit|extra forX:x1 Y:y1];
						[self setTileInfo:wallbit|visitedbit|extra forX:x2 Y:y2];
					}
				}
			}
		}
		
		if (!retVal)
			retVal = thisPassRetVal;
	}
	
	return retVal;
}


BOOL PercentChance(int upToPercent)
{
	if ( (randomNum() % 100) < upToPercent)
		return YES;
	return NO;
}


#pragma mark -
#pragma mark rooms


// return NO if a door is not yet in the requested wall -OR- if all sides have doors.
- (BOOL) doorInThisWall:(long*)doorVal whichWall:(int)whichWall update:(BOOL)updateDoorVal
{
	BOOL retVal = NO;
	
	long top = 0x0001;
	long left = 0x0010;
	long bottom = 0x0100;
	long right = 0x1000;
	long allWalls = top | left | bottom | right;
	long setVal = 0;
	
	switch (whichWall)
	{
		default:
		case 1:
			if (*doorVal & top)
				retVal = YES;
			setVal = top;
			break;
			
		case 2:
			if (*doorVal & left)
				retVal = YES;
			setVal = left;
			break;
			
		case 3:
			if (*doorVal & bottom)
				retVal = YES;
			setVal = bottom;
			break;
			
		case 4:
			if (*doorVal & right)
				retVal = YES;
			setVal = right;
			break;
	}
	
	*doorVal |= setVal;
	
	// if all walls have a door in them then return NO so that this wall is available for an additional door.
	if (*doorVal & allWalls)
		retVal = NO;
	
	return retVal;
}


// place the doors for the rooms.
//
- (void) placeDoorsX:(int)x Y:(int)y width:(int)wid height:(int)ht
{
	int numDoors = 2;
	int dwindlingPercent = 50;
	while (PercentChance(dwindlingPercent))	// add additional doors every 20% that is hit.
	{
		numDoors++;
		dwindlingPercent = lrint(dwindlingPercent / 2.0);	// reduce the chance by half for additional doors.
	}
	
	// do a little manual correction.  For large rooms, make sure we have 3 to 6 doors
	//	int avgRoomSide = (self.roomMaxSize + self.roomMinSize) / 2.0;
	//	if (wid + ht >= avgRoomSide)
	//		numDoors += 1;
	//	if (wid + ht >= lrint(avgRoomSide * 1.5))
	//		numDoors += 1;
	
	numDoors = 4;
	long visited = 0;
	
	while (numDoors)
	{
		int x1, y1, x2, y2;
		int num = randomNum() % 4 + 1; // 0..3 + 1
		
		// each door should (usually) be on a different wall
		if ([self doorInThisWall:&visited whichWall:num update:YES])// &&
			//			PercentChance(80))
		{
			continue;
		}
		
		numDoors--;
		
		switch (num)
		{
			default:
			case 1:		// top
				x1 = x + randomNum() % wid;
				if (x1 % 2 == 0)	// make sure it's odd so our room doors aren't next to each other ever or they don't go into a "middle" part of a corridor, only the ends.
					x1--;
				y1 = y - 1;
				x2 = x1;
				y2 = y1 - 1;
				//				NSLog(@"exit type %d, room starting at (%d, %d) (w/h:%d, %d), exit at (%d, %d) and (%d, %d)", num, x, y, wid, ht, x1, y1, x2, y2);
				break;
			case 2:		// left
				x1 = x - 1;
				y1 = y + randomNum() % ht;
				if (y1 % 2 == 0)	// make sure it's odd so our room doors aren't next to each other ever or they don't go into a "middle" part of a corridor, only the ends.
					y1--;
				x2 = x1 - 1;
				y2 = y1;
				//				NSLog(@"exit type %d, room starting at (%d, %d) (w/h:%d, %d), exit at (%d, %d) and (%d, %d)", num, x, y, wid, ht, x1, y1, x2, y2);
				break;
			case 3:		// bottom
				x1 = x + randomNum() % wid;
				if (x1 % 2 == 0)	// make sure it's odd so our room doors aren't next to each other ever or they don't go into a "middle" part of a corridor, only the ends.
					x1--;
				y1 = y + ht;
				x2 = x1;
				y2 = y1 + 1;
				//				NSLog(@"exit type %d, room starting at (%d, %d) (w/h:%d, %d), exit at (%d, %d) and (%d, %d)", num, x, y, wid, ht, x1, y1, x2, y2);
				break;
			case 4:		// right
				x1 = x + wid;
				y1 = y + randomNum() % ht;
				if (y1 % 2 == 0)	// make sure it's odd so our room doors aren't next to each other ever or they don't go into a "middle" part of a corridor, only the ends.
					y1--;
				x2 = x1 + 1;
				y2 = y1;
				//				NSLog(@"exit type %d, room starting at (%d, %d) (w/h:%d, %d), exit at (%d, %d) and (%d, %d)", num, x, y, wid, ht, x1, y1, x2, y2);
				break;
		}
		
		[self setTileInfo:zerobits|exitbit forX:x1 Y:y1];
		[self setTileInfo:zerobits|exitbit forX:x2 Y:y2];
	}
}


// how many rooms should we have?
//
- (int) roomWeightValue:(int)density
{
	// to try and be smart, let's take the number of tiles we have available to us and make average
	// sized rooms out of them.  Then divide our tile space by the room size to see how many we
	// on average could fit without corridors.  Then multiply that number by a percentage based
	// on the density.
	int retVal = 0;
	int tilePool = self.width * self.height;
	int avgRoomSide = (self.roomMaxSize + self.roomMinSize) / 2.0;
	int avgRoomSize = avgRoomSide * avgRoomSide;
	int moreAvgRooms = lrint(tilePool / (self.roomMinSize * avgRoomSide));
	int avgNumRooms = lrint(tilePool / avgRoomSize);
	
	switch (density)
	{
		case noRooms:
		default:
			// 0, set above
			break;
			
		case sparseRooms:
			retVal = lrint(avgNumRooms * 0.25) + 1;
			break;
			
		case someRooms:
			retVal = lrint(avgNumRooms * 0.5) + 1;
			break;
			
		case averageRooms:
			retVal = lrint(moreAvgRooms * 0.75) + 1;
			break;
			
		case lotsOfRooms:
			retVal = moreAvgRooms;
			break;
			
		case veryRoomy:		// as many as will fit?
			retVal = tilePool / (self.roomMinSize * self.roomMinSize);
			break;
	}
	return retVal;
}


- (int) roomSpacingForDensity:(int)density
{
	int roomSpacing = 3;
	int widerSpacedRooms = 30;
	int closerSpacedRooms = 15;
	
	// room density modification
	switch (density)
	{
		case noRooms:
		case sparseRooms:
			widerSpacedRooms = 100;
			closerSpacedRooms = 0;
			break;
			
		case someRooms:
			widerSpacedRooms = 75;
			closerSpacedRooms = 25;
			break;
			
		case averageRooms:
		default:
			// set above
			break;
			
		case lotsOfRooms:
			widerSpacedRooms = 25;
			closerSpacedRooms = 75;
			break;
			
		case veryRoomy:
			widerSpacedRooms = 0;
			closerSpacedRooms = 100;
			break;
	}
	
	// random room variation spacing
	if (PercentChance(widerSpacedRooms))
		roomSpacing = 5;
	if (PercentChance(closerSpacedRooms))
		roomSpacing = 1;
	
	return roomSpacing;
}


// adds rooms given the pre-set inputs.
//
- (void) addRooms
{
	int roomCount = [self roomWeightValue:self.roomDensity];
	
	while (roomCount)
	{
		// make a room.
		int mod = MAX(self.width / 10, self.roomMaxSize);
		int minRoomLen = self.roomMinSize;
		int wid = MAX(randomNum() % mod, minRoomLen);
		int ht = MAX(randomNum() % mod, minRoomLen);
		
		// less long, more square rooms
		if (wid * 2 < ht)
			ht -= wid;
		else if (ht * 2 < wid)
			wid -= ht;
		
		if (wid % 2 == 0)	// make sure room widths are odd
			wid++;
		if (ht % 2 == 0)
			ht++;
		
		// range between 0 + 2 and self.width
		int maxx = self.width - 4;
		int maxy = self.height - 4;
		
		// if we don't have enough space to place a minimum room then stop
		if (maxx < wid && maxy < ht)
			break;
		
		// figure out where to start building the room
		int attempts = 200;		// max attempts for a room.
		int startx, starty;
		bool valid = true;
		BOOL tooSmall = NO;
		do
		{
			startx = MAX((randomNum() % maxx), 3);
			starty = MAX((randomNum() % maxy), 3);
			if (startx % 2 == 0)	// always make the room start on odd tiles
				startx--;
			if (starty % 2 == 0)
				starty--;
			
			// bounds check
			if (startx + wid + 1 >= maxx ||
				starty + ht + 1 >= maxy)
			{
				valid = false;
				continue;
			}
			
			// default blocks, chance of 1, 3 or 5 blocks.
			int roomSpacing = [self roomSpacingForDensity:self.roomDensity];
			bool roomCollision = false;
			
			for (int x = -MIN(roomSpacing, startx); x < wid+roomSpacing && !roomCollision; x++)
			{
				for (int y = -MIN(roomSpacing, starty); y < ht+roomSpacing && !roomCollision; y++)
				{
					if ([self tileInfoForX:startx + x Y:starty + y] & roombit)
						roomCollision = true;
				}
			}
			
			if (roomCollision)
				valid = false;
			else
				valid = true;
			
			// trim the room size a bit to see if we can force a fit.  If it gets to small, abandon the room.
			if (!valid)
			{
				// -2 here for hallway space on each step.  So we don't get doubled-up walls.
				if ((wid - 2) < minRoomLen && (ht - 2) < minRoomLen)
					tooSmall = YES;
				wid = MAX(wid - 2, minRoomLen);
				ht = MAX(ht - 2, minRoomLen);
			}
		} while (!valid && !tooSmall && --attempts > 0);
		
		if (valid)
		{
			// place the room
			for (int x = -1; x < wid + 1; x++)
			{
				for (int y = -1; y < ht + 1; y++)
				{
					MapTileType info = [self tileInfoForX:startx + x Y:starty + y];
					
					if (info & exitbit)	// don't write over the top of doors or entrances
						continue;
					
					// room border
					if (x == -1 || y == -1 || x == wid || y == ht)
						[self setTileInfo:wallbit|visitedbit forX:startx + x Y:starty + y];
					// open up the room!
					else
						[self setTileInfo:roombit|visitedbit forX:startx + x Y:starty + y];
				}
			}
			
			// place the entrances to the room
			[self placeDoorsX:startx Y:starty width:wid height:ht];
		}
		
		// remove the room space from the pool.
		roomCount--;
	}
}


// depth-first search for corridors, after rooms have been placed.
//
- (void) setupMapData
{
	[self addRooms];
	
	// recursively build the maze.
	//	[self iterateCellX:1 Y:1];
	
	// changed this to a loop to get rooms that may have "blank space" on an inside track of rooms.
	for (int x = 1; x < self.width; x += 2)
		for (int y = 1; y < self.height; y += 2)
			[self iterateCellX:x Y:y];
}


#pragma mark -
#pragma mark END interesting Stuff


#pragma mark -
#pragma mark Accessors

// I hate linear 2d arrays, these are here so I can ignore the math that can be in the way of my thought processes.
- (void) setTileInfo:(MapTileType)info forX:(int)x Y:(int)y
{
	self.mapData[x + (y * self.height)] = info;
}

- (MapTileType) tileInfoForX:(int)x Y:(int)y
{
	MapTileType retVal = self.mapData[x + (y * self.height)];
	return retVal;
}


#pragma mark -
#pragma mark TMXGeneratorDelegate

#define kNumPixelsPerTileSquare	64
#define kNumPixelsBetweenTiles 2
#define kMapWidth self.width
#define kMapHeight self.height


- (NSString*) tileAtlasForLayerNamed:(NSString*)layerName		{ return @"caveAtlas.png"; }

- (NSString*) mapFilePath
{
	NSString* fileName = @"map.tmx";
	NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:fileName];
	return fullPath;
};


// basic map setup
- (NSDictionary*) mapAttributeSetup
{
	NSMutableDictionary* dict = [NSMutableDictionary dictionaryWithCapacity:5];
	[dict setObject:[NSString stringWithFormat:@"%i", kMapWidth] forKey:kTMXGeneratorHeaderInfoMapWidth];
	[dict setObject:[NSString stringWithFormat:@"%i", kMapHeight] forKey:kTMXGeneratorHeaderInfoMapHeight];
	[dict setObject:[NSString stringWithFormat:@"%i", kNumPixelsPerTileSquare] forKey:kTMXGeneratorHeaderInfoMapTileWidth];
	[dict setObject:[NSString stringWithFormat:@"%i", kNumPixelsPerTileSquare] forKey:kTMXGeneratorHeaderInfoMapTileHeight];
	[dict setObject:[self mapFilePath] forKey:kTMXGeneratorHeaderInfoMapPath];
	[dict setObject:[NSDictionary dictionaryWithObject:@"Test property" forKey:@"property"] forKey:kTMXGeneratorHeaderInfoMapProperties];
	return dict;
}

// set up default tileset
- (NSDictionary*) tileSetInfoForName:(NSString*)name
{
	// we only have one tileset so always return the same thing
	NSDictionary* dict = [TMXGenerator tileSetWithImage:[self tileAtlasForLayerNamed:name]
												  named:name
												  width:kNumPixelsPerTileSquare
												 height:kNumPixelsPerTileSquare
											tileSpacing:kNumPixelsBetweenTiles];
	return dict;
}


- (NSDictionary*) layerInfoForName:(NSString*)name
{
	// same for both layers
	NSDictionary* dict = [TMXGenerator layerNamed:name width:kMapWidth height:kMapHeight data:nil visible:YES];
	return dict;
}


// determines the initial state of the map
- (int) tileGIDForLayer:(NSString*)layerName tileSetName:(NSString*)tileSetName X:(int)x Y:(int)y
{
	MapTileType info = [self tileInfoForX:x Y:y];
	int gid = 0;	// default to wall
	
	if ((info & wallbit) == zerobits)
		gid = 1;	// non-wall
	
	return gid;
}

@end
