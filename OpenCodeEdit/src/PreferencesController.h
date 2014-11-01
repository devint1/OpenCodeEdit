//
//  PreferencesController.h
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/15/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CodeStyler.h"

@interface PreferencesController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
	NSMutableArray *languageNames;
	CodeStyler *styler;
	BOOL tableItemSelected;
}

@property IBOutlet NSPopUpButtonCell *themePopUp;
@property IBOutlet NSPopUpButtonCell *styleSetPopUp;
@property IBOutlet NSPopUpButtonCell *fontPopUp;
@property NSColor *foregroundColor;
@property NSColor *backgroundColor;
@property NSInteger fontSize;
@property BOOL bold;
@property BOOL italic;
@property BOOL underline;
@property NSString *fontName;
@property IBOutlet NSTableView *styleTable;

@end
