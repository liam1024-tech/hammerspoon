#import "SentryQueueableRequestManager.h"
#import "SentryRequestOperation.h"
#import "SentryLog.h"

NS_ASSUME_NONNULL_BEGIN

@interface SentryQueueableRequestManager ()

@property(nonatomic, strong) NSOperationQueue *queue;
@property(nonatomic, strong) NSURLSession *session;

@end

@implementation SentryQueueableRequestManager

- (instancetype)initWithSession:(NSURLSession *)session {
    self = [super init];
    if (self) {
        self.session = session;
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.name = @"io.sentry.QueueableRequestManager.OperationQueue";
        self.queue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (BOOL)isReady {
    // We always have at least one operation in the queue when calling this
    return self.queue.operationCount <= 1;
}

- (void)addRequest:(NSURLRequest *)request completionHandler:(_Nullable SentryRequestOperationFinished)completionHandler {
    SentryRequestOperation *operation =
    [[SentryRequestOperation alloc]
     initWithSession:self.session
     request:request
     completionHandler:^(NSHTTPURLResponse *_Nullable response, NSError *_Nullable error) {
        [SentryLog logWithMessage:[NSString stringWithFormat:@"Queued requests: %@", @(self.queue.operationCount - 1)] andLevel:kSentryLogLevelDebug];
        if (completionHandler) {
            completionHandler(response, error);
        }
    }];
    [self.queue addOperation:operation];
}

- (void)cancelAllOperations {
    [self.queue cancelAllOperations];
}

@end

NS_ASSUME_NONNULL_END
