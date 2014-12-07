//
//  PreferencesController.h
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/15/14.
//  Copyright (c) 2014 Devin Tuchsen. All rights reserved.
//
//  This file is part of OpenCodeEdit.
//
//  OpenCodeEdit is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  OpenCodeEdit is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
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
