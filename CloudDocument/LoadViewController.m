//
//  LoadViewController.m
//  CloudDocument
//
//  Created by Hoshi Takanori on 12/01/28.
//  Copyright (c) 2012 -. All rights reserved.
//

#import "LoadViewController.h"
#import "CloudDocument.h"
#import "SimpleHUD.h"

#define KEY_ISCLOUD @"isCloud"

#define EXT_TXT     @"txt"

#define INDEX_LOCAL 0
#define INDEX_CLOUD 1

#define INDEX_OK    1

// uncomment to test SimpleHUD on open/save as local files.
//#define LOCAL_OPEN_DELAY 5
//#define LOCAL_SAVE_DELAY 5

@interface LoadViewController () <UITextFieldDelegate, UIAlertViewDelegate> {
    UITextField *textField;
    UIButton *saveButton;
    UITableView *tableView;
    BOOL isOpened;

    BOOL isCloud;
    NSMetadataQuery *query;

    SEL confirmSelector;
    id confirmObject;
}

@property (nonatomic, retain) NSArray *items;

- (void)handleSave:(id)sender;

- (NSArray *)fileItems;
- (BOOL)deletePath:(NSString *)path;
- (void)openPath:(NSString *)path;
- (void)saveAs:(NSString *)filename path:(NSString *)path;
- (void)saveAsPath:(NSString *)path;

- (BOOL)isCloudAvailable;
- (void)startQuery;
- (BOOL)deleteURL:(NSURL *)url;
- (void)openURL:(NSURL *)url;
- (void)saveAs:(NSString *)filename url:(NSURL *)url;

@end

@implementation LoadViewController

@synthesize delegate;
@synthesize isSaveAs;
@synthesize items;

#pragma mark - view lifecycle

- (void)loadView
{
    CGRect frame = [UIScreen mainScreen].applicationFrame;

    if (isSaveAs) {
        UIView *view = [[UIView alloc] initWithFrame:frame];
        view.backgroundColor = [UIColor groupTableViewBackgroundColor];

        textField = [[UITextField alloc] initWithFrame:CGRectMake(8, 8, view.bounds.size.width - 56 - 3 * 8, 31)];
        textField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.placeholder = @"Filename";
        textField.delegate = self;
        [view addSubview:textField];

        saveButton = [[UIButton buttonWithType:UIButtonTypeRoundedRect] retain];
        saveButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        saveButton.frame = CGRectMake(view.bounds.size.width - 56 - 8, 8, 56, 31);
        [saveButton setTitle:@"Save" forState:UIControlStateNormal];
        [saveButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
        [saveButton addTarget:self action:@selector(handleSave:) forControlEvents:UIControlEventTouchUpInside];
        saveButton.enabled = NO;
        [view addSubview:saveButton];

        frame = view.bounds;
        frame.origin.y += 47;
        frame.size.height -= 47;

        self.view = view;
        [view release];
    }

    tableView = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.dataSource = self;
    tableView.delegate = self;

    if (isSaveAs) {
        [self.view addSubview:tableView];
    } else {
        self.view = tableView;
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = isSaveAs ? @"Save as" : @"Open";

    isCloud = NO;
    if (self.isCloudAvailable) {
        isCloud = [[NSUserDefaults standardUserDefaults] boolForKey:KEY_ISCLOUD];

        NSArray *array = [NSArray arrayWithObjects:@"Local", @"Cloud", nil];
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:array];
        control.segmentedControlStyle = UISegmentedControlStyleBar;
        [control setWidth:64 forSegmentAtIndex:INDEX_LOCAL];
        [control setWidth:64 forSegmentAtIndex:INDEX_CLOUD];
        [control addTarget:self action:@selector(handleCloud:) forControlEvents:UIControlEventValueChanged];
        control.selectedSegmentIndex = ! isCloud ? INDEX_LOCAL : INDEX_CLOUD;
        self.navigationItem.titleView = control;
        [control release];
    }

    if (! isCloud) {
        self.items = [self fileItems];
    } else {
        [self startQuery];
    }

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(handleCancel:)];
    self.navigationItem.leftBarButtonItem = button;
    [button release];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (! isOpened) {
        [textField becomeFirstResponder];
        isOpened = NO;
    }

    if (query.isStarted && ! query.isStopped) {
        [query enableUpdates];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (query.isStarted && ! query.isStopped) {
        [query disableUpdates];
    }
}

#pragma mark - event handling

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [textField resignFirstResponder];
}

