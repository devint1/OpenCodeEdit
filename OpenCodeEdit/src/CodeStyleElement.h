//
//  CodeStyleElement.h
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/14/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface CodeStyleElement : NSObject

@property (readwrite) int styleId;
@property (readwrite) NSString *description;
@property (readwrite) NSString *fontName;
@property (readwrite) int fontSize;
@property (readwrite) BOOL bold;
@property (readwrite) BOOL italic;
@property (readwrite) BOOL underline;
@property (readwrite) NSColor *foregroundColor;
@property (readwrite) NSColor *backgroundColor;
@property (readwrite) BOOL eolFilled;

// These are only used in the editor style
@property (readwrite) NSColor *caretForegroundColor;

@end
