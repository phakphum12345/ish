//
//  Workspace.m
//  iSH
//

#import "Workspace.h"

NSString * const WorkspaceErrorDomain = @"org.ish.Workspace";

static const NSInteger WorkspaceCurrentSchemaVersion = 1;
static NSString * const WorkspaceKindRoot = @"root";

static NSError *WorkspaceMakeError(WorkspaceErrorCode code, NSString *message) {
    return [NSError errorWithDomain:WorkspaceErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

static NSString * _Nullable WorkspaceValidatedName(NSString *name, NSError **error) {
    if (![name isKindOfClass:NSString.class]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidName, @"Workspace name must be text.");
        return nil;
    }

    NSString *normalized = [name stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (normalized.length == 0 ||
        [normalized rangeOfCharacterFromSet:NSCharacterSet.controlCharacterSet].location != NSNotFound) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidName, @"Workspace name cannot be empty or contain control characters.");
        return nil;
    }
    return normalized;
}

static NSString *WorkspaceISO8601StringFromDate(NSDate *date) {
    NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    return [formatter stringFromDate:date];
}

static NSDate * _Nullable WorkspaceDateFromISO8601String(NSString *value) {
    NSISO8601DateFormatter *formatter = [NSISO8601DateFormatter new];
    formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime | NSISO8601DateFormatWithFractionalSeconds;
    NSDate *date = [formatter dateFromString:value];
    if (!date) {
        formatter.formatOptions = NSISO8601DateFormatWithInternetDateTime;
        date = [formatter dateFromString:value];
    }
    return date;
}

static NSString * _Nullable WorkspaceValidatedRootName(NSString *rootName, NSError **error) {
    if (![rootName isKindOfClass:NSString.class] ||
        rootName.length == 0 ||
        [rootName isEqualToString:@"."] ||
        [rootName isEqualToString:@".."] ||
        [rootName containsString:@"/"]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidRootName, @"Workspace must reference a valid existing root name.");
        return nil;
    }
    return rootName;
}

@interface Workspace ()
@property (nonatomic, copy, readwrite) NSUUID *identifier;
@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSString *rootName;
@property (nonatomic, copy, readwrite) NSDate *createdAt;
@property (nonatomic, copy, readwrite) NSDate *updatedAt;
@property (nonatomic, readwrite) NSInteger schemaVersion;

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                               name:(NSString *)name
                           rootName:(NSString *)rootName
                          createdAt:(NSDate *)createdAt
                          updatedAt:(NSDate *)updatedAt;
@end

@implementation Workspace

- (instancetype)initWithIdentifier:(NSUUID *)identifier
                               name:(NSString *)name
                           rootName:(NSString *)rootName
                          createdAt:(NSDate *)createdAt
                          updatedAt:(NSDate *)updatedAt {
    self = [super init];
    if (self) {
        _identifier = [identifier copy];
        _name = [name copy];
        _rootName = [rootName copy];
        _createdAt = [createdAt copy];
        _updatedAt = [updatedAt copy];
        _schemaVersion = WorkspaceCurrentSchemaVersion;
    }
    return self;
}

+ (nullable instancetype)workspaceWithName:(NSString *)name
                                  rootName:(NSString *)rootName
                                     error:(NSError **)error {
    NSString *validatedName = WorkspaceValidatedName(name, error);
    if (!validatedName) return nil;

    NSString *validatedRootName = WorkspaceValidatedRootName(rootName, error);
    if (!validatedRootName) return nil;

    NSDate *now = [NSDate date];
    return [[self alloc] initWithIdentifier:[NSUUID UUID]
                                       name:validatedName
                                   rootName:validatedRootName
                                  createdAt:now
                                  updatedAt:now];
}

+ (nullable instancetype)workspaceFromDictionary:(NSDictionary<NSString *,id> *)dictionary
                                           error:(NSError **)error {
    if (![dictionary isKindOfClass:NSDictionary.class]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidRecord, @"Workspace record must be a dictionary.");
        return nil;
    }

    id version = dictionary[@"schemaVersion"];
    if (![version isKindOfClass:NSNumber.class]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidRecord, @"Workspace schema version is missing or invalid.");
        return nil;
    }
    if ([version integerValue] != WorkspaceCurrentSchemaVersion) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorUnsupportedSchemaVersion, @"Workspace schema version is not supported.");
        return nil;
    }

    id identifierValue = dictionary[@"id"];
    id nameValue = dictionary[@"name"];
    id kindValue = dictionary[@"kind"];
    id rootValue = dictionary[@"rootName"];
    id createdValue = dictionary[@"createdAt"];
    id updatedValue = dictionary[@"updatedAt"];

    if (![identifierValue isKindOfClass:NSString.class] ||
        ![nameValue isKindOfClass:NSString.class] ||
        ![kindValue isKindOfClass:NSString.class] ||
        ![rootValue isKindOfClass:NSString.class] ||
        ![createdValue isKindOfClass:NSString.class] ||
        ![updatedValue isKindOfClass:NSString.class] ||
        ![kindValue isEqualToString:WorkspaceKindRoot]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidRecord, @"Workspace record contains missing or invalid fields.");
        return nil;
    }

    NSUUID *identifier = [[NSUUID alloc] initWithUUIDString:identifierValue];
    NSDate *createdAt = WorkspaceDateFromISO8601String(createdValue);
    NSDate *updatedAt = WorkspaceDateFromISO8601String(updatedValue);
    NSError *validationError = nil;
    NSString *validatedName = WorkspaceValidatedName(nameValue, &validationError);
    NSString *validatedRootName = WorkspaceValidatedRootName(rootValue, &validationError);
    if (!identifier || !createdAt || !updatedAt || !validatedName || !validatedRootName ||
        ![validatedName isEqualToString:nameValue] ||
        ![validatedRootName isEqualToString:rootValue]) {
        if (error) *error = validationError ?: WorkspaceMakeError(WorkspaceErrorInvalidRecord, @"Workspace record is not canonical.");
        return nil;
    }

    return [[self alloc] initWithIdentifier:identifier
                                       name:validatedName
                                   rootName:validatedRootName
                                  createdAt:createdAt
                                  updatedAt:updatedAt];
}

- (NSDictionary<NSString *,id> *)dictionaryRepresentation {
    return @{
        @"schemaVersion": @(self.schemaVersion),
        @"id": self.identifier.UUIDString,
        @"name": self.name,
        @"kind": WorkspaceKindRoot,
        @"rootName": self.rootName,
        @"createdAt": WorkspaceISO8601StringFromDate(self.createdAt),
        @"updatedAt": WorkspaceISO8601StringFromDate(self.updatedAt),
    };
}

- (nullable Workspace *)workspaceByRenamingTo:(NSString *)name
                                    updatedAt:(NSDate *)updatedAt
                                        error:(NSError **)error {
    NSString *validatedName = WorkspaceValidatedName(name, error);
    if (!validatedName) return nil;
    if (![updatedAt isKindOfClass:NSDate.class]) {
        if (error) *error = WorkspaceMakeError(WorkspaceErrorInvalidRecord, @"Updated date must be valid.");
        return nil;
    }

    return [[Workspace alloc] initWithIdentifier:self.identifier
                                            name:validatedName
                                        rootName:self.rootName
                                       createdAt:self.createdAt
                                       updatedAt:updatedAt];
}

@end
