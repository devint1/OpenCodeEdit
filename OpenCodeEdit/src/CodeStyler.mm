//
//  CodeStyler.m
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/14/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Scintilla/ScintillaView.h>
#import "CodeStyler.h"

#pragma mark Debug flags

#define DEBUG_LANGUAGE YES

#pragma mark Key constants

#define COMMON @"common"
#define EDITOR @"editor"
#define FONT_NAME @"fontName"
#define STYLE_ID @"styleId"
#define FONT_SIZE @"fontSize"
#define BOLD @"bold"
#define ITALIC @"italic"
#define UNDERLINE @"underline"
#define FOREGROUND_COLOR @"foregroundColor"
#define BACKGROUND_COLOR @"backgroundColor"
#define EOL_FILLED @"eolFilled"
#define CARET_FOREGROUND_COLOR @"caretForegroundColor"
#define RED @"red"
#define GREEN @"green"
#define BLUE @"blue"

@implementation CodeStyler

static NSDictionary *properties;

+(void)initialize {
    if(!properties) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *filePath = [mainBundle pathForResource:@"themes" ofType:@"plist"];
        properties = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
}

+(NSArray*)getStyleNames {
    return [properties allKeys];
}

-(NSColor*)colorForDictionary:(NSDictionary*)dictionary {
	if(dictionary == nil) return nil;
	CGFloat r = [[dictionary objectForKey:RED] floatValue];
	CGFloat g = [[dictionary objectForKey:GREEN] floatValue];
	CGFloat b = [[dictionary objectForKey:BLUE] floatValue];
	NSColor *color = [NSColor colorWithRed:r green:g blue:b alpha:1];
	return color;
}

-(CodeStyleElement*)elementForDictionary:(NSDictionary*)dictionary {
	CodeStyleElement *elem = [[CodeStyleElement alloc] init];
	elem.styleId = [[dictionary objectForKey:STYLE_ID] intValue];
	elem.fontName = [dictionary objectForKey:FONT_NAME];
	elem.fontSize = [[dictionary objectForKey:FONT_SIZE] intValue];
	elem.bold = [[dictionary objectForKey:BOLD] boolValue];
	elem.italic = [[dictionary objectForKey:ITALIC] boolValue];
	elem.underline = [[dictionary objectForKey:UNDERLINE] boolValue];
	elem.foregroundColor = [self colorForDictionary:[dictionary objectForKey:FOREGROUND_COLOR]];
	elem.backgroundColor = [self colorForDictionary:[dictionary objectForKey:BACKGROUND_COLOR]];
	elem.eolFilled = [[dictionary objectForKey:EOL_FILLED] boolValue];
	elem.caretForegroundColor = [self colorForDictionary:[dictionary objectForKey:CARET_FOREGROUND_COLOR]];
	return elem;
}

-(id)initWithTheme:(NSString*)theme language:(NSString*)language {
    if(DEBUG_LANGUAGE)
        NSLog(@"Styling for language: %@",language);
    styleElements = [[NSMutableArray alloc] init];
    NSDictionary *themeStyles = [properties objectForKey:theme];
    NSDictionary *editorStyleDict = [themeStyles objectForKey:EDITOR];
    editorStyle = [self elementForDictionary:editorStyleDict];
	NSArray *commonStyles = [themeStyles objectForKey:COMMON];
	int i;
	for(i = 0; i < [commonStyles count]; ++i) {
		NSDictionary *style = [commonStyles objectAtIndex:i];
		CodeStyleElement *elem = [self elementForDictionary:style];
		[styleElements addObject:elem];
	}
	NSArray *languageStyles = [themeStyles objectForKey:language];
	for(i = 0; i < [languageStyles count]; ++i) {
		NSDictionary *style = [languageStyles objectAtIndex:i];
		CodeStyleElement *elem = [self elementForDictionary:style];
		[styleElements addObject:elem];
	}
	return self;
}

-(void)stylizeScintillaView:(ScintillaView*)sv {
	[sv setFontName:editorStyle.fontName size:editorStyle.fontSize bold:editorStyle.bold italic:editorStyle.italic];
	if(editorStyle.foregroundColor != nil) {
		[sv setColorProperty:SCI_STYLESETFORE parameter:STYLE_DEFAULT value:editorStyle.foregroundColor];
	}
	if(editorStyle.backgroundColor != nil) {
		[sv setColorProperty:SCI_STYLESETBACK parameter:STYLE_DEFAULT value:editorStyle.backgroundColor];
	}
	if(editorStyle.caretForegroundColor != nil) {
		[sv setColorProperty:SCI_SETCARETFORE value:editorStyle.caretForegroundColor];
	}
    for(int i = 0; i < [styleElements count]; ++i) {
        NSObject *arrayObj = [styleElements objectAtIndex:i];
        if (![arrayObj isMemberOfClass:[CodeStyleElement class]]) {
            NSLog(@"Warning loading styles: expected object of class CodeStyleElement but got %@",[arrayObj className]);
            continue;
        }
        CodeStyleElement *styleElement = (CodeStyleElement*)arrayObj;
        int styleId = [styleElement styleId];
        if ([styleElement fontName] != nil && [[styleElement fontName] length] > 0) {
            [sv setStringProperty:SCI_STYLESETFONT parameter:styleId value:[styleElement fontName]];
        }
        if ([styleElement fontSize] > 0) {
            [sv setGeneralProperty:SCI_STYLESETSIZE parameter:styleId value:[styleElement fontSize]];
        }
        [sv setGeneralProperty:SCI_STYLESETBOLD parameter:styleId value:[styleElement bold]];
        [sv setGeneralProperty:SCI_STYLESETITALIC parameter:styleId value:[styleElement italic]];
        [sv setGeneralProperty:SCI_STYLESETUNDERLINE parameter:styleId value:[styleElement underline]];
        if ([styleElement foregroundColor] != nil) {
            [sv setColorProperty:SCI_STYLESETFORE parameter:styleId value:[styleElement foregroundColor]];
		} else if (editorStyle.foregroundColor != nil) {
			[sv setColorProperty:SCI_STYLESETFORE parameter:styleId value:editorStyle.foregroundColor];
		}
        if ([styleElement backgroundColor] != nil) {
            [sv setColorProperty:SCI_STYLESETBACK parameter:styleId value:[styleElement backgroundColor]];
		} else if (editorStyle.backgroundColor != nil) {
			[sv setColorProperty:SCI_STYLESETBACK parameter:styleId value:editorStyle.backgroundColor];
		}
        [sv setGeneralProperty:SCI_STYLESETEOLFILLED parameter:styleId value:[styleElement eolFilled]];
    }
}

@end
