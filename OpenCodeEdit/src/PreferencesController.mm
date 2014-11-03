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

#pragma mark Loading

-(void)windowDidLoad {
	languageNames = [[NSMutableArray alloc] init];
	tableItemSelected = NO;
	[self registerObservers];
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

#pragma mark IBAction methods

-(IBAction)themeChanged:(id)sender {
	[self populateStyleSets];
	
	// TODO: Remove this later
	[_styleSetPopUp selectItemAtIndex:1];
	
	tableItemSelected = NO;
	[self populateStyles];
}

-(IBAction)styleSetChanged:(id)sender {
	tableItemSelected = NO;
	[self populateStyles];
}

-(IBAction)resetStyle:(id)sender {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Reset style to defaults?"];
	[alert setInformativeText:@"This action cannot be undone."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse response) {
		if(response == 1000) {
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			NSMutableDictionary *overrides = [[NSMutableDictionary alloc] init];
			if(!overrides) {
				NSLog(@"ERROR: Could not load style overrides, default may not have been registered");
				return;
			}
			CodeStyleElement *selectedElem = [[styler getStyles] objectAtIndex:[_styleTable selectedRow]];
			NSString *styleId = [[NSNumber numberWithInt:selectedElem.styleId] stringValue];
			[overrides addEntriesFromDictionary:[userDefaults dictionaryForKey:UD_STYLE_OVERRIDES]];
			NSMutableDictionary *languageStyles = [self mutableLanguageDictionaryForOverrideDictionary:overrides];
			[languageStyles removeObjectForKey:styleId];
			[userDefaults setObject:overrides forKey:UD_STYLE_OVERRIDES];
			NSInteger selectedRow = [_styleTable selectedRow];
			[self populateStyles];
			NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:selectedRow];
			[_styleTable selectRowIndexes:indexSet byExtendingSelection:NO];
		}
	}];
}

-(IBAction)resetTheme:(id)sender {
	NSAlert *alert = [[NSAlert alloc] init];
	[alert addButtonWithTitle:@"OK"];
	[alert addButtonWithTitle:@"Cancel"];
	[alert setMessageText:@"Reset theme to defaults?"];
	[alert setInformativeText:@"This will reset all styles for the selected theme to their default values. This cannot be undone."];
	[alert setAlertStyle:NSWarningAlertStyle];
	[alert beginSheetModalForWindow:[self window] completionHandler:^(NSModalResponse response) {
		if(response == 1000) {
			NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
			NSMutableDictionary *overrides = [[NSMutableDictionary alloc] init];
			if(!overrides) {
				NSLog(@"ERROR: Could not load style overrides, default may not have been registered");
				return;
			}
			[overrides addEntriesFromDictionary:[userDefaults dictionaryForKey:UD_STYLE_OVERRIDES]];
			[overrides removeObjectForKey:[_themePopUp titleOfSelectedItem]];
			[userDefaults setObject:overrides forKey:UD_STYLE_OVERRIDES];
			NSInteger selectedRow = [_styleTable selectedRow];
			[self populateStyles];
			NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:selectedRow];
			[_styleTable selectRowIndexes:indexSet byExtendingSelection:NO];
		}
	}];
}

#pragma mark Observer methods

