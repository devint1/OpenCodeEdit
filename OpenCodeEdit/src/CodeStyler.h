//
//  CodeStyler.h
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/14/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CodeStyleElement.h"

@interface CodeStyler : NSObject {
    NSMutableArray *styleElements;
	CodeStyleElement *editorStyle;
}

+(NSArray*)getStyleNames;
-(id)initWithTheme:(NSString*)theme language:(NSString*)language;
-(void)stylizeScintillaView:(ScintillaView*)sv;

@end
