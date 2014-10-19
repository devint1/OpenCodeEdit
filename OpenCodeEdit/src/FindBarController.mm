//
//  FindBarController.m
//  OpenCodeEdit
//
//  Created by Devin Tuchsen on 10/18/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
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
