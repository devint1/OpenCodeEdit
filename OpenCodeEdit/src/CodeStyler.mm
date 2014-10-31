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
#define DESCRIPTION @"description"
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
#define LANGUAGE_DESCRIPTIONS @"languageDescriptions"

@implementation CodeStyler

static NSDictionary *properties;

+(void)initialize {
    if(!properties) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *filePath = [mainBundle pathForResource:@"themes" ofType:@"plist"];
        properties = [NSDictionary dictionaryWithContentsOfFile:filePath];
    }
}

+(NSArray*)getThemeNames {
    return [properties allKeys];
}

+(NSArray*)getSupportedLanguagesForTheme:(NSString*)theme {
	return [[properties objectForKey:theme] allKeys];
}

+(NSDictionary*)getLanguageDescriptionsForTheme:(NSString*)theme {
	return [[properties objectForKey:theme] objectForKey:LANGUAGE_DESCRIPTIONS];
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
	elem.description = [dictionary objectForKey:DESCRIPTION];
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
	return [self initWithTheme:theme language:language includeCommon:YES];
}

-(id)initWithTheme:(NSString*)theme language:(NSString*)language includeCommon:(BOOL)includeCommon {
	if(DEBUG_LANGUAGE)
		NSLog(@"Styling for language: %@",language);
	styleElements = [[NSMutableArray alloc] init];
	NSDictionary *themeStyles = [properties objectForKey:theme];
	NSDictionary *editorStyleDict = [themeStyles objectForKey:EDITOR];
	editorStyle = [self elementForDictionary:editorStyleDict];
	int i;
	if(includeCommon) {
		NSArray *commonStyles = [themeStyles objectForKey:COMMON];
		for(i = 0; i < [commonStyles count]; ++i) {
			NSDictionary *style = [commonStyles objectAtIndex:i];
			CodeStyleElement *elem = [self elementForDictionary:style];
			[styleElements addObject:elem];
		}
	}
	NSArray *languageStyles = [themeStyles objectForKey:language];
	for(i = 0; i < [languageStyles count]; ++i) {
		NSDictionary *style = [languageStyles objectAtIndex:i];
		CodeStyleElement *elem = [self elementForDictionary:style];
		[styleElements addObject:elem];
	}
	[self setSubStyles:themeStyles language:language includeCommon:includeCommon];
	return self;
}

-(NSArray*)getStyles {
	return styleElements;
}

-(CodeStyleElement*)getEditorStyle {
	return editorStyle;
}

-(void)setSubStyles:(NSDictionary*)themeStyles language:(NSString*)language includeCommon:(BOOL)includeCommon {
    if([language isEqualToString:@"hypertext"]) {
        NSMutableArray *subStyles = [themeStyles objectForKey:@"cpp"];
		if(includeCommon)
			[subStyles addObjectsFromArray:[themeStyles objectForKey:COMMON]];
        for(int i = 0; i < [subStyles count]; ++i) {
            NSDictionary *style = [subStyles objectAtIndex:i];
            CodeStyleElement *elem = [self elementForDictionary:style];
            CodeStyleElement *subElem1;
            CodeStyleElement *subElem2;
            switch (elem.styleId) {
                case 0: {
                    elem.styleId = 46;
                    subElem1 = [self elementForDictionary:style];
                    subElem2 = [self elementForDictionary:style];
                    subElem1.styleId = 40;
                    subElem2.styleId = 41;
                    break;
                }
                case 1:
                    elem.styleId = 42;
                    break;
                case 2:
                    elem.styleId = 43;
                    break;
                case 3:
                    elem.styleId = 44;
                    break;
                case 4:
                    elem.styleId = 45;
                    break;
                case 6:
                    elem.styleId = 48;
                    break;
                case 7:
                    elem.styleId = 49;
                    break;
                case 10:
                    elem.styleId = 50;
                    break;
                case 16:
                    elem.styleId = 47;
                    break;
                default:
                    continue;
            }
            if(subElem1)
                [styleElements addObject:subElem1];
            if(subElem2)
                [styleElements addObject:subElem2];
            [styleElements addObject:elem];
        }
    }
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
