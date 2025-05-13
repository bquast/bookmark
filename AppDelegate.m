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

    NSMenuItem *browseOnlineMenuItem = [[NSMenuItem alloc] initWithTitle:@"Browse Online Library..." action:@selector(showBookLibraryWindow:) keyEquivalent:@"b"];
    browseOnlineMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift; // Cmd+Shift+B
    [fileMenu addItem:browseOnlineMenuItem];
    [fileMenu addItem:[NSMenuItem separatorItem]]; // Optional: Add a separator

    // Load the book index
    [self loadBookIndexFromBundle];

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

- (void)loadBookIndexFromBundle {
    NSURL *jsonURL = [[NSBundle mainBundle] URLForResource:@"books_index" withExtension:@"json"];
    if (!jsonURL) {
        NSLog(@"Error: books_index.json not found in bundle.");
        self.allBooks = @[];
        self.displayedBooks = @[];
        // Optionally show an alert to the user
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Book Library Not Found";
        alert.informativeText = @"The local book index file (books_index.json) could not be loaded. Please ensure it's included in the app bundle.";
        [alert addButtonWithTitle:@"OK"];
        alert.alertStyle = NSAlertStyleCritical;
        [alert runModal];
        return;
    }

    NSError *error = nil;
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL options:0 error:&error];
    if (jsonData) {
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if ([jsonObject isKindOfClass:[NSArray class]]) {
            self.allBooks = (NSArray<NSDictionary *> *)jsonObject;
            self.displayedBooks = self.allBooks;
        } else {
            NSLog(@"Error parsing books_index.json: %@", error.localizedDescription);
            self.allBooks = @[];
            self.displayedBooks = @[];
        }
    } else {
        NSLog(@"Error loading data from books_index.json: %@", error.localizedDescription);
        self.allBooks = @[];
        self.displayedBooks = @[];
    }
}

- (NSURL *)applicationBooksDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
    if (!bundleID) {
        bundleID = @"com.example.bookmark"; // Fallback bundle ID
        NSLog(@"Warning: Could not retrieve bundle identifier. Using fallback.");
    }
    NSURL *booksDirectory = [[appSupportURL URLByAppendingPathComponent:bundleID] URLByAppendingPathComponent:@"Books"];

    NSError *error = nil;
    if (![fileManager fileExistsAtPath:booksDirectory.path]) {
        [fileManager createDirectoryAtURL:booksDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            NSLog(@"Error creating books directory: %@", error.localizedDescription);
            return nil;
        }
    }
    return booksDirectory;
}

- (void)updateBookViewWithContent:(NSAttributedString *)attributedString title:(NSString *)title {
    BookTextView *textView = [self findBookTextView];
    if (!textView) {
        NSLog(@"Error: BookTextView not found when trying to display content.");
        return;
    }
    [[textView textStorage] setAttributedString:attributedString];
    self.window.title = title;
    [textView scrollRangeToVisible:NSMakeRange(0, 0)];
    [self.window makeFirstResponder:textView];
}

- (void)displayBookFromFileURL:(NSURL *)fileURL title:(NSString *)bookTitle {
    NSError *error = nil;
    NSString *fileContent = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];
    
    BookTextView *textViewToUpdate = [self findBookTextView];
    if (!textViewToUpdate) {
         NSLog(@"Cannot open document: BookTextView instance not found.");
         return;
    }
    NSFont *defaultFont = textViewToUpdate.font ?: [NSFont systemFontOfSize:16.0];

    if (fileContent) {
        NSAttributedString *styledContent = [MarkdownParser attributedStringFromMarkdownString:fileContent defaultFont:defaultFont];
        [self updateBookViewWithContent:styledContent title:bookTitle];
    } else {
        NSString *errorMessage = [NSString stringWithFormat:@"Error loading file: %@\nPath: %@", error.localizedDescription, fileURL.path];
        NSAttributedString *styledError = [[NSAttributedString alloc] initWithString:errorMessage attributes:@{NSFontAttributeName: defaultFont, NSForegroundColorAttributeName: [NSColor redColor]}];
        [self updateBookViewWithContent:styledError title:@"Error Loading Book"];
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Error Opening Saved Book";
        alert.informativeText = errorMessage;
        [alert addButtonWithTitle:@"OK"];
        alert.alertStyle = NSAlertStyleWarning;
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
    }
}

