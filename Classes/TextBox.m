//
//  TextBox.m
//  TextBox
//
//  Created by Jussi Enroos on 28.3.2013.
//  Copyright 2013 Jussi Enroos. All rights reserved.
//

#import "TextBox.h"

#define DEFAULT_LINE_SPACING 1.0f

int numberOfHexValue(char hex) 
{
	// 0 ... 9
	if (hex >= '0' && hex <= '9') {
		return hex - '0';
	}
	// A ... F
	if (hex >= 'A' && hex <= 'F') {
		return hex - ('A' - 10);
	}
	// a ... f
	if (hex >= 'a' && hex <= 'f') {
		return hex - ('a' - 10);
	}
	return 0;
}

ccColor3B getColorFromHex(const char* data)
{
	// Sanity check
	if (strlen(data) != 6) {
		return ccc3(255, 255, 255);
	}
	
	// create colors
	GLubyte r = numberOfHexValue(data[0]) * 16 + numberOfHexValue(data[1]);
	GLubyte g = numberOfHexValue(data[2]) * 16 + numberOfHexValue(data[3]);
	GLubyte b = numberOfHexValue(data[4]) * 16 + numberOfHexValue(data[5]);
	
	return ccc3(r, g, b);
}


typedef enum {
	tbs_text,
	// If > tbs_text -> inside tag
	tbs_tagName,
	tbs_tagColor,
	tbs_tagSprite,
	tbs_lineEnd,
	tbs_stringEnd,
	tbs_imgAttributeName,
	tbs_imgYAttribute,
	tbs_imgXAttribute,
	tbs_imgScaleAttribute,
	tbs_imgWidthAttribute,
} TextBoxReadStates;

@interface TextBox ()

@property (retain) NSString *stringStore;
@property (retain) NSString *font;
@property (retain) CCNode	*currentNode;

- (void)refreshView;

@end


@implementation TextBox

@synthesize stringStore = stringStore_;
@synthesize font = font_;
@synthesize currentNode = currentNode_;

- (id) init
{
	if (self = [super init]) {
		self.stringStore = nil;
		self.font = nil;
		
		anchorPoint_.x  = 0.5f;
		anchorPoint_.y  = 0.5f;
		
		lineSpacing_	= DEFAULT_LINE_SPACING;
	}
	[self refreshView];
	return self;
}

- (id) initWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize dimensions:(CGSize) dimensions halignment:(int) halignment color:(ccColor3B) color
{
	if (self = [super init]) {
		self.stringStore 	= text;
		self.font 			= fontName;
		
		size_ 				= fontSize;
		boxSize_ 			= dimensions;
		
		horzAlign_			= halignment;
		vertAlign_			= 1;			// Center
		
		fontColor_			= color;

		anchorPoint_.x	 	= 0.5f;
		anchorPoint_.y 		= 0.5f;
		
		lineSpacing_		= DEFAULT_LINE_SPACING;
	}
	[self refreshView];
	return self;
}

+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize
{
	TextBox *box = [[TextBox alloc] initWithString:text fontName:fontName fontSize:fontSize dimensions:CGSizeMake(1000.0f, 1000.0f) halignment:1 color:ccWHITE];
	return [box autorelease];
}
				
+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize dimensions:(CGSize) dimensions halignment:(int) halignment
{
	TextBox *box = [[TextBox alloc] initWithString:text fontName:fontName fontSize:fontSize dimensions:dimensions halignment:halignment color:ccWHITE];
	return [box autorelease];
}
				
+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize dimensions:(CGSize) dimensions halignment:(int) halignment color:(ccColor3B) color
{
	TextBox *box = [[TextBox alloc] initWithString:text fontName:fontName fontSize:fontSize dimensions:dimensions halignment:halignment color:color];
	return [box autorelease];
}


- (NSString*) string
{
	return stringStore_;
}

- (void) setString:(NSString *)text
{
	// Retain string
	self.stringStore = text;
	
	// Refresh view
	[self refreshView];
}

