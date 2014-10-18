#import <Scintilla/InfoBar.h>
#import "AppDelegate.h"
#import "CodeDocument.h"
#import "CodeStyler.h"

@implementation CodeDocument

@synthesize loaded;

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
    [sm setLanguage:2];
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
    NSString *style = [[NSUserDefaults standardUserDefaults] objectForKey:@"style"];
	// TODO: Get rid of hardcoded "cpp"
	CodeStyler *styler = [[CodeStyler alloc] initWithTheme:style language:@"cpp"];
	[styler stylizeScintillaView:_sv];
}

#pragma mark Button actions
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
	self = [super init];
	[self setUpView];
	return self;
}

-(id)initWithBaseTabContents:(CTTabContents*)baseContents {
	if (!(self = [super initWithBaseTabContents:baseContents])) return nil;
	[self setUpView];
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	[self setUpView];
	self = [super initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	return self;
}

#pragma mark File I/O
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
	NSString *docName = [self title];
	[_sv setStatusText:[NSString stringWithFormat:@"Loading document: %@",docName,nil]];
	void *bytes = malloc([data length]);
	[data getBytes:bytes];
	[_sv message:SCI_APPENDTEXT wParam:[data length] lParam:(sptr_t)bytes];
	free(bytes);
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
	long docLength = [_sv getGeneralProperty:SCI_GETLENGTH] + 1;
	char text[docLength];
	[_sv message:SCI_GETTEXT wParam:docLength lParam:(sptr_t)text];
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
    if(eolButton != nil) {
        BOOL showEOL = [_sv message:SCI_GETVIEWEOL];
        [eolButton setState:showEOL];
    }
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

#pragma mark Misc
-(void)setLanguageMenu:(NSString*)title {
	AppDelegate *appDelegate = (AppDelegate*)[[NSApplication sharedApplication] delegate];
	NSMenu *menu = [appDelegate languageMenu];
	NSMenuItem *menuItem = [menu itemWithTitle:title];
	for(int i = 0; i < [[menu itemArray] count]; ++i) {
		[[menu itemAtIndex:i] setState:NSOffState];
	}
	[menuItem setState:NSOnState];
}

-(IBAction)changeLanguage:(id)sender {
    [sm setLanguage:[sender tag]];
	[self setLanguageMenu:[sender title]];
}

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