- (void)showBookLibraryWindow:(id)sender {
    if (!self.libraryWindow) {
        NSRect frame = NSMakeRect(0, 0, 500, 400);
        self.libraryWindow = [[NSWindow alloc] initWithContentRect:frame
                                                          styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                            backing:NSBackingStoreBuffered
                                                              defer:NO];
        self.libraryWindow.title = @"Online Book Library";
        [self.libraryWindow center];

        // Create Search Field
        self.librarySearchField = [[NSSearchField alloc] initWithFrame:NSMakeRect(20, frame.size.height - 50, frame.size.width - 40, 24)];
        self.librarySearchField.autoresizingMask = NSViewWidthSizable | NSViewMinYMargin;
        [self.librarySearchField.cell setTarget:self];
        [self.librarySearchField.cell setAction:@selector(searchLibrary:)];
        [self.libraryWindow.contentView addSubview:self.librarySearchField];

        // Create ScrollView for TableView
        NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 60, frame.size.width - 40, frame.size.height - 50 - 60)];
        scrollView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        scrollView.hasVerticalScroller = YES;

        // Create TableView
        self.libraryTableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
        self.libraryTableView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
        self.libraryTableView.dataSource = self;
        self.libraryTableView.delegate = self;
        self.libraryTableView.allowsMultipleSelection = NO;
        self.libraryTableView.doubleAction = @selector(downloadSelectedBook:); // Double-click to download

        NSTableColumn *titleCol = [[NSTableColumn alloc] initWithIdentifier:@"TitleColumn"];
        titleCol.title = @"Title";
        titleCol.width = 250;
        [self.libraryTableView addTableColumn:titleCol];

        NSTableColumn *authorCol = [[NSTableColumn alloc] initWithIdentifier:@"AuthorColumn"];
        authorCol.title = @"Author";
        authorCol.width = 200;
        [self.libraryTableView addTableColumn:authorCol];
        
        scrollView.documentView = self.libraryTableView;
        [self.libraryWindow.contentView addSubview:scrollView];

        // Create Download Button
        NSButton *downloadButton = [NSButton buttonWithTitle:@"Download & Open" target:self action:@selector(downloadSelectedBook:)];
        downloadButton.frame = NSMakeRect(frame.size.width - 160, 20, 140, 25);
        downloadButton.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;
        [self.libraryWindow.contentView addSubview:downloadButton];

        // Create Cancel Button
        NSButton *cancelButton = [NSButton buttonWithTitle:@"Cancel" target:self.libraryWindow action:@selector(performClose:)];
        cancelButton.frame = NSMakeRect(frame.size.width - 160 - 100, 20, 80, 25);
        cancelButton.autoresizingMask = NSViewMinXMargin | NSViewMaxYMargin;
        [self.libraryWindow.contentView addSubview:cancelButton];
    }
    [self.libraryTableView reloadData];
    [self.libraryWindow makeKeyAndOrderFront:sender];
}

- (void)searchLibrary:(NSSearchField *)sender {
    NSString *searchText = [sender.stringValue lowercaseString];
    if (searchText.length == 0) {
        self.displayedBooks = self.allBooks;
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(NSDictionary *book, NSDictionary *bindings) {
            NSString *title = [book[@"title"] lowercaseString];
            NSString *author = [book[@"author"] lowercaseString];
            return [title containsString:searchText] || [author containsString:searchText];
        }];
        self.displayedBooks = [self.allBooks filteredArrayUsingPredicate:predicate];
    }
    [self.libraryTableView reloadData];
}