- (void)refreshView
{
	// Remove all children first
	[self removeAllChildrenWithCleanup:YES];
	
	// Create font for size measurements
	UIFont 	*uiFont = [UIFont fontWithName:font_ size:size_];
	
	CGSize  testStringSize = [@" " sizeWithFont:uiFont];
	CGFloat lineHeight = testStringSize.height;
	CGFloat	spaceWidth = testStringSize.width;
	
	// Nothing to be done, if line height is too small
	if (lineHeight > boxSize_.height) {
		return;
	}
	
	// Line position variable
	CGFloat linePosition = 0.0f;
	CGFloat yPosition = 0.0f;
	
	int		charPosition = 0;
	int		lastWordPosition = 0;
	
	ccColor3B currentColor = fontColor_;
	
	const char 	*text = [stringStore_ cStringUsingEncoding:NSUTF8StringEncoding];
	//int		textLength = strlen(text);
	char	previousChar = '\0'; 
		
	CGFloat	maxWidth = boxSize_.width;
	
	CGFloat yDiff 		= 0.0f;
	CGFloat xDiff 		= 0.0f;
	CGFloat	widthDiff 	= 0.0f;
	float	scaleValue	= 1.0f;
	
	NSMutableArray *rowItems = [NSMutableArray arrayWithCapacity:3];
	
	// reading state
	int state = tbs_text;

	CGFloat prevWordWidth = 0.0f;
	
	CGSize nodeSize = CGSizeMake(0.0f, 0.0f);
	
	BOOL nodeFinished = NO;
	
	// Get next word break or state change
	BOOL breakFound = NO;
	while (!!! breakFound) {
		
		// End of string
		if (text[charPosition] == '\0') {
			breakFound = YES;
		}
		
		// End of word
		if (state == tbs_text && (text[charPosition] == ' ' || (text[charPosition] == '[' && previousChar != ' ') || breakFound)) {
			
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 2;
			
			if (text[charPosition] == '[') {
				wordSize -= 1;
			}
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			lastWordPosition = charPosition + 1;
			
			NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			if (string != nil && [string length] > 0) {
				CCLabelTTF *label = [CCLabelTTF labelWithString:string fontName:font_ fontSize:size_];
				[label setColor:currentColor];
				label.anchorPoint = ccp(0.0f, 0.0f);
				[[label texture] setAliasTexParameters];
				
				// Hold on to the node
				self.currentNode = label;
				nodeSize = [string sizeWithFont:uiFont];
				
				nodeFinished = YES;
			}
			
			free(word);
			
		}
		
		// Start of tag
		if (state == tbs_text && text[charPosition] == '[') {
			lastWordPosition = charPosition + 1;
			state = tbs_tagName;
		}
		
		// End of tag name
		else if (state == tbs_tagName && text[charPosition] == '='){
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			lastWordPosition = charPosition + 1;
			
			// Read tag name
			//NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"Tag name: %@", string);
			
			if (strcmp(word, "img") == 0) {
				state = tbs_tagSprite;
			} else if (strcmp(word, "color") == 0) {
				state = tbs_tagColor;
			}
			
			free(word);
			
		}
		
		// End of close tag
		else if (state == tbs_tagName && text[charPosition] == ']') {
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			// Read tag name
			//NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"Close tag: %@", string);
			
			if (strcmp(word, "/color") == 0) {
				currentColor = fontColor_;
			}
			
			lastWordPosition = charPosition + 1;
			state = tbs_text;
			
			free(word);
		}
		
		// End of img name
		else if (state == tbs_tagSprite && (text[charPosition] == ']' || text[charPosition] == ';')) {
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			// Read tag name
			NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"Sprite name: %@", string);
			
			CCSprite *sprite = [[CCSprite new] autorelease];
			[sprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:string]];
			if ([sprite displayedFrame] != nil && [sprite displayedFrame].texture != nil) {
				self.currentNode = sprite;
				nodeSize = [sprite boundingBox].size;
				[sprite setAnchorPoint:ccp(0.0f, 0.0f)];
				
				if (text[charPosition] == ']') {
					nodeFinished = YES;
				}
			}
			
			lastWordPosition = charPosition + 1;
			
			if (text[charPosition] == ';') {
				state = tbs_imgAttributeName;
			} else {
				state = tbs_text;
			}
			
			free(word);
		}
		
		// End of img name, start of attributes
		/*else if (state == tbs_tagSprite && text[charPosition] == ';') {
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			// Read tag name
			NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"Sprite name: %@", string);
			
			CCSprite *sprite = [[CCSprite new] autorelease];
			[sprite setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:string]];
			if ([sprite displayedFrame] != nil && [sprite displayedFrame].texture != nil) {
				self.currentNode = sprite;
				nodeSize = [sprite boundingBox].size;
				[sprite setAnchorPoint:ccp(0.0f, 0.0f)];
			}
			
			lastWordPosition = charPosition + 1;
			state = tbs_imgAttributeName;
			
			free(word);
		}*/
		
		// End of img attribute, possibly start of attributes
		else if (state >= tbs_imgYAttribute && state <= tbs_imgWidthAttribute && (text[charPosition] == ';' || text[charPosition] == ']')) {
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			lastWordPosition = charPosition + 1;
			
			// Read attribute
			if (state == tbs_imgYAttribute) {
				yDiff = atof(word);
			} else if (state == tbs_imgXAttribute) {
				xDiff = atof(word);
			} else if (state == tbs_imgWidthAttribute) {
				widthDiff = atof(word);
			} else if (state == tbs_imgScaleAttribute) {
				scaleValue = atof(word);
			}
			
			// Change state
			if (text[charPosition] == ';') {
				state = tbs_imgAttributeName;
			} else {
				state = tbs_text;
				nodeFinished = YES;
			}
			
			lastWordPosition = charPosition + 1;
			
			free(word);
		}
		
		
		// End of img attribute name
		else if (state == tbs_imgAttributeName && text[charPosition] == '='){
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			lastWordPosition = charPosition + 1;
			
			// Read tag name
			//NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"img attribute name: %@", string);
			
			if (strcmp(word, "y") == 0) {
				state = tbs_imgYAttribute;
			} else if (strcmp(word, "x") == 0) {
				state = tbs_imgXAttribute;
			} else if (strcmp(word, "width") == 0) {
				state = tbs_imgWidthAttribute;
			} else if (strcmp(word, "scale") == 0) {
				state = tbs_imgScaleAttribute;
			}
			
			free(word);
			
		}

		// End of color name
		else if (state == tbs_tagColor && text[charPosition] == ']') {
			// Create a word
			size_t wordSize = charPosition - lastWordPosition + 1;
			
			char *word = malloc(wordSize);
			strncpy(word, &text[lastWordPosition], wordSize - 1);
			word[wordSize - 1] = '\0';
			
			// Read tag name
			//NSString *string = [NSString stringWithCString:word encoding:NSUTF8StringEncoding];
			//NSLog(@"Color code: %@", string);
			
			currentColor = getColorFromHex(word);
			
			lastWordPosition = charPosition + 1;
			state = tbs_text;
			
			free(word);
		}
		
		// Any invalid tag end
		else if (text[charPosition] == ']') {
			lastWordPosition = charPosition + 1;
			
			yDiff = 0.0f;
			xDiff = 0.0f;
			widthDiff = 0.0f;
			scaleValue = 1.0f;
			
			state = tbs_text;
		}
		
		// Position node, if created
		if (currentNode_ != nil && nodeFinished) {
			CGFloat newPos = linePosition + nodeSize.width + widthDiff + xDiff;
			
			// This triggers if an orphan word is last
			BOOL positioned = NO;
			
			if (newPos >= maxWidth || breakFound) {
				
				// Last item
				if (breakFound && newPos < maxWidth) {
					[currentNode_ setPosition:ccp(linePosition, yPosition)];
					linePosition += nodeSize.width + widthDiff + xDiff;
					[rowItems addObject:currentNode_];
				}
				else if (breakFound) {
					// Last item special positioning (TODO: make this work without excpetion handling)
					if (horzAlign_ == UITextAlignmentCenter) {
						[currentNode_ setPosition:ccp(-nodeSize.width / 2.0f + ((0.5f - anchorPoint_.x) * boxSize_.width) + xDiff, yPosition + yDiff - lineHeight * lineSpacing_)];
					} else if (horzAlign_ == UITextAlignmentLeft) {
						[currentNode_ setPosition:ccp(- (anchorPoint_.x * boxSize_.width) + xDiff, yPosition + yDiff - lineHeight * lineSpacing_)];
					} else if (horzAlign_ == UITextAlignmentRight) {
						[currentNode_ setPosition:ccp(- (anchorPoint_.x * boxSize_.width) + (boxSize_.width - nodeSize.width) + xDiff, yPosition + yDiff - lineHeight * lineSpacing_)];
					}
					positioned = YES;
				}
				
				// No additional space to last line
				float space = 0.0f;
				
				if ((!!! breakFound && text[charPosition] == ' ')
					|| positioned) {
					space = spaceWidth;
				}
				
				// Reposition all line items
				if (horzAlign_ == UITextAlignmentCenter) {
					
					CGFloat amount = (linePosition - space) / 2.0f;
					if (linePosition == 0.0f) {
						amount = (prevWordWidth - space) / 2.0f;
					}
					
					for (CCNode *node in rowItems) {
						[node setPosition:ccp(node.position.x - amount + ((0.5f - anchorPoint_.x) * boxSize_.width), node.position.y)];
					}
				}
				else if (horzAlign_ == UITextAlignmentLeft) {
					
					for (CCNode *node in rowItems) {
						[node setPosition:ccp(node.position.x - (anchorPoint_.x * boxSize_.width), node.position.y)];
					}
				}
				else if (horzAlign_ == UITextAlignmentRight) {
					
					CGFloat amount = linePosition - space;
					if (linePosition == 0.0f) {
						amount = prevWordWidth - space;
					}
				
					for (CCNode *node in rowItems) {
						[node setPosition:ccp(node.position.x - amount + (anchorPoint_.x * boxSize_.width), node.position.y)];
					}
				}
				
				[rowItems removeAllObjects];
				linePosition = 0.0f;
				
				// Hitting max height
				if (yPosition - lineHeight * lineSpacing_ < -boxSize_.height) {
					breakFound = YES;
				} else {
					yPosition -= lineHeight * lineSpacing_;
				}
				
			}
			
			if ((!!! breakFound || (breakFound && newPos >= maxWidth)) && !!! positioned) {
				[currentNode_ setPosition:ccp(linePosition + xDiff, yPosition + yDiff)];
				linePosition += nodeSize.width + widthDiff + xDiff;
			}
			
			if (positioned) {
				yPosition -= lineHeight * lineSpacing_;
			}
			
			prevWordWidth = nodeSize.width;
			
			if (yPosition >= -boxSize_.height) {
				[currentNode_ setScale:scaleValue];
				
				[self addChild:currentNode_];
				[rowItems addObject:currentNode_];
			}
			
			// Release the node
			self.currentNode = nil;
			
			nodeFinished = NO;
			
			yDiff = 0.0f;
			xDiff = 0.0f;
			widthDiff = 0.0f;
			scaleValue	= 1.0f;
			
		}
		
		previousChar = text[charPosition];
		charPosition ++;
		
	}
	
	// Reposition everything in y-scale
	if (vertAlign_ == UITextAlignmentCenter) {
		float alignValue = yPosition / 2.0f + lineHeight;
		for (CCNode *node in [self children]) {
			[node setPosition:ccp(node.position.x, node.position.y - alignValue /*+ ((0.5f - anchorPoint_.y) * boxSize.height)*/)];
		}
	}
	
}

-(void) dealloc
{
	self.stringStore = nil;
	self.font = nil;
	self.currentNode = nil;
	
	[super dealloc];
}

@end
