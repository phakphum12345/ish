//
//  Workspace.h
//  iSH
//
//  A metadata-only value model for workspaces. It never owns filesystem roots.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString * const WorkspaceErrorDomain;

typedef NS_ERROR_ENUM(WorkspaceErrorDomain, WorkspaceErrorCode) {
    WorkspaceErrorInvalidName = 1,
    WorkspaceErrorInvalidRootName,
    WorkspaceErrorInvalidRecord,
    WorkspaceErrorUnsupportedSchemaVersion,
};

@interface Workspace : NSObject

@property (nonatomic, copy, readonly) NSUUID *identifier;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *rootName;
@property (nonatomic, copy, readonly) NSDate *createdAt;
@property (nonatomic, copy, readonly) NSDate *updatedAt;
@property (nonatomic, readonly) NSInteger schemaVersion;

/// Creates a new workspace record referencing an iSH root by name. The store must verify root existence.
/// This method does not create, rename, move, or delete the referenced root.
+ (nullable instancetype)workspaceWithName:(NSString *)name
                                  rootName:(NSString *)rootName
                                     error:(NSError **)error;

/// Reconstitutes a workspace from its versioned property-list/JSON dictionary.
+ (nullable instancetype)workspaceFromDictionary:(NSDictionary<NSString *, id> *)dictionary
                                           error:(NSError **)error;

/// Returns the stable, versioned representation suitable for persistence.
- (NSDictionary<NSString *, id> *)dictionaryRepresentation;

/// Returns a renamed value while preserving UUID, root reference, and creation date.
- (nullable Workspace *)workspaceByRenamingTo:(NSString *)name
                                    updatedAt:(NSDate *)updatedAt
                                        error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