- (void)downloadSelectedBook:(id)sender {
    NSInteger selectedRow = self.libraryTableView.selectedRow;
    if (selectedRow < 0 || selectedRow >= self.displayedBooks.count) {
        return;
    }

    NSDictionary *selectedBook = self.displayedBooks[selectedRow];
    NSString *fileName = selectedBook[@"filename"];
    NSString *urlString = selectedBook[@"url"];
    NSString *bookTitle = selectedBook[@"title"];

    if (!fileName || !urlString || !bookTitle) {
        NSLog(@"Error: Selected book data is incomplete.");
        // Show an alert
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Book Data Error";
        alert.informativeText = @"The selected book's information (filename, URL, or title) is missing.";
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:self.libraryWindow completionHandler:nil];
        return;
    }
    
    [self.libraryWindow performClose:sender]; // Close library window

    NSURL *localBooksDir = [self applicationBooksDirectory];
    if (!localBooksDir) {
         // Error creating directory already logged, show alert
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Storage Error";
        alert.informativeText = @"Could not access or create the local book storage directory.";
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:self.window completionHandler:nil];
        return;
    }
    NSURL *localFileURL = [localBooksDir URLByAppendingPathComponent:fileName];

    if ([[NSFileManager defaultManager] fileExistsAtPath:localFileURL.path]) {
        NSLog(@"Book '%@' already downloaded. Opening local copy.", bookTitle);
        [self displayBookFromFileURL:localFileURL title:bookTitle];
    } else {
        NSLog(@"Downloading '%@' from %@", bookTitle, urlString);
        // Show some progress indicator or change window title
        self.window.title = [NSString stringWithFormat:@"Downloading %@...", bookTitle];

        NSURL *downloadURL = [NSURL URLWithString:urlString];
        if (!downloadURL) {
            NSLog(@"Error: Invalid URL string for download: %@", urlString);
            self.window.title = @"Error: Invalid Download URL";
            // Show an alert
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Download Error";
            alert.informativeText = [NSString stringWithFormat:@"The URL for the book '%@' is invalid.", bookTitle];
            [alert addButtonWithTitle:@"OK"];
            [alert beginSheetModalForWindow:self.window completionHandler:nil];
            return;
        }
        
        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
            dataTaskWithURL:downloadURL
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              dispatch_async(dispatch_get_main_queue(), ^{
                  if (error) {
                      NSLog(@"Download error for '%@': %@", bookTitle, error.localizedDescription);
                      self.window.title = @"Download Failed";
                      NSAlert *alert = [[NSAlert alloc] init];
                      alert.messageText = @"Download Failed";
                      alert.informativeText = [NSString stringWithFormat:@"Could not download '%@':\n%@", bookTitle, error.localizedDescription];
                      [alert addButtonWithTitle:@"OK"];
                      [alert beginSheetModalForWindow:self.window completionHandler:nil];
                      return;
                  }

                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                  if (httpResponse.statusCode == 200) {
                      NSError *writeError = nil;
                      if ([data writeToURL:localFileURL options:NSDataWritingAtomic error:&writeError]) {
                          NSLog(@"Successfully downloaded and saved '%@'", bookTitle);
                          [self displayBookFromFileURL:localFileURL title:bookTitle];
                      } else {
                          NSLog(@"Error saving downloaded file '%@': %@", bookTitle, writeError.localizedDescription);
                          self.window.title = @"Error Saving File";
                          NSAlert *alert = [[NSAlert alloc] init];
                          alert.messageText = @"File Save Error";
                          alert.informativeText = [NSString stringWithFormat:@"Could not save the downloaded book '%@':\n%@", bookTitle, writeError.localizedDescription];
                          [alert addButtonWithTitle:@"OK"];
                          [alert beginSheetModalForWindow:self.window completionHandler:nil];
                      }
                  } else {
                       NSLog(@"Download failed for '%@': HTTP status code %ld", bookTitle, (long)httpResponse.statusCode);
                       self.window.title = @"Download Failed";
                       NSAlert *alert = [[NSAlert alloc] init];
                       alert.messageText = @"Download Failed";
                       alert.informativeText = [NSString stringWithFormat:@"Could not download '%@'. Server returned status code %ld.", bookTitle, (long)httpResponse.statusCode];
                       [alert addButtonWithTitle:@"OK"];
                       [alert beginSheetModalForWindow:self.window completionHandler:nil];
                  }
              });
          }];
        [downloadTask resume];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == self.libraryTableView) {
        return self.displayedBooks.count;
    }
    return 0;
}

#pragma mark - NSTableViewDelegate

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (tableView == self.libraryTableView) {
        NSDictionary *book = self.displayedBooks[row];
        NSString *identifier = tableColumn.identifier;
        NSTextField *textField = [tableView makeViewWithIdentifier:identifier owner:self];

        if (!textField) {
            textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
            textField.identifier = identifier;
            textField.bordered = NO;
            textField.drawsBackground = NO;
            textField.editable = NO;
            textField.selectable = NO; // Or YES if you want selection in cells
        }

        if ([identifier isEqualToString:@"TitleColumn"]) {
            textField.stringValue = book[@"title"] ?: @"";
        } else if ([identifier isEqualToString:@"AuthorColumn"]) {
            textField.stringValue = book[@"author"] ?: @"";
        }
        return textField;
    }
    return nil;
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
                NSFont *defaultTextViewFont = textViewToUpdate.font ?: [NSFont systemFontOfSize:16.0];

                NSError *error = nil;
                // Read the raw string content from the selected file
                NSString *fileContent = [NSString stringWithContentsOfURL:selectedFileURL
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
                if (fileContent) {
                    // Parse the Markdown string into an NSAttributedString
                    NSAttributedString *styledContent = [MarkdownParser attributedStringFromMarkdownString:fileContent defaultFont:defaultTextViewFont];
                    [self updateBookViewWithContent:styledContent title:selectedFileURL.lastPathComponent];
                } else {
                    // Handle error loading file content
                    NSString *errorMessage = [NSString stringWithFormat:@"Error loading file content: %@\nPath: %@", error.localizedDescription, selectedFileURL.path];
                    NSAttributedString *styledError = [[NSAttributedString alloc] initWithString:errorMessage attributes:@{NSFontAttributeName: defaultTextViewFont, NSForegroundColorAttributeName: [NSColor redColor]}];
                    [self updateBookViewWithContent:styledError title:@"Error"];
                    
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

