//
//  UITests.m
//  UITests
//

#import <XCTest/XCTest.h>
#import "Workspace.h"

@interface UITests : XCTestCase
@end

@implementation UITests

- (void)setUp {
    self.continueAfterFailure = NO;
}

- (void)testWorkspaceRoundTripsVersionedMetadata {
    NSError *error = nil;
    Workspace *workspace = [Workspace workspaceWithName:@"  Personal  " rootName:@"default" error:&error];
    XCTAssertNotNil(workspace);
    XCTAssertNil(error);
    XCTAssertEqualObjects(workspace.name, @"Personal");
    XCTAssertEqualObjects(workspace.rootName, @"default");
    XCTAssertEqual(workspace.schemaVersion, 1);

    Workspace *decoded = [Workspace workspaceFromDictionary:workspace.dictionaryRepresentation error:&error];
    XCTAssertNotNil(decoded);
    XCTAssertNil(error);
    XCTAssertEqualObjects(decoded.identifier, workspace.identifier);
    XCTAssertEqualObjects(decoded.name, workspace.name);
    XCTAssertEqualObjects(decoded.rootName, workspace.rootName);
    XCTAssertEqualObjects(decoded.createdAt, workspace.createdAt);
}

- (void)testWorkspaceRejectsEmptyNamesAndUnsafeRootNames {
    NSError *error = nil;
    XCTAssertNil([Workspace workspaceWithName:@" \n " rootName:@"default" error:&error]);
    XCTAssertEqual(error.code, WorkspaceErrorInvalidName);

    error = nil;
    XCTAssertNil([Workspace workspaceWithName:@"Personal" rootName:@"../outside" error:&error]);
    XCTAssertEqual(error.code, WorkspaceErrorInvalidRootName);
}

- (void)testWorkspaceRejectsUnknownSchemaVersion {
    NSError *error = nil;
    Workspace *workspace = [Workspace workspaceWithName:@"Personal" rootName:@"default" error:&error];
    NSMutableDictionary *record = [workspace.dictionaryRepresentation mutableCopy];
    record[@"schemaVersion"] = @999;

    XCTAssertNil([Workspace workspaceFromDictionary:record error:&error]);
    XCTAssertEqual(error.code, WorkspaceErrorUnsupportedSchemaVersion);
}

- (void)testRenamePreservesIdentityRootAndCreationDate {
    NSError *error = nil;
    Workspace *workspace = [Workspace workspaceWithName:@"Personal" rootName:@"default" error:&error];
    NSDate *updatedAt = [NSDate dateWithTimeIntervalSince1970:1];
    Workspace *renamed = [workspace workspaceByRenamingTo:@"Work" updatedAt:updatedAt error:&error];

    XCTAssertNotNil(renamed);
    XCTAssertEqualObjects(renamed.identifier, workspace.identifier);
    XCTAssertEqualObjects(renamed.rootName, workspace.rootName);
    XCTAssertEqualObjects(renamed.createdAt, workspace.createdAt);
    XCTAssertEqualObjects(renamed.updatedAt, updatedAt);
    XCTAssertEqualObjects(renamed.name, @"Work");
}

- (void)testPersistedNamesMustAlreadyBeNormalized {
    NSError *error = nil;
    Workspace *workspace = [Workspace workspaceWithName:@"Personal" rootName:@"default" error:&error];
    NSMutableDictionary *record = [workspace.dictionaryRepresentation mutableCopy];
    record[@"name"] = @" Personal ";

    XCTAssertNil([Workspace workspaceFromDictionary:record error:&error]);
    XCTAssertEqual(error.code, WorkspaceErrorInvalidRecord);
}

@end
