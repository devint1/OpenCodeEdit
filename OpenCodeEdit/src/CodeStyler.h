//
//  CodeStyler.h
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/14/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Scintilla/ScintillaView.h>
#import "CodeStyleElement.h"

@interface CodeStyler : NSObject {
    NSMutableArray *styleElements;
	CodeStyleElement *editorStyle;
}

+(NSArray*)getThemeNames;
+(NSArray*)getSupportedLanguagesForTheme:(NSString*)theme;
+(NSDictionary*)getLanguageDescriptionsForTheme:(NSString*)theme;
-(id)initWithTheme:(NSString*)theme language:(NSString*)language;
-(id)initWithTheme:(NSString*)theme language:(NSString*)language includeCommon:(BOOL)includeCommon;
-(NSArray*)getStyles;
-(CodeStyleElement*)getEditorStyle;
-(void)stylizeScintillaView:(ScintillaView*)sv;

@end
