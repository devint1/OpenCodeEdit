#import "AppDelegate.h"
#import "CodeDocument.h"

@implementation AppDelegate

CTBrowser *browser;

-(void)applicationDidFinishLaunching:(NSNotification *)notification {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaults = [[NSDictionary alloc] init];
	NSString *defaultStyle = @"Default";
	[defaults setValue:defaultStyle forKey:@"style"];
	[userDefaults registerDefaults:defaults];
}

- (void)newBrowserWindow {
	if ([[self documents] count] < 1) {
		if(browser == nil) {
			browser = [CTBrowser browser];
		}
		browser.windowController = [[CTBrowserWindowController alloc] initWithBrowser:browser];
		[browser.windowController showWindow:self];
	}
}

- (id)makeDocumentWithContentsOfURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError {
	CodeDocument *document = [[CodeDocument alloc] initWithContentsOfURL:absoluteURL ofType:typeName error:outError];
	return document;
}

// NOTE: Currently this just sets the active tab; it will not re-load the document
- (void)reopenDocumentForURL:(NSURL *)urlOrNil withContentsOfURL:(NSURL *)contentsURL display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	CodeDocument *document = [self documentForURL:urlOrNil];
	int tabIndex = [browser indexOfTabContents:document];
	[browser selectTabAtIndex:tabIndex];
	[super reopenDocumentForURL:urlOrNil withContentsOfURL:contentsURL display:displayDocument completionHandler:completionHandler];
}

-(void)finishOpenDocument:(CodeDocument*)document documentAlreadyOpen:(BOOL)documentOpen display:(BOOL)displayDocument url:(NSURL *)url completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	[self newBrowserWindow];
	[document setDelegate:self];
	[self addDocument:document];
	[document addWindowController:browser.windowController];
	[browser addTabContents:document];
	completionHandler(document, documentOpen, nil);
}

- (void)openDocumentWithContentsOfURL:(NSURL *)url display:(BOOL)displayDocument completionHandler:(void (^)(NSDocument *document, BOOL documentWasAlreadyOpen, NSError *error))completionHandler {
	BOOL documentAlreadyOpen = YES;
	__block CodeDocument *document;
	if([self documentForURL:url] == nil) {
		documentAlreadyOpen = NO;
		if ([CodeDocument canConcurrentlyReadDocumentsOfType:@"C++ Source"]) {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
				document = [self makeDocumentWithContentsOfURL:url ofType:@"C++ Source" error:nil];
				dispatch_sync(dispatch_get_main_queue(), ^{
					[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:url completionHandler:completionHandler];
				});
			});
		} else {
			document = [self makeDocumentWithContentsOfURL:url ofType:@"C++ Source" error:nil];
			[self finishOpenDocument:document documentAlreadyOpen:documentAlreadyOpen display:displayDocument url:url completionHandler:completionHandler];
		}
	} else {
		[self reopenDocumentForURL:url withContentsOfURL:url display:displayDocument completionHandler:completionHandler];
	}
}

- (id)openUntitledDocumentAndDisplay:(BOOL)displayDocument error:(NSError **)outError {
	[self newBrowserWindow];
	CodeDocument *newTab = [[CodeDocument alloc] init];
	[newTab setLoaded:YES];
	[newTab setDelegate:self];
	[self addDocument:newTab];
	[newTab addWindowController:browser.windowController];
	[browser addTabContents:newTab];
	return newTab;
}

-(IBAction)showPreferences:(id)sender {
	preferencesWindowController = [[PreferencesController alloc] initWithWindowNibName:@"Preferences"];
	[preferencesWindowController showWindow:self];
}

@end
