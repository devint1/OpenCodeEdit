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

#import <Scintilla/InfoBar.h>
#import "AppDelegate.h"
#import "CodeDocument.h"
#import "CodeStyler.h"
#import "FindBarController.h"
#import "FindBarView.h"
#import "UserDefaultsKeys.h"

@implementation CodeDocument

@synthesize loaded;
@synthesize language = _language;

// Sets up the ScintillaView (and a few other things)
-(void)setUpView {
	// Some basic initialization stuff
	self.loaded = NO;
	savePromptOpen = NO;
	_sv = [[ScintillaView alloc] initWithFrame:NSZeroRect];
    sm = [[ScintillaManager alloc] initWithCodeDocument:self];
	[_sv setDelegate:sm];
	[_sv setAutoresizingMask:NSViewMaxYMargin|
	 NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|
	 NSViewHeightSizable|
	 NSViewMinYMargin];
    [sm setLanguageForUTI:[self fileType]];
    
	// Create a NSScrollView to which we add the NSTextView
	NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSZeroRect];
	[scrollView setDocumentView:_sv];
	
	// Set the NSScrollView as our view
	self.view = scrollView;
	
	// Line numbers in left margin
	[_sv setGeneralProperty:SCI_SETMARGINWIDTHN parameter:0 value:30];
	[_sv setGeneralProperty:SCI_SETMARGINTYPEN parameter:0 value:SC_MARGIN_NUMBER];
	
    // Indentation guides
    [_sv setGeneralProperty:SCI_SETTABINDENTS value:YES];
    [_sv setGeneralProperty:SCI_SETINDENTATIONGUIDES value:SC_IV_LOOKBOTH];
    
    // Folding margins
    [_sv setGeneralProperty:SCI_SETMARGINTYPEN parameter:1 value:SC_MARGIN_SYMBOL];
    [_sv setGeneralProperty:SCI_SETMARGINMASKN parameter:1 value:SC_MASK_FOLDERS];
    [_sv setGeneralProperty:SCI_SETMARGINSENSITIVEN parameter:1 value:YES];
    
    // Folding marker symbols
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDER value:SC_MARK_ARROW];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPEN value:SC_MARK_ARROWDOWN];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEREND value:SC_MARK_EMPTY];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERMIDTAIL value:SC_MARK_TCORNERCURVE];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDEROPENMID value:SC_MARK_EMPTY];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERSUB value:SC_MARK_VLINE];
    [_sv setGeneralProperty:SCI_MARKERDEFINE parameter:SC_MARKNUM_FOLDERTAIL value:SC_MARK_LCORNERCURVE];
    
    // Folding marker colors
    [_sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDER value:[NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]];
    [_sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDEROPEN value:[NSColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1]];
    [_sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERMIDTAIL value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [_sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERSUB value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
    [_sv setColorProperty:SCI_MARKERSETBACK parameter:SC_MARKNUM_FOLDERTAIL value:[NSColor colorWithRed:0 green:0 blue:0 alpha:1]];
	
	InfoBar *infoBar = [[InfoBar alloc] initWithFrame:NSZeroRect];
	[infoBar setDisplay:IBShowAll];
	[_sv setInfoBar:infoBar top:NO];
}

-(void)applyStyle {
    NSString *style = [[NSUserDefaults standardUserDefaults] objectForKey:UD_THEME];
    // 20 characters should be more than enough for any lexer module name
    char lexerLanguageBuf[20];
    [_sv message:SCI_GETLEXERLANGUAGE wParam:(uptr_t)nil lParam:(sptr_t)lexerLanguageBuf];
    NSString *lexerLanguage = [NSString stringWithCString:lexerLanguageBuf encoding:NSUTF8StringEncoding];
	CodeStyler *styler = [[CodeStyler alloc] initWithTheme:style language:lexerLanguage];
	[styler stylizeScintillaView:_sv];
}

#pragma mark Toolbar button actions
-(IBAction)increaseIndent:(id)sender {
    [_sv message:SCI_TAB];
}

-(IBAction)decreaseIndent:(id)sender {
    [_sv message:SCI_BACKTAB];
}

-(IBAction)toggleEOL:(id)sender {
    BOOL showEOL = [_sv message:SCI_GETVIEWEOL];
    [_sv message:SCI_SETVIEWEOL wParam:!showEOL];
    if(eolButton == nil) {
        eolButton = sender;
    }
}

#pragma mark Initializers
-(id)init {
    if(!_sv) {
        [self setFileType:@"public.text"];
        [self setUpView];
    }
	self = [super init];
	return self;
}

-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
	[self setUpView];
	if (!(self = [super initWithBaseTabContents:baseContents])) return nil;
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *oldType;
	
	// Makefiles are a special case
	if([[[absoluteURL lastPathComponent] lowercaseString] isEqualToString:@"makefile"]) {
		oldType = [NSString stringWithString:typeName];
		typeName = @"dyn.age80442";
	}
	
	[self setFileType:typeName];
	[self setUpView];
	
	// If typeName changed change it back
	if(oldType) {
		typeName = [NSString stringWithString:oldType];
	}
	
	self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	return self;
}

