//
//  PreferencesController.m
//  CodeEdit
//
//  Created by Devin Tuchsen on 10/15/14.
//  Copyright (c) 2014 Devi Tuchsen. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"
#import "CodeDocument.h"
#import "CodeStyler.h"
#import "PreferencesController.h"
#import "UserDefaultsKeys.h"

@implementation PreferencesController

-(void)windowDidLoad {
	languageNames = [[NSMutableArray alloc] init];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	NSArray *styleNames = [CodeStyler getThemeNames];
	[_themePopUp addItemsWithTitles:styleNames];
	[_themePopUp selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:UD_THEME]];
	[self populateStyleSets];
	
	// TODO: Remove this later
	[_styleSetPopUp selectItemAtIndex:1];
	
	[self populateStyles];
	_styleTable.intercellSpacing = CGSizeMake(4, 5);
	[_styleTable reloadData];
	NSArray *fontNames = [[NSFontManager sharedFontManager] availableFontFamilies];
	for(int i = 0; i < [fontNames count]; ++i) {
		NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:[fontNames objectAtIndex:i] action:nil keyEquivalent:@""];
		NSDictionary *attributes = @{
									 NSFontAttributeName: [NSFont fontWithName:[menuItem title] size:13]
									 };
		NSAttributedString *attributedFontName = [[NSAttributedString alloc] initWithString:[menuItem title] attributes:attributes];
		[menuItem setAttributedTitle:attributedFontName];
		[[_fontPopUp menu] addItem:menuItem];
	}
}

-(IBAction)themeChanged:(id)sender {
	[self populateStyleSets];
	
	// TODO: Remove this later
	[_styleSetPopUp selectItemAtIndex:1];
	
	[self populateStyles];
}

-(IBAction)styleSetChanged:(id)sender {
	[self populateStyles];
}

- (void)defaultsChanged:(NSNotification *)notification {
	// Refresh styles
	AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
	NSArray *documents = [appDelegate documents];
	for (int i = 0; i < [documents count]; ++i) {
		CodeDocument *document = [documents objectAtIndex:i];
		[document applyStyle];
	}
}

-(void)populateStyleSets {
	[_styleSetPopUp removeAllItems];
	[languageNames removeAllObjects];
	NSString *theme = [[_themePopUp selectedItem] title];
	NSArray *supportedLanguages = [CodeStyler getSupportedLanguagesForTheme:theme];
	NSDictionary *languageDescriptions = [CodeStyler getLanguageDescriptionsForTheme:theme];
	for (int i = 0; i < [supportedLanguages count]; ++i) {
		NSString *language = [supportedLanguages objectAtIndex:i];
		NSString *languageDescription = [languageDescriptions objectForKey:language];
		NSString *menuTitle;
		if (languageDescription) {
			menuTitle = languageDescription;
		} else {
			menuTitle = language;
		}
		if([language isEqualToString:@"editor"]) {
			[_styleSetPopUp insertItemWithTitle:@"Editor Styles" atIndex:0];
			[languageNames insertObject:language atIndex:0];
		} else if([language isEqualToString:@"common"]) {
			[_styleSetPopUp insertItemWithTitle:@"Common Styles" atIndex:1];
			[languageNames insertObject:language atIndex:1];
		} else if(![language isEqualToString:@"languageDescriptions"]) {
			[_styleSetPopUp addItemWithTitle:menuTitle];
			[languageNames addObject:language];
		}
	}
}

-(void)populateStyles {
	NSInteger styleSetIndex = [_styleSetPopUp indexOfItem:[_styleSetPopUp selectedItem]];
	styler = [[CodeStyler alloc] initWithTheme:[[_themePopUp selectedItem] title] language:[languageNames objectAtIndex:styleSetIndex] includeCommon:NO];
	[_styleTable setBackgroundColor:[styler getEditorStyle].backgroundColor];
	[_styleTable reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
	return [[styler getStyles] count];
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
				  row:(NSInteger)row {
	NSTextField *cell = [[NSTextField alloc] init];
	NSMutableAttributedString *cellStr;
	
	CodeStyleElement *elem = [[styler getStyles] objectAtIndex:row];
	CodeStyleElement *editorStyle = [styler getEditorStyle];
	
	NSColor *foregroundColor = elem.foregroundColor ? elem.foregroundColor : editorStyle.foregroundColor;
	NSColor *backgroundColor = elem.backgroundColor ? elem.backgroundColor : editorStyle.backgroundColor;
	BOOL bold = elem.bold ? elem.bold : editorStyle.bold;
	BOOL italic = elem.italic ? elem.italic : editorStyle.italic;
	BOOL underline = elem.underline ? elem.underline : editorStyle.underline;
	NSString *fontName = elem.fontName ? elem.fontName : editorStyle.fontName;
	int fontSize = elem.fontSize ? elem.fontSize : editorStyle.fontSize;
	
	NSString *styleDescription = [elem description];
	if(styleDescription) {
		cellStr = [[NSMutableAttributedString alloc] initWithString:styleDescription];
	} else {
		cellStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d",[elem styleId]]];
	}
	
	NSFontTraitMask fontMask = 0;
	if(bold)
		fontMask |= NSBoldFontMask;
	if(italic)
		fontMask |= NSItalicFontMask;
	if(underline)
		[cellStr addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInt:NSUnderlineStyleSingle] range:NSMakeRange(0, cellStr.length)];
	
	[cell setAttributedStringValue:cellStr];
	[cell setDrawsBackground:YES];
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSFont *cellFont = [fontManager fontWithFamily:fontName
											traits:fontMask
											weight:0
											  size:fontSize];
	[cell setFont:cellFont];
	[cell setTextColor:foregroundColor];
	[cell setBackgroundColor:backgroundColor];
	[cell setBordered:NO];
	[cell setEditable:NO];
	return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	NSTableView *tableView = [notification object];
	CodeStyleElement *elem = [[styler getStyles] objectAtIndex:[tableView selectedRow]];
	CodeStyleElement *editorStyle = [styler getEditorStyle];
	
	NSColor *foregroundColor = elem.foregroundColor ? elem.foregroundColor : editorStyle.foregroundColor;
	NSColor *backgroundColor = elem.backgroundColor ? elem.backgroundColor : editorStyle.backgroundColor;
	BOOL bold = elem.bold ? elem.bold : editorStyle.bold;
	BOOL italic = elem.italic ? elem.italic : editorStyle.italic;
	BOOL underline = elem.underline ? elem.underline : editorStyle.underline;
	NSString *fontName = elem.fontName ? elem.fontName : editorStyle.fontName;
	int fontSize = elem.fontSize ? elem.fontSize : editorStyle.fontSize;
	
	//[self setValue:foregroundColor forKey:@"foregroundColor"];
	[self setForegroundColor:foregroundColor];
	[self setBackgroundColor:backgroundColor];
	[self setFontSize:fontSize];
	[self setBold:bold];
	[self setItalic:italic];
	[self setUnderline:underline];
	[self setFontName:fontName];
}

@end
