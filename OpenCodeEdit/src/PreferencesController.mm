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

@implementation PreferencesController

-(void)windowDidLoad {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(defaultsChanged:) name:NSUserDefaultsDidChangeNotification object:nil];
    NSArray *styleNames = [CodeStyler getStyleNames];
    [_stylePopUp addItemsWithTitles:styleNames];
    [_stylePopUp selectItemWithTitle:[[NSUserDefaults standardUserDefaults] stringForKey:@"style"]];
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

@end
