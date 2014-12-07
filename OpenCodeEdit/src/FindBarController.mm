//
//  FindBarController.m
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/18/14.
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

#import "AppDelegate.h"
#import "CodeDocument.h"
#import "FindBarController.h"

@implementation FindBarController

-(IBAction)searchForwardOrBackward:(id)sender {
	CodeDocument *document = [(AppDelegate*)[[NSApplication sharedApplication] delegate] currentDocument];
	if(![sender isKindOfClass:[NSSegmentedControl class]]) {
		[document findNext];
		return;
	}
	if([sender selectedSegment])
		[document findNext];
	else
		[document findPrevious];
	return;
}

-(IBAction)done:(id)sender {
	CodeDocument *document = [(AppDelegate*)[[NSApplication sharedApplication] delegate] currentDocument];
	[document removeFindBar];
}

@end