#pragma mark File I/O
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *docName = [self title];
	[_sv setStatusText:[NSString stringWithFormat:@"Loading document: %@",docName,nil]];
	
	// Do raw data read
	// TODO: Need to detect and set Scintilla code page
	[_sv message:SCI_APPENDTEXT wParam:[data length] lParam:(sptr_t)[data bytes]];
	[_sv message:SCI_EMPTYUNDOBUFFER];
	[_sv message:SCI_SETSAVEPOINT];
	
	[_sv setStatusText:[NSString stringWithFormat:@"Loaded document: %@",docName,nil]];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[NSThread sleepForTimeInterval:3];
		[_sv setStatusText:@"Ready"];
	});
	return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
	NSString *docName = [self title];
	[_sv setStatusText:[NSString stringWithFormat:@"Saving document: %@",docName,nil]];
	char *text = (char*)[_sv message:SCI_GETCHARACTERPOINTER];
	
	// TODO: Encoding conversion done here
	NSString *strText = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
	
	NSData *data = [strText dataUsingEncoding:NSUTF8StringEncoding];
	[_sv setStatusText:[NSString stringWithFormat:@"Saved document: %@",docName,nil]];
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		[NSThread sleepForTimeInterval:3];
		[_sv setStatusText:@"Ready"];
	});
	return data;
}

#pragma mark Tab management
-(void)tabDidBecomeActive {
	[self becomeFirstResponder];
	[self addWindowController:browser_.windowController];
    
    // Set menu/toolbar options
    if(eolButton != nil) {
        BOOL showEOL = [_sv message:SCI_GETVIEWEOL];
        [eolButton setState:showEOL];
    }
    [self setLanguageMenu:self.language];
}

-(void)tabWillResignActive {
	[self removeWindowController:browser_.windowController];
    if(eolButton != nil) {
        [eolButton setState:NSOffState];
    }
}

#pragma mark Document closing
-(void)close {
	[[self delegate] removeDocument:self];
	if (savePromptOpen) {
		[[self browser] closeTab];
	}
}

- (void)document:(NSDocument *)doc shouldClose:(BOOL)shouldClose  contextInfo:(void  *)contextInfo {
	BOOL *close = (BOOL*)contextInfo;
	if(shouldClose) {
		*close = YES;
		[self close];
	} else {
		savePromptOpen = NO;
	}
}

-(BOOL)closingOfTabDidStart:(CTTabStripModel *)model {
	BOOL shouldClose = NO;
	SEL selector = @selector(document:shouldClose:contextInfo:);
	if(!savePromptOpen) {
		[self canCloseDocumentWithDelegate:self shouldCloseSelector:selector contextInfo:(void*)&shouldClose];
		savePromptOpen = YES;
	} else {
		shouldClose = YES;
	}
	return shouldClose;
}

#pragma mark Finding
-(void)findNext {
	if(![_sv message:SCI_GETSELECTIONEMPTY]) {
		[_sv message:SCI_GOTOPOS wParam:[_sv message:SCI_GETSELECTIONEND]];
	}
	[_sv message:SCI_SEARCHANCHOR];
	long wordStart = [_sv message:SCI_SEARCHNEXT wParam:0 lParam:(sptr_t)[[[findBar findField] stringValue] cStringUsingEncoding:NSUTF8StringEncoding]];
	long wordEnd = [_sv message:SCI_WORDENDPOSITION wParam:wordStart lParam:NO];
	if(wordStart > -1) {
		[_sv message:SCI_SCROLLRANGE wParam:wordEnd lParam:wordStart];
		[_sv message:SCI_FINDINDICATORFLASH wParam:wordStart lParam:wordEnd];
	}
}

