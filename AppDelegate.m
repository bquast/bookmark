#import "AppDelegate.h"
#import "BookTextView.h"
#import "MarkdownParser.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h> // For UTType

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // --- Main Menu Setup ---
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"MainMenu"];
    NSApp.mainMenu = mainMenu;

    // Application Menu (Bolded App Name)
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] initWithTitle:@"ApplicationMenuPlaceholder" action:nil keyEquivalent:@""];
    [mainMenu addItem:appMenuItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Application"];
    appMenuItem.submenu = appMenu;
    NSString *appName = [[NSProcessInfo processInfo] processName];
    NSString *quitTitle = [NSString stringWithFormat:@"Quit %@", appName];
    NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
    quitMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [appMenu addItem:quitMenuItem];

    // File Menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu addItem:fileMenuItem];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    fileMenuItem.submenu = fileMenu;
    NSMenuItem *openMenuItem = [[NSMenuItem alloc] initWithTitle:@"Open..." action:@selector(openDocument:) keyEquivalent:@"o"];
    openMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [fileMenu addItem:openMenuItem];

    // --- Window Setup ---
    NSRect contentRect = NSMakeRect(200, 200, 700, 600); // A decent size for reading
    NSWindowStyleMask styleMask = NSWindowStyleMaskTitled |
                                  NSWindowStyleMaskClosable |
                                  NSWindowStyleMaskMiniaturizable |
                                  NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:contentRect
                                              styleMask:styleMask
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.title = appName; // Set initial window title to app name
    [self.window center];

    // Window's main content view
    NSView *windowContentView = [[NSView alloc] initWithFrame:contentRect];
    self.window.contentView = windowContentView;
    
    // --- ScrollView and Custom TextView (BookTextView) Setup ---
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:windowContentView.bounds];
    scrollView.hasVerticalScroller = YES;   // Enable vertical scrolling
    scrollView.hasHorizontalScroller = NO;  // Disable horizontal scrolling for book feel
    scrollView.autohidesScrollers = YES;    // Show scrollers only when needed
    scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable; // ScrollView resizes with window
    scrollView.backgroundColor = [NSColor textBackgroundColor]; // Match typical text area background

    // Instantiate your custom BookTextView
    BookTextView *bookView = [[BookTextView alloc] initWithFrame:scrollView.bounds];
    bookView.editable = NO;     // Content should not be editable by the user
    bookView.selectable = YES;  // Allow users to select text
    
    // Set a default font. The MarkdownParser will use this as a base.
    NSFont *defaultTextViewFont = [NSFont systemFontOfSize:16.0];
    bookView.font = defaultTextViewFont; // Set on text view for initial state / if parser fails
    
    bookView.backgroundColor = [NSColor textBackgroundColor]; // Ensure consistent background
    bookView.textColor = [NSColor textColor];                 // Default text color

    // Add some padding inside the text view for better readability
    bookView.textContainerInset = NSMakeSize(20, 15); // Vertical padding, Horizontal padding

    // Configure text container for proper reflow and sizing
    [bookView setHorizontallyResizable:NO]; // Text view width is fixed by scroll view
    [bookView setVerticallyResizable:YES];  // Text view height grows with content

    NSTextContainer *textContainer = bookView.textContainer;
    // Text should reflow when the text view's width changes (due to window resize)
    textContainer.widthTracksTextView = YES;
    // Text container height should not track text view height; it should be as tall as the content.
    textContainer.heightTracksTextView = NO;
    // [textContainer setContainerSize:NSMakeSize(scrollView.contentSize.width, FLT_MAX)]; // Let it grow vertically

    // Set the BookTextView as the document view of the NSScrollView
    scrollView.documentView = bookView;
    // Add the NSScrollView to the window's content view
    [windowContentView addSubview:scrollView];

    // --- Initial Content ---
    // Display a welcome message, styled using the MarkdownParser
    NSString *welcomeMessage = [NSString stringWithFormat:@"# Welcome to %@!\n\nUse File > Open... to select a Markdown file.\n\nUse UP/DOWN or LEFT/RIGHT arrow keys for page turning.", appName];
    NSAttributedString *styledWelcome = [MarkdownParser attributedStringFromMarkdownString:welcomeMessage defaultFont:defaultTextViewFont];
    // Apply the styled welcome message to the text view's storage
    [[bookView textStorage] setAttributedString:styledWelcome];

    // --- Finalize Window and Activate App ---
    [self.window makeKeyAndOrderFront:nil]; // Show the window
    [NSApp activateIgnoringOtherApps:YES];  // Bring the app to the foreground
    [self.window makeFirstResponder:bookView]; // Ensure BookTextView receives key events for paging
}

