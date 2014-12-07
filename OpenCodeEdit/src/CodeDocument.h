//
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

#import <ChromiumTabs/ChromiumTabs.h>
#import <Scintilla/ScintillaView.h>
#import "FindBarController.h"
#import "ScintillaManager.h"

@class ScintillaManager;

@interface CodeDocument : CTTabContents {
    NSTextView* tv;
	BOOL savePromptOpen;
	int currentLine;
    NSButton *eolButton;
    ScintillaManager *sm;
	FindBarController *findBar;
}

@property (readwrite) BOOL loaded;
@property (readwrite) NSInteger language;
@property (readonly) ScintillaView *sv;

-(void)removeFindBar;
-(void)applyStyle;
-(void)findNext;
-(void)findPrevious;

@end

