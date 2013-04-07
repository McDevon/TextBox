//
//  TextBox.h
//  TextBox
//
//  Created by Jussi Enroos on 28.3.2013.
//  Copyright 2013 Jussi Enroos. All rights reserved.
//

#import "cocos2d.h"


@interface TextBox : CCNode {
	
	NSString 	*stringStore;
	NSString 	*font;
	
	int			size;
	int			horzAlign;
	int			vertAlign;
	
	CGSize 		boxSize;
	
	ccColor3B	fontColor;
	
	CCNode		*currentNode;
}

+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize;
+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize dimensions:(CGSize) dimensions halignment:(int) halignment;
+ (TextBox*) textBoxWithString:(NSString*) text fontName:(NSString*) fontName fontSize:(int) fontSize dimensions:(CGSize) dimensions halignment:(int) halignment color:(ccColor3B) color;

- (NSString*) string;
- (void) setString:(NSString *)text;

- (void)refreshView;

@end
