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
}

@property IBOutlet NSPopUpButtonCell *stylePopUp;
@property IBOutlet NSPopUpButtonCell *styleSetPopUp;
@property IBOutlet NSTableView *styleTable;

@end
