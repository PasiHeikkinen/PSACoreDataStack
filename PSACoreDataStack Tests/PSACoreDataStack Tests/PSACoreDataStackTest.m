//
//  PSACoreDataStackTest.m
//  PSACoreDataStackTest
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

#import "PSACoreDataStackTest.h"
#import "PSACoreDataStack.h"

@interface PSACoreDataStackTest ()
@property(nonatomic, copy) NSString *temporaryDirectory;
@property(nonatomic, strong) PSACoreDataStack *stack;
@end

@implementation PSACoreDataStackTest

- (void)setUp
{
    [super setUp];
    self.temporaryDirectory = [PSACoreDataStackTest createTemporaryDirectory];
    NSBundle *bundle = [NSBundle bundleForClass:[PSACoreDataStackTest class]];
    PSACoreDataStack *stack = [PSACoreDataStack stackWithModelName:@"TestModel" bundle:bundle storeURL:[self temporaryStoreURL]];
    self.stack = stack; 
}

- (void)tearDown
{
    self.stack = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];

    {
        NSError *error = nil;
        if (![fileManager removeItemAtPath:self.temporaryDirectory error:&error]) {
            NSLog(@"Failed to remove temporary directory: %@", [error description]);
        }
    }

    [super tearDown];
}

- (void)testStack
{
    PSACoreDataStack *stack = self.stack;

    STAssertEqualObjects(@"TestModel", stack.modelName, nil);
    STAssertNotNil(stack.modelLocation, nil);

    NSManagedObjectModel *model = stack.managedObjectModel;
    STAssertNotNil(model, nil);

    NSDictionary *entities = [model entitiesByName];
    STAssertNotNil(entities[@"TestEntity"], nil);

    NSManagedObjectContext *managedObjectContext = stack.managedObjectContext;
    STAssertNotNil(managedObjectContext, nil);

    NSEntityDescription *entityDescription = [NSEntityDescription entityForName:@"TestEntity" inManagedObjectContext:managedObjectContext];
    STAssertNotNil(entityDescription, nil);
}

- (void)testManagedObjectContext {
    STAssertNotNil(self.stack.managedObjectContext, nil);
}

- (NSURL *)temporaryStoreURL {
    NSString *storeFilePath = [self.temporaryDirectory stringByAppendingPathComponent:@"TestModel.sqlite"];
    return [NSURL fileURLWithPath:storeFilePath];
}

+ (NSString*) createTemporaryDirectory {
    // Based on http://www.cocoawithlove.com/2009/07/temporary-files-and-folders-in-cocoa.html
    NSString *s = [NSString stringWithFormat:@"%@.XXXXXX", [[NSBundle bundleForClass:[self class]] bundleIdentifier]];
    NSString *tempDirectoryTemplate =
            [NSTemporaryDirectory() stringByAppendingPathComponent:s];
    const char *tempDirectoryTemplateCString =
        [tempDirectoryTemplate fileSystemRepresentation];
    char *tempDirectoryNameCString =
        (char *)malloc(strlen(tempDirectoryTemplateCString) + 1);
    strcpy(tempDirectoryNameCString, tempDirectoryTemplateCString);

    NSString *tempDirectoryPath = nil;

    char *result = mkdtemp(tempDirectoryNameCString);
    if (result) {
        tempDirectoryPath= [[NSFileManager defaultManager]
                stringWithFileSystemRepresentation:tempDirectoryNameCString
                                            length:strlen(result)];
    }
    free(tempDirectoryNameCString);
    return tempDirectoryPath;
}

@end