-(void)registerObservers {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
	[self addObserver:self forKeyPath:@"foregroundColor" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"fontName" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"fontSize" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"bold" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"italic" options:NSKeyValueObservingOptionNew context:nil];
	[self addObserver:self forKeyPath:@"underline" options:NSKeyValueObservingOptionNew context:nil];
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

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if(!tableItemSelected)
		return;
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSMutableDictionary *overrides = [[NSMutableDictionary alloc] init];
	if(!overrides) {
		NSLog(@"ERROR: Could not load style overrides, default may not have been registered");
		return;
	}
	[overrides addEntriesFromDictionary:[userDefaults dictionaryForKey:UD_STYLE_OVERRIDES]];
	NSMutableDictionary *styleOverrides = [self mutableStyleDictionaryForOverrideDictionary:overrides];
	if ([keyPath isEqualToString:@"foregroundColor"]) {
		NSData *colorData = [NSArchiver archivedDataWithRootObject:_foregroundColor];
		[styleOverrides setObject:colorData forKey:keyPath];
	} else if ([keyPath isEqualToString:@"backgroundColor"]) {
		NSData *colorData = [NSArchiver archivedDataWithRootObject:_backgroundColor];
		[styleOverrides setObject:colorData forKey:keyPath];
	} else if ([keyPath isEqualToString:@"fontName"]) {
		[styleOverrides setObject:_fontName forKey:keyPath];
	} else if ([keyPath isEqualToString:@"fontSize"]) {
		[styleOverrides setObject:[NSNumber numberWithInteger:_fontSize] forKey:keyPath];
	} else if ([keyPath isEqualToString:@"bold"]) {
		[styleOverrides setObject:[NSNumber numberWithBool:_bold] forKey:keyPath];
	} else if ([keyPath isEqualToString:@"italic"]) {
		[styleOverrides setObject:[NSNumber numberWithBool:_italic] forKey:keyPath];
	} else if ([keyPath isEqualToString:@"underline"]) {
		[styleOverrides setObject:[NSNumber numberWithBool:_underline] forKey:keyPath];
	} else {
		NSLog(@"WARNING: Unknown key path: %@",keyPath);
	}
	[userDefaults setObject:overrides forKey:UD_STYLE_OVERRIDES];
	NSInteger selectedRow = [_styleTable selectedRow];
	[self populateStyles];
	NSIndexSet *indexSet = [[NSIndexSet alloc] initWithIndex:selectedRow];
	[_styleTable selectRowIndexes:indexSet byExtendingSelection:NO];
}

#pragma mark Menu population

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
	NSInteger styleSetIndex = [_styleSetPopUp indexOfSelectedItem];
	styler = [[CodeStyler alloc] initWithTheme:[[_themePopUp selectedItem] title] language:[languageNames objectAtIndex:styleSetIndex] includeCommon:NO];
	[_styleTable setBackgroundColor:[styler getEditorStyle].backgroundColor];
	[_styleTable reloadData];
}

#pragma mark Style table view methods

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
	
	tableItemSelected = NO;
	
	[self setForegroundColor:foregroundColor];
	[self setBackgroundColor:backgroundColor];
	[self setFontSize:fontSize];
	[self setBold:bold];
	[self setItalic:italic];
	[self setUnderline:underline];
	[self setFontName:fontName];

	tableItemSelected = YES;
}

#pragma mark Misc

-(NSMutableDictionary*)mutableStyleDictionaryForOverrideDictionary:(NSMutableDictionary*)overrides {
	CodeStyleElement *selectedElem = [[styler getStyles] objectAtIndex:[_styleTable selectedRow]];
	NSString *theme = [[_themePopUp selectedItem] title];
	NSString *language = [languageNames objectAtIndex:[_styleSetPopUp indexOfSelectedItem]];
	NSString *styleId = [[NSNumber numberWithInt:selectedElem.styleId] stringValue];
	
	// Theme overrides
	NSMutableDictionary *themeOverrides = [[NSMutableDictionary alloc] init];
	[themeOverrides addEntriesFromDictionary:[overrides objectForKey:theme]];
	[overrides setObject:themeOverrides forKey:theme];
	
	// Language overrides
	NSMutableDictionary *languageOverrides = [[NSMutableDictionary alloc] init];
	[languageOverrides addEntriesFromDictionary:[themeOverrides objectForKey:language]];
	[themeOverrides setObject:languageOverrides forKey:language];
	
	// Style overrides
	NSMutableDictionary *styleOverrides = [[NSMutableDictionary alloc] init];
	[styleOverrides addEntriesFromDictionary:[languageOverrides objectForKey:styleId]];
	[languageOverrides setObject:styleOverrides forKey:styleId];
	
	return styleOverrides;
}

-(NSMutableDictionary*)mutableLanguageDictionaryForOverrideDictionary:(NSMutableDictionary*)overrides {
	NSString *theme = [[_themePopUp selectedItem] title];
	NSString *language = [languageNames objectAtIndex:[_styleSetPopUp indexOfSelectedItem]];
	
	// Theme overrides
	NSMutableDictionary *themeOverrides = [[NSMutableDictionary alloc] init];
	[themeOverrides addEntriesFromDictionary:[overrides objectForKey:theme]];
	[overrides setObject:themeOverrides forKey:theme];
	
	// Language overrides
	NSMutableDictionary *languageOverrides = [[NSMutableDictionary alloc] init];
	[languageOverrides addEntriesFromDictionary:[themeOverrides objectForKey:language]];
	[themeOverrides setObject:languageOverrides forKey:language];
	
	return languageOverrides;
}

@end