// Helper method to find the BookTextView instance
- (BookTextView *)findBookTextView {
    NSView *mainContentView = self.window.contentView;
    // Check if the first subview is an NSScrollView
    if (mainContentView.subviews.count > 0 && [mainContentView.subviews.firstObject isKindOfClass:[NSScrollView class]]) {
        NSScrollView *scrollView = (NSScrollView *)mainContentView.subviews.firstObject;
        // Check if the scroll view's documentView is our BookTextView
        if ([scrollView.documentView isKindOfClass:[BookTextView class]]) {
            return (BookTextView *)scrollView.documentView;
        }
    }
    NSLog(@"Error: BookTextView not found in the view hierarchy.");
    return nil;
}

// Action method called when "File > Open..." is selected
- (void)openDocument:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;             // Allow selecting files
    panel.canChooseDirectories = NO;        // Do not allow selecting directories
    panel.allowsMultipleSelection = NO;     // Only allow one file to be selected

    // Configure allowed file types (Markdown files)
    if (@available(macOS 11.0, *)) { // Modern way using UTType
        UTType *markdownTypeDB = [UTType typeWithIdentifier:@"net.daringfireball.markdown"];
        UTType *markdownTypePublic = [UTType typeWithIdentifier:@"public.markdown"]; // Another common ID for Markdown
        NSMutableArray *contentTypes = [NSMutableArray array];
        if (markdownTypeDB) [contentTypes addObject:markdownTypeDB];
        if (markdownTypePublic && ![contentTypes containsObject:markdownTypePublic]) [contentTypes addObject:markdownTypePublic];
        
        if (contentTypes.count > 0) {
            panel.allowedContentTypes = contentTypes;
        } else {
            // Fallback if specific Markdown UTTypes are not resolved on the system
            NSLog(@"Warning: Specific Markdown UTTypes not found. Falling back to extension-based filtering.");
            panel.allowedFileTypes = @[@"md", @"markdown", @"txt"]; // Allow .txt as well
        }
    } else { // Fallback for older macOS versions
        panel.allowedFileTypes = @[@"md", @"markdown", @"txt"];
    }

    // Display the open panel as a sheet
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) { // User clicked "Open"
            NSURL *selectedFileURL = panel.URLs.firstObject;
            if (selectedFileURL) {
                BookTextView *textViewToUpdate = [self findBookTextView];
                if (!textViewToUpdate) {
                    NSLog(@"Cannot open document: BookTextView instance not found.");
                    // Optionally show an alert to the user here
                    return;
                }
                
                // Get the default font from the text view to pass to the parser
                NSFont *defaultTextViewFont = [NSFont systemFontOfSize:16.0];

                NSError *error = nil;
                // Read the raw string content from the selected file
                NSString *fileContent = [NSString stringWithContentsOfURL:selectedFileURL
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
                if (fileContent) {
                    // Parse the Markdown string into an NSAttributedString
                    NSAttributedString *styledContent = [MarkdownParser attributedStringFromMarkdownString:fileContent defaultFont:defaultTextViewFont];
                    
                    // Replace the entire content of the text view's textStorage
                    [[textViewToUpdate textStorage] setAttributedString:styledContent];
                    
                    self.window.title = selectedFileURL.lastPathComponent; // Update window title with filename
                    // Scroll to the beginning of the newly loaded document
                    [textViewToUpdate scrollRangeToVisible:NSMakeRange(0, 0)];
                    // Ensure BookTextView is ready to receive keyboard events for paging
                    [self.window makeFirstResponder:textViewToUpdate];
                } else {
                    // Handle error loading file content
                    NSString *errorMessage = [NSString stringWithFormat:@"Error loading file content: %@\nPath: %@", error.localizedDescription, selectedFileURL.path];
                    NSAttributedString *styledError = [[NSAttributedString alloc] initWithString:errorMessage attributes:@{NSFontAttributeName: defaultTextViewFont, NSForegroundColorAttributeName: [NSColor redColor]}];
                    [[textViewToUpdate textStorage] setAttributedString:styledError];
                    self.window.title = @"Error";
                    
                    // Show an alert panel to the user
                    NSAlert *alert = [[NSAlert alloc] init];
                    alert.messageText = @"Error Opening File";
                    alert.informativeText = errorMessage; // Show detailed error
                    [alert addButtonWithTitle:@"OK"];
                    alert.alertStyle = NSAlertStyleWarning;
                    [alert beginSheetModalForWindow:self.window completionHandler:nil];
                }
            }
        }
    }];
}

// Called when the application is about to terminate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog(@"Application will terminate: %@", [[NSProcessInfo processInfo] processName]);
}

// Determine if the application should terminate when the last window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES; // Standard behavior for document-based apps
}

@end

