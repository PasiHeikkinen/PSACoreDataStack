//
//  PSACoreDataStack.m
//  PSACoreDataStack
//
//  Created by Pasi Heikkinen on 2/15/13.
//  Copyright (c) 2013 Pasi Heikkinen.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "PSACoreDataStack.h"

typedef NSPersistentStore *(^AddPersistentStoreBlockType)(NSPersistentStoreCoordinator *coordinator, NSError **error);

NSString *const PSACoreDataStackBackupWhenModelUpgradedUserDefaultsKey = @"PSACoreDataStackBackupWhenModelUpgraded";

@interface PSACoreDataStack ()

@property(nonatomic, readwrite) NSString *modelName;
@property(nonatomic, readwrite) NSBundle *bundle;
@property(nonatomic, copy) AddPersistentStoreBlockType addPersistentStoreBlock;

@property(nonatomic, readwrite) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, readwrite) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property(nonatomic, readwrite) NSArray *errors;

@property(nonatomic, readonly) NSURL *modelLocation;

- (id)initWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle block:(AddPersistentStoreBlockType)block;

@end

@implementation PSACoreDataStack

+ (NSURL *)storeURLWithBundle:(NSBundle *)bundle modelName:(NSString *)modelName extension:(NSString *)extension {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *result = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    result = [result URLByAppendingPathComponent:[bundle bundleIdentifier]];
    result = [result URLByAppendingPathComponent:modelName];
    result = [result URLByAppendingPathExtension:extension];
    return result;
}

- (id)initWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle block:(AddPersistentStoreBlockType)block {
    self = [super init];
    if (self) {
        self.modelName = modelName;
        self.bundle = bundle;
        self.addPersistentStoreBlock = block;
    }
    return self;
}

+ (id)stackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle {
    return [self SQLiteStackWithModelName:modelName bundle:bundle];
}

+ (id)stackWithModelName:(NSString *)modelName {
    return [self SQLiteStackWithModelName:modelName];
}

+ (id)SQLiteStackWithModelName:(NSString *)modelName {
    NSBundle *bundle = [NSBundle mainBundle];
    return [self SQLiteStackWithModelName:modelName bundle:bundle];
}

+ (id)SQLiteStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle {
    NSURL *url = [self storeURLWithBundle:bundle modelName:modelName extension:@"sqlite"];
    return [self SQLiteStackWithModelName:modelName bundle:bundle URL:url];
}

+ (id)SQLiteStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle URL:(NSURL *)url {
    AddPersistentStoreBlockType block = ^NSPersistentStore *(NSPersistentStoreCoordinator *coordinator, NSError **error) {
        return [self addSQLitePersistentStoreToCoordinator:coordinator withStoreURL:url error:error];
    };
    return [[self alloc] initWithModelName:modelName bundle:bundle block:block];
}

+ (id)InMemoryStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle {
    AddPersistentStoreBlockType block = ^NSPersistentStore *(NSPersistentStoreCoordinator *coordinator, NSError **error) {
        return [self addInMemoryPersistentStoreToCoordinator:coordinator error:error];
    };
    return [[self alloc] initWithModelName:modelName bundle:bundle block:block];
}

+ (id)InMemoryStackWithModelName:(NSString *)modelName {
    NSBundle *bundle = [NSBundle mainBundle];
    AddPersistentStoreBlockType block = ^NSPersistentStore *(NSPersistentStoreCoordinator *coordinator, NSError **error) {
        return [self addInMemoryPersistentStoreToCoordinator:coordinator error:error];
    };
    return [[self alloc] initWithModelName:modelName bundle:bundle block:block];
}

- (NSURL *)modelLocation {
    return [self.bundle URLForResource:self.modelName withExtension:@"momd"];
}

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        self.managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:self.modelLocation];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        if (!self.managedObjectModel) {
            return nil;
        }

        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self
                .managedObjectModel];
        NSError *error = nil;
        if (!self.addPersistentStoreBlock(_persistentStoreCoordinator, &error)) {
            [self addError:error];
        }
    }
    return _persistentStoreCoordinator;
}