-(void)findPrevious {
	[_sv message:SCI_SEARCHANCHOR];
	long wordStart = [_sv message:SCI_SEARCHPREV wParam:0 lParam:(sptr_t)[[[findBar findField] stringValue] cStringUsingEncoding:NSUTF8StringEncoding]];
	long wordEnd = [_sv message:SCI_WORDENDPOSITION wParam:wordStart lParam:NO];
	if(wordStart > -1) {
		[_sv message:SCI_SCROLLRANGE wParam:wordEnd lParam:wordStart];
		[_sv message:SCI_FINDINDICATORFLASH wParam:wordStart lParam:wordEnd];
	}
}

-(IBAction)performFindPanelAction:(id)sender {
	if([sender isKindOfClass:[NSSegmentedControl class]]) {
		if([sender selectedSegment])
			[self findNext];
		else
			[self findPrevious];
		return;
	}
	switch([sender tag]) {
		case 1: {
			if(!findBar) {
				findBar = [[FindBarController alloc] initWithNibName:@"FindBar" bundle:[NSBundle mainBundle]];
			}
			FindBarView *findBarView = (FindBarView*)[findBar view];
			CGFloat windowHeight = [[browser_ window] frame].size.height;
			CGFloat windowWidth = [[browser_ window] frame].size.width;
			[findBarView setFrame:CGRectMake(0, windowHeight - 95, windowWidth, 25)];
			[findBarView setWantsLayer:YES];
			NSScrollView *scrollView = (NSScrollView*)[self view];
			[scrollView removeConstraints:[scrollView constraints]];
			[_sv setAutoresizingMask:NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|NSViewHeightSizable];
			[_sv setFrame:CGRectMake(0, 0, windowWidth, windowHeight - 95)];
			[[[browser_ window] contentView] addSubview:findBarView];
			[[findBar findField] becomeFirstResponder];
			break;
		}
		case 2:
			[self findNext];
			break;
		case 3:
			[self findPrevious];
			break;
	}
}

-(void)removeFindBar {
	CGFloat windowHeight = [[browser_ window] frame].size.height;
	CGFloat windowWidth = [[browser_ window] frame].size.width;
	[[findBar view] removeFromSuperview];
	[_sv setAutoresizingMask:NSViewMaxYMargin|
	 NSViewMinXMargin|NSViewWidthSizable|NSViewMaxXMargin|
	 NSViewHeightSizable|
	 NSViewMinYMargin];
	[_sv setFrame:CGRectMake(0, 0, windowWidth, windowHeight - 70)];
}

#pragma mark Language switching
-(void)setLanguageMenu:(NSInteger)tag {
	AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
	NSMenu *menu = [appDelegate languageMenu];
	NSMenuItem *menuItem = [menu itemWithTag:tag];
	for(int i = 0; i < [[menu itemArray] count]; ++i) {
		[[menu itemAtIndex:i] setState:NSOffState];
	}
	[menuItem setState:NSOnState];
}

-(IBAction)changeLanguage:(id)sender {
	[sm setLanguage:[sender tag]];
}

-(NSInteger)language {
    return _language;
}

-(void)setLanguage:(NSInteger)language {
    _language = language;
    [self setLanguageMenu:language];
}

#pragma mark Misc
-(BOOL)loaded {
    return loaded;
}

-(void)setLoaded:(BOOL)isLoaded {
    loaded = isLoaded;
	[_sv setStatusText:@"Ready"];
}

+ (BOOL)canConcurrentlyReadDocumentsOfType:(NSString *)typeName {
	return YES;
}

-(void)setFileURL:(NSURL *)url {
	title_ = [url lastPathComponent];
	[browser_ updateTabStateForContent:self];
	[super setFileURL:url];
}

- (void)saveToURL:(NSURL *)url ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation completionHandler:(void (^)(NSError *errorOrNil))completionHandler {
	title_ = [url lastPathComponent];
	[browser_ updateTabStateForContent:self];
	[super saveToURL:url ofType:typeName forSaveOperation:saveOperation completionHandler:completionHandler];
}

-(void)viewFrameDidChange:(NSRect)newFrame {
	// We need to recalculate the frame of the NSTextView when the frame changes.
	// This happens when a tab is created and when it's moved between windows.
	[super viewFrameDidChange:newFrame];
	NSRect frame = NSZeroRect;
	frame.size = [(NSScrollView*)(view_) contentSize];
	[_sv setFrame:frame];
}

@end
