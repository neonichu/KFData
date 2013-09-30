//
//  KFDataTableViewController.m
//  KFData
//
//  Created by Kyle Fuller on 08/11/2012.
//  Copyright (c) 2012-2013 Kyle Fuller. All rights reserved.
//

#import "KFDataTableViewController.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KFDataStore.h"

@interface KFDataTableViewController ()

@end

@implementation KFDataTableViewController

#pragma mark -

- (instancetype)initWithNibName:(NSString *)nibNameOrNil
                         bundle:(NSBundle *)nibBundleOrNil
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSParameterAssert(managedObjectContext);

    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self commonInitWithManagedObjectContext:managedObjectContext];
    }

    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                                       style:(UITableViewStyle)style
{
    NSParameterAssert(managedObjectContext);

    if (self = [super initWithStyle:style]) {
        [self commonInitWithManagedObjectContext:managedObjectContext];
    }

    return self;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [self initWithManagedObjectContext:managedObjectContext style:UITableViewStylePlain]) {
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
         managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSParameterAssert(managedObjectContext);

    if (self = [super initWithCoder:coder]) {
        [self commonInitWithManagedObjectContext:managedObjectContext];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    NSString *reason = [NSString stringWithFormat:@"%@ Failed to call designated initializer. Overide `initWithCoder:` and call `initWithCoder:managedObjectContext:` instead.", NSStringFromClass([self class])];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

- (instancetype)init {
    NSString *reason = [NSString stringWithFormat:@"%@ Failed to call designated initializer. Invoke `initWithManagedObjectContext:` instead.", NSStringFromClass([self class])];
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:reason userInfo:nil];
}

- (void)commonInitWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
    NSParameterAssert(managedObjectContext != nil);

    _managedObjectContext = managedObjectContext;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectContextDidReset:) name:KFDataManagedObjectContextDidReset object:managedObjectContext];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:KFDataManagedObjectContextDidReset object:_managedObjectContext];
}

#pragma mark - Notification Handlers

- (void)managedObjectContextDidReset:(NSNotification *)notification {
    if ([self isViewLoaded]) {
        [self performFetch];
    }
}

#pragma mark - View

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self performFetch];
}

#pragma mark -

- (void)setFetchRequest:(NSFetchRequest *)fetchRequest
     sectionNameKeyPath:(NSString*)sectionNameKeyPath
{
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];

    NSFetchedResultsController *fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                               managedObjectContext:managedObjectContext
                                                                                                 sectionNameKeyPath:sectionNameKeyPath
                                                                                                          cacheName:nil];

    [self setFetchedResultsController:fetchedResultsController];
}

- (void)setFetchedResultsController:(NSFetchedResultsController *)fetchedResultsController
{
    _fetchedResultsController = fetchedResultsController;

    [fetchedResultsController setDelegate:self];
    if ([self isViewLoaded]) {
        [self performFetch];
    }
}

- (void)performFetch {
    NSError *fetchError;
    if ([[self fetchedResultsController] performFetch:&fetchError] == NO) {
        NSLog(@"KFData: Fetch request error: %@", fetchError);
    }

    [[self tableView] reloadData];
}

- (NSManagedObject *)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [[self fetchedResultsController] objectAtIndexPath:indexPath];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView *tableView = [self tableView];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:sectionIndex];

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:indexSet
                     withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:indexSet
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = [self tableView];

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate: {
            [tableView reloadRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        }

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [[self tableView] endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSArray *sections = [[self fetchedResultsController] sections];
    NSUInteger count = [sections count];

    return (NSInteger)count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *sections = [[self fetchedResultsController] sections];
    id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:section];

	NSUInteger count = [sectionInfo numberOfObjects];
	return (NSInteger)count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"tableView:cellForRowAtIndexPath: must be overidden." userInfo:nil];
}

@end

#endif