- (BOOL)textField:(UITextField *)theTextField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *filename = [textField.text stringByReplacingCharactersInRange:range withString:string];
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    filename = [filename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    saveButton.enabled = (filename.length > 0);
    return YES;
}

- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    saveButton.enabled = NO;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField
{
    [self handleSave:textField];
    return YES;
}

- (void)handleSave:(id)sender
{
    NSString *filename = textField.text;
    filename = [filename stringByReplacingOccurrencesOfString:@"/" withString:@" "];
    filename = [filename stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (filename.length > 0) {
        if (! isCloud) {
            [self saveAs:filename path:nil];
        } else {
            [self saveAs:filename url:nil];
        }
    }
}

- (void)handleCloud:(id)sender
{
    isCloud = (((UISegmentedControl *) sender).selectedSegmentIndex == INDEX_CLOUD);
    if (! isCloud) {
        [query stopQuery];
        self.items = [self fileItems];
    } else {
        self.items = nil;
        [self startQuery];
    }

    [tableView reloadData];

    [[NSUserDefaults standardUserDefaults] setBool:isCloud forKey:KEY_ISCLOUD];
}

- (void)closeWithData:(id)data
{
    if (data != nil) {
        [delegate loadData:data];
    }

    [self.navigationController dismissModalViewControllerAnimated:YES];
}

- (void)handleCancel:(id)sender
{
    [self closeWithData:nil];
}

#pragma mark - table view

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return items.count;
}

static NSString *get_name(id obj)
{
    if ([obj isKindOfClass:[NSURL class]]) {
        obj = [obj path];
    }
    return [[obj lastPathComponent] stringByDeletingPathExtension];
}

- (UITableViewCell *)tableView:(UITableView *)theTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }

    cell.textLabel.text = get_name([items objectAtIndex:indexPath.row]);

    return cell;
}

- (void)tableView:(UITableView *)theTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id obj = [items objectAtIndex:indexPath.row];
    if ([obj isKindOfClass:[NSString class]]) {
        if (isSaveAs) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self saveAs:get_name(obj) path:obj];
        } else {
            [self openPath:obj];
        }
    } else if ([obj isKindOfClass:[NSURL class]]) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (isSaveAs) {
            [self saveAs:get_name(obj) url:obj];
        } else {
            [self openURL:obj];
        }
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [tableView setEditing:editing animated:animated];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)theTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        id obj = [items objectAtIndex:indexPath.row];
        BOOL deleted = NO;
        if ([obj isKindOfClass:[NSString class]]) {
            deleted = [self deletePath:obj];
        } else if ([obj isKindOfClass:[NSURL class]]) {
            deleted = [self deleteURL:obj];
        }
        if (deleted) {
            [(NSMutableArray *) items removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }
    }
}

#pragma mark - alert view

- (void)alert:(NSString *)title error:(NSError *)error
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:error.localizedDescription
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
}

- (void)confirm:(NSString *)title message:(NSString *)message selector:(SEL)selector object:(id)object
{
    confirmSelector = selector;
    [confirmObject release];
    confirmObject = [object retain];

    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"OK", nil];
    [alertView show];
    [alertView release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == INDEX_OK) {
        [self performSelector:confirmSelector withObject:confirmObject];
    }

    confirmSelector = NULL;
    [confirmObject release];
    confirmObject = nil;
}

#pragma mark - file handling

- (NSString *)documentPath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths objectAtIndex:0];
}

static NSInteger compare(id obj1, id obj2, void *context)
{
    NSString *str1 = get_name(obj1);
    NSString *str2 = get_name(obj2);
    if ([str1 respondsToSelector:@selector(localizedStandardCompare:)]) {
        return [str1 localizedStandardCompare:str2];
    } else {
        return [str1 compare:str2
                     options:NSCaseInsensitiveSearch | NSNumericSearch | NSForcedOrderingSearch
                       range:NSMakeRange(0, str1.length)
                      locale:[NSLocale currentLocale]];
    }
}

- (NSArray *)fileItems
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSString *documentPath = self.documentPath;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:NULL];
    for (NSString *filename in files) {
        if ([[filename pathExtension] isEqualToString:EXT_TXT]) {
            [array addObject:[documentPath stringByAppendingPathComponent:filename]];
        }
    }
    [array sortUsingFunction:compare context:NULL];
    return [array autorelease];
}

- (BOOL)deletePath:(NSString *)path
{
    NSError *error = nil;
    BOOL result = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
    if (! result) {
        [self alert:@"Delete Failed" error:error];
    }
    return result;
}