+ (NSPersistentStore *)addSQLitePersistentStoreToCoordinator:(NSPersistentStoreCoordinator *)coordinator
                                                withStoreURL:(NSURL *)storeURL error:(NSError **)error {

    NSURL *directoryURL = [storeURL URLByDeletingLastPathComponent];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    {
        if (![fileManager createDirectoryAtPath:[directoryURL path] withIntermediateDirectories:YES attributes:nil
                                          error:error]) {
            return nil;
        }
    }
    {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        if ([userDefaults boolForKey:PSACoreDataStackBackupWhenModelUpgradedUserDefaultsKey]) {
            NSError *compatibilityError = nil;
            BOOL result = [self isModelInPersistentStoreCoordinator:coordinator compatibleWithStoreAtURL:storeURL
                                                              error:&compatibilityError];
            if (!result) {
                [self backupStoreAtURL:storeURL];
            }            
        }
    }
    NSDictionary *options = @{
            NSMigratePersistentStoresAutomaticallyOption : @YES,
            NSInferMappingModelAutomaticallyOption : @YES
    };
    return [coordinator addPersistentStoreWithType:NSSQLiteStoreType
                                     configuration:nil URL:storeURL
                                           options:options
                                             error:error];
}

+ (BOOL)backupStoreAtURL:(NSURL *)storeURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDate *date = [NSDate date];

    const NSInteger retryAttempts = 10;
    for (NSUInteger i = 0; i < retryAttempts; i++) {
        NSURL *dstURL = [self backupURLForStoreURL:storeURL fromDate:date];
        NSError *copyError = nil;
        BOOL success = [fileManager copyItemAtURL:storeURL toURL:dstURL error:&copyError];
        if (success) {
            return YES;
        } else {
            // Should break unless error indicates that the file already exists.
            date = [date dateByAddingTimeInterval:1.0];
        }
    }
    return NO;
}

+ (NSURL *)backupURLForStoreURL:(NSURL *)storeURL fromDate:(NSDate *)date {
    NSURL *parentDirectoryURL = [storeURL URLByDeletingLastPathComponent];
    NSString *lastPathComponent = [storeURL lastPathComponent];
    NSString *fileName = [NSString stringWithFormat:@"%@-%@.%@", [lastPathComponent stringByDeletingPathExtension],
                                                    [self ISO8601DateTimeStringFromDate:date], [lastPathComponent pathExtension]];
    return [parentDirectoryURL URLByAppendingPathComponent:fileName];
}

+ (NSString *)ISO8601DateTimeStringFromDate:(NSDate *)date {
    return [[self ISO8601DateFormatter] stringFromDate:date];
}

+ (NSDateFormatter *)ISO8601DateFormatter {
    NSDateFormatter *result = [[NSDateFormatter alloc] init];
    [result setDateFormat:@"YYYYMMdd'T'hhmmss'Z'"];
    [result setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    return result;
}

+ (NSPersistentStore *)addInMemoryPersistentStoreToCoordinator:(NSPersistentStoreCoordinator *)coordinator
                                                         error:(NSError **)error {
    return [coordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:error];
}

+ (BOOL)isModelInPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
                   compatibleWithStoreAtURL:(NSURL *)storeURL
                                      error:(NSError **)error {
    NSDictionary *metadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                        URL:storeURL
                                                                                      error:error];
    if (metadata == nil) {
        return NO;
    }

    return [[coordinator managedObjectModel] isConfiguration:nil compatibleWithStoreMetadata:metadata];
}

- (void)addError:(NSError *)error {
    if (_errors) {
        self.errors = [self.errors arrayByAddingObject:error];
    } else {
        self.errors = @[error];
    }
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        if (!self.persistentStoreCoordinator) {
            return nil;
        }
        NSManagedObjectContext *result = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [result setPersistentStoreCoordinator:self.persistentStoreCoordinator];
        self.managedObjectContext = result;
    }
    return _managedObjectContext;
}

@end
