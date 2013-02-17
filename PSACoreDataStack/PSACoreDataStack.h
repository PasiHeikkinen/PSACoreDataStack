//
//  PSACoreDataStack.h
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

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PSACoreDataStack : NSObject

@property(nonatomic, readonly) NSString *modelName;
@property(nonatomic, readonly) NSBundle *bundle;
@property(nonatomic, readonly) NSManagedObjectModel *managedObjectModel;
@property(nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property(nonatomic, readonly) NSArray *errors;

+ (id)stackWithModelName:(NSString *)modelName;
+ (id)stackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle;

+ (id)SQLiteStackWithModelName:(NSString *)modelName;
+ (id)SQLiteStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle;
+ (id)SQLiteStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle URL:(NSURL *)url;

+ (id)InMemoryStackWithModelName:(NSString *)modelName;
+ (id)InMemoryStackWithModelName:(NSString *)modelName bundle:(NSBundle *)bundle;

@end