-(void)openPath:(NSString *)path
{
#ifdef LOCAL_OPEN_DELAY
    [SimpleHUD show];
    [self performSelector:@selector(openLater:) withObject:path afterDelay:LOCAL_OPEN_DELAY];
}

- (void)openLater:(NSString *)path
{
    [SimpleHUD dismiss];
#endif

    [self closeWithData:[NSData dataWithContentsOfFile:path]];
}

- (void)saveAs:(NSString *)filename path:(NSString *)path
{
    if (path == nil) {
        path = [self.documentPath stringByAppendingPathComponent:filename];

        if (! [[filename pathExtension] isEqualToString:EXT_TXT]) {
            path = [path stringByAppendingPathExtension:EXT_TXT];
        }
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *message = [NSString stringWithFormat:@"Are you sure to replace \"%@\"?", filename];
        [self confirm:@"Replacing Existing File" message:message selector:@selector(saveAsPath:) object:path];
    } else {
        [self saveAsPath:path];
    }
}

- (void)saveAsPath:(NSString *)path
{
#ifdef LOCAL_SAVE_DELAY
    [SimpleHUD show];
    [self performSelector:@selector(saveLater:) withObject:path afterDelay:LOCAL_SAVE_DELAY];
}

- (void)saveLater:(NSString *)path
{
    [SimpleHUD dismiss];
#endif

    NSError *error = nil;
    if ([[delegate dataToSave] writeToFile:path options:NSDataWritingAtomic error:&error]) {
        [self closeWithData:nil];
    } else {
        [self alert:@"Save Failed" error:error];
    }
}

#pragma mark - cloud handling

- (BOOL)isCloudAvailable
{
    return [[NSFileManager defaultManager] respondsToSelector:@selector(URLForUbiquityContainerIdentifier:)] &&
           [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil] != nil;
}

- (void)startQuery
{
    if (query == nil) {
        query = [[NSClassFromString(@"NSMetadataQuery") alloc] init];
        query.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDocumentsScope];
        NSString *format = [NSString stringWithFormat:@"%%K like '*.%@'", EXT_TXT];
        query.predicate = [NSPredicate predicateWithFormat:format, NSMetadataItemFSNameKey];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateQueryResult:)
                                                     name:NSMetadataQueryDidFinishGatheringNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateQueryResult:)
                                                     name:NSMetadataQueryDidUpdateNotification
                                                   object:nil];
    }

    [query startQuery];
}

- (void)updateQueryResult:(NSNotification *)notification
{
    [query disableUpdates];

    NSMutableArray *array = [[NSMutableArray alloc] init];
    for (NSMetadataItem *item in query.results) {
        [array addObject:[item valueForAttribute:NSMetadataItemURLKey]];
    }
    [array sortUsingFunction:compare context:NULL];
    if (! [self.items isEqualToArray:array]) {
        self.items = array;
        [tableView reloadData];
    }
    [array release];

    [query enableUpdates];
}

- (BOOL)deleteURL:(NSURL *)url
{
    [CloudDocument deleteURL:url];
    return YES;
}

- (void)openURL:(NSURL *)url
{
    [CloudDocument openURL:url onSuccess:^(CloudDocument *document) {
        [self closeWithData:document.data];
    }];
}

- (void)saveAs:(NSString *)filename url:(NSURL *)url
{
    BOOL replacing = (url != nil);

    if (url == nil) {
        url = [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
        url = [[url URLByAppendingPathComponent:@"Documents"] URLByAppendingPathComponent:filename];

        if (! [[filename pathExtension] isEqualToString:EXT_TXT]) {
            url = [url URLByAppendingPathExtension:EXT_TXT];
        }

        replacing = [items containsObject:url];
    }

    if (replacing) {
        NSString *message = [NSString stringWithFormat:@"Are you sure to replace \"%@\"?", filename];
        [self confirm:@"Replacing Cloud File" message:message selector:@selector(saveAsURL:) object:url];
    } else {
        [CloudDocument createURL:url data:[delegate dataToSave]];
        [self closeWithData:nil];
    }
}

- (void)saveAsURL:(NSURL *)url
{
    [CloudDocument openURL:url onSuccess:^(CloudDocument *document) {
        [document changeData:[delegate dataToSave]];
        [self closeWithData:nil];
    }];
}

#pragma mark - clean up

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [textField release];
    textField = nil;
    [saveButton release];
    saveButton = nil;
    [tableView release];
    tableView = nil;
}

- (void)dealloc
{
    [items release];
    [textField release];
    [saveButton release];
    [tableView release];
    [query release];
    [confirmObject release];
    [super dealloc];
}

@end
