#import "MarkdownParser.h"

@implementation MarkdownParser

+ (NSAttributedString *)attributedStringFromMarkdownString:(NSString *)markdownString
                                                defaultFont:(NSFont *)defaultFont {
    // Ensure a default font is provided or set one.
    if (!defaultFont) {
        defaultFont = [NSFont systemFontOfSize:16.0]; // Default size if none provided
    }

    // This will hold the final styled string.
    NSMutableAttributedString *finalAttributedString = [[NSMutableAttributedString alloc] init];
    // Split the input Markdown into individual lines for processing.
    NSArray<NSString *> *lines = [markdownString componentsSeparatedByString:@"\n"];

    // --- Define Fonts and Styles (Approximating GitHub's look) ---
    CGFloat defaultSize = defaultFont.pointSize;

    // Fonts for different heading levels.
    NSFont *h1Font = [NSFont systemFontOfSize:defaultSize * 1.8 weight:NSFontWeightSemibold]; // Larger and bolder for H1
    NSFont *h2Font = [NSFont systemFontOfSize:defaultSize * 1.4 weight:NSFontWeightSemibold]; // Slightly smaller, bold for H2
    
    // Font for italicized text.
    NSFont *italicFont = [[NSFontManager sharedFontManager] convertFont:defaultFont toHaveTrait:NSFontItalicTrait];
    // Font for bold and italicized text (used for the "*1*" example).
    NSFont *boldItalicFont = [[NSFontManager sharedFontManager] convertFont:defaultFont toHaveTrait:NSFontBoldTrait | NSFontItalicTrait];

    // --- Paragraph Styles ---
    // Default style for regular paragraphs.
    NSMutableParagraphStyle *defaultParagraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    defaultParagraphStyle.paragraphSpacingBefore = defaultSize * 0.2; // Space before a paragraph
    defaultParagraphStyle.paragraphSpacing = defaultSize * 0.5;      // Space after a paragraph
    defaultParagraphStyle.lineSpacing = defaultSize * 0.2;           // Extra space between lines within a paragraph

    // Style for headings, typically with more space around them.
    NSMutableParagraphStyle *headingParagraphStyle = [defaultParagraphStyle mutableCopy];
    headingParagraphStyle.paragraphSpacingBefore = defaultSize * 0.8; // More space before headings
    headingParagraphStyle.paragraphSpacing = defaultSize * 0.3;       // Space after headings

    // Style for horizontal rules, giving them distinct spacing.
    NSMutableParagraphStyle *hrParagraphStyle = [defaultParagraphStyle mutableCopy];
    hrParagraphStyle.paragraphSpacingBefore = defaultSize * 1.2; // Significant space before HR
    hrParagraphStyle.paragraphSpacing = defaultSize * 1.2;       // Significant space after HR

    // --- Line-by-Line Parsing ---
    for (NSUInteger i = 0; i < lines.count; i++) {
        NSString *line = lines[i];
        // Trim leading/trailing whitespace to simplify checks.
        NSString *trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSMutableAttributedString *lineAttrString = nil;

        // --- Horizontal Rules ---
        // Detects common Markdown horizontal rule syntaxes.
        if ([trimmedLine isEqualToString:@"-------"] || [trimmedLine isEqualToString:@"------------"] ||
            [trimmedLine isEqualToString:@"---"] || [trimmedLine isEqualToString:@"***"] || [trimmedLine isEqualToString:@"___"]) {
            // Represent HR with a string of em-dashes or other characters.
            // Adding newlines before and after to ensure it's on its own visual block.
            NSString *hrText = @"\n————————————————————\n"; 
            NSDictionary *hrAttributes = @{
                NSFontAttributeName: [NSFont systemFontOfSize:defaultSize * 0.8 weight:NSFontWeightLight],
                NSForegroundColorAttributeName: [NSColor grayColor], // HR is often gray
                NSParagraphStyleAttributeName: hrParagraphStyle
            };
            lineAttrString = [[NSMutableAttributedString alloc] initWithString:hrText attributes:hrAttributes];
        }
        // --- Headings ---
        else if ([trimmedLine hasPrefix:@"## "]) { // H2 heading
            NSString *text = [trimmedLine substringFromIndex:3]; // Get text after "## "
            NSDictionary *attributes = @{
                NSFontAttributeName: h2Font,
                NSParagraphStyleAttributeName: headingParagraphStyle,
                NSForegroundColorAttributeName: [NSColor textColor] // Use standard text color
            };
            lineAttrString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
        } else if ([trimmedLine hasPrefix:@"# "]) { // H1 heading
            NSString *text = [trimmedLine substringFromIndex:2]; // Get text after "# "
            NSDictionary *attributes = @{
                NSFontAttributeName: h1Font,
                NSParagraphStyleAttributeName: headingParagraphStyle,
                NSForegroundColorAttributeName: [NSColor textColor]
            };
            lineAttrString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
        }
        // --- Paragraphs & Inline Styling ---
        else {
            // Default attributes for a paragraph line.
            NSDictionary *attributes = @{
                NSFontAttributeName: defaultFont,
                NSParagraphStyleAttributeName: defaultParagraphStyle,
                NSForegroundColorAttributeName: [NSColor textColor]
            };
            // Use the original line (not trimmedLine) to preserve leading/trailing spaces if intended within a line.
            lineAttrString = [[NSMutableAttributedString alloc] initWithString:line attributes:attributes];

            // --- Inline Styling: Italics and Special Numeric Emphasis ---
            // Regex for _text_ (underscore italics)
            NSRegularExpression *italicRegexUnderscore = [NSRegularExpression regularExpressionWithPattern:@"_(.+?)_" options:0 error:nil];
            // Regex for *text* (asterisk italics)
            NSRegularExpression *italicRegexAsterisk = [NSRegularExpression regularExpressionWithPattern:@"\\*(.+?)\\*" options:0 error:nil];
            // Regex for special numeric emphasis like *1* (to be bold italic)
            NSRegularExpression *numericEmphasisRegex = [NSRegularExpression regularExpressionWithPattern:@"\\*(\\d+)\\*" options:0 error:nil];

            // Apply numeric emphasis first (e.g., *1*)
            NSArray<NSTextCheckingResult *> *numericMatches = [numericEmphasisRegex matchesInString:lineAttrString.string options:0 range:NSMakeRange(0, lineAttrString.length)];
            for (NSTextCheckingResult *match in [numericMatches reverseObjectEnumerator]) { // Iterate backwards for safe modification
                NSRange contentRange = [match rangeAtIndex:1]; // Range of the number inside '*'
                [lineAttrString addAttribute:NSFontAttributeName value:boldItalicFont range:contentRange];
                // Replace the "*1*" with just "1"
                [lineAttrString replaceCharactersInRange:[match rangeAtIndex:0] withString:[lineAttrString.string substringWithRange:contentRange]];
            }
            
            // Helper block to apply italic style and remove markers
            void (^applyItalicAndRemoveMarkers)(NSRegularExpression*, NSMutableAttributedString*) =
                ^(NSRegularExpression *regex, NSMutableAttributedString *attrStr) {
                NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:attrStr.string options:0 range:NSMakeRange(0, attrStr.length)];
                for (NSTextCheckingResult *match in [matches reverseObjectEnumerator]) {
                    // Check if this match was already handled by numericEmphasisRegex to avoid double processing
                    // This is a simple check; more robust would be to track ranges.
                    BOOL alreadyHandled = NO;
                    for (NSTextCheckingResult *numMatch in numericMatches) {
                        if (NSEqualRanges(match.range, numMatch.range)) {
                            alreadyHandled = YES;
                            break;
                        }
                    }
                    if (alreadyHandled) continue;

                    NSRange fullMatchRange = [match rangeAtIndex:0]; // e.g., range of "_text_"
                    NSRange contentRange = [match rangeAtIndex:1];   // e.g., range of "text"
                    
                    // Apply italic font to the content part
                    [attrStr addAttribute:NSFontAttributeName value:italicFont range:contentRange];
                    // Replace the full match (e.g., "_text_") with just its content ("text")
                    // This is done by adjusting the attributed string.
                    NSString *justContent = [attrStr.string substringWithRange:contentRange];
                    [attrStr replaceCharactersInRange:fullMatchRange withString:justContent];
                }
            };

            // Apply italics, ensuring not to re-process parts handled by numeric emphasis.
            applyItalicAndRemoveMarkers(italicRegexUnderscore, lineAttrString);
            applyItalicAndRemoveMarkers(italicRegexAsterisk, lineAttrString);
        }

        // --- Append the processed line to the final string ---
        if (lineAttrString) {
            [finalAttributedString appendAttributedString:lineAttrString];
            // Add a newline character after each processed line, unless it's a special HR block
            // or the last line of the input.
            BOOL isHRLine = ([trimmedLine isEqualToString:@"-------"] || [trimmedLine isEqualToString:@"------------"] ||
                             [trimmedLine isEqualToString:@"---"] || [trimmedLine isEqualToString:@"***"] || [trimmedLine isEqualToString:@"___"]);
            
            if (!isHRLine && i < lines.count - 1) {
                 [finalAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n"]];
            }
        } else if (trimmedLine.length == 0 && finalAttributedString.length > 0) {
            // Handle blank lines for paragraph separation if not already handled by paragraphSpacing.
            // Ensure we don't add too many newlines if paragraph styles already add them.
            if (![[[finalAttributedString attributedSubstringFromRange:NSMakeRange(finalAttributedString.length - 1, 1)] string] isEqualToString:@"\n"]) {
                [finalAttributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n" attributes:@{NSParagraphStyleAttributeName: defaultParagraphStyle}]];
            }
        }
    }
    return finalAttributedString;
}
@end
