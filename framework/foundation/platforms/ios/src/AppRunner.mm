
#import <bdn/foundationkit/stringUtil.hh>
#import <bdn/ios/AppRunner.hh>

#import <bdn/foundationkit/MainDispatcher.hh>
#import <bdn/foundationkit/objectUtil.hh>

#include <bdn/entry.h>

#include <bdn/ApplicationController.h>

#import <UIKit/UIKit.h>

@interface BdnIosAppDelegate_ : UIResponder <UIApplicationDelegate>

@property(strong, nonatomic) UIWindow *window;

// static method
+ (void)setStaticAppRunner:(bdn::ios::AppRunner *)runner;

@end

@implementation BdnIosAppDelegate_

static bdn::ios::AppRunner *_staticAppRunner;
bdn::ios::AppRunner *_appRunner;

- (id)init
{
    self = [super init];
    if (self != nullptr) {
        _appRunner = _staticAppRunner;
    }
    return self;
}

+ (void)setStaticAppRunner:(bdn::ios::AppRunner *)runner { _staticAppRunner = runner; }

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return _appRunner->_applicationWillFinishLaunching(launchOptions) ? YES : NO;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return _appRunner->_applicationDidFinishLaunching(launchOptions) ? YES : NO;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    _appRunner->_applicationDidBecomeActive(application);
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    _appRunner->_applicationWillResignActive(application);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    _appRunner->_applicationDidEnterBackground(application);
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    _appRunner->_applicationWillEnterForeground(application);
}

- (void)applicationWillTerminate:(UIApplication *)application { _appRunner->_applicationWillTerminate(application); }

@end

namespace bdn::ios
{
    AppLaunchInfo AppRunner::_makeLaunchInfo(int argCount, char *args[])
    {
        AppLaunchInfo launchInfo;

        std::vector<String> argStrings;
        argStrings.reserve(argCount);
        for (int i = 0; i < argCount; i++) {
            // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-pointer-arithmetic)
            argStrings.emplace_back(args[i]);
        }
        if (argCount == 0) {
            argStrings.emplace_back(""); // always add the first entry.
        }

        launchInfo.setArguments(argStrings);

        return launchInfo;
    }

    AppRunner::AppRunner(const std::function<std::shared_ptr<ApplicationController>()> &appControllerCreator,
                         int argCount, char *args[])
        : AppRunnerBase(appControllerCreator, _makeLaunchInfo(argCount, args))
    {
        _mainDispatcher = std::make_shared<bdn::fk::MainDispatcher>();
    }

    bool AppRunner::isCommandLineApp() const
    {
        // iOS does not support commandline apps.
        return false;
    }

    int AppRunner::entry(int argCount, char *args[])
    {
        [BdnIosAppDelegate_ setStaticAppRunner:this];

        @autoreleasepool {
            return UIApplicationMain(argCount, args, nil, NSStringFromClass([BdnIosAppDelegate_ class]));
        }
    }

    void AppRunner::openURL(const String &url)
    {
        if (auto app = [UIApplication sharedApplication]) {
            if (auto nsUrl = [NSURL URLWithString:fk::stringToNSString(url)]) {
                [app openURL:nsUrl options:@{} completionHandler:nil];
            }
        }
    }

    bool AppRunner::_applicationWillFinishLaunching(NSDictionary *launchOptions)
    {
        bdn::platformEntryWrapper(
            [&]() {
                prepareLaunch();
                beginLaunch();
            },
            false);

        return true;
    }

    bool AppRunner::_applicationDidFinishLaunching(NSDictionary *launchOptions)
    {
        bdn::platformEntryWrapper([&]() { finishLaunch(); }, false);

        return true;
    }

    void AppRunner::_applicationDidBecomeActive(UIApplication *application)
    {
        bdn::platformEntryWrapper([&]() { ApplicationController::get()->onActivate(); }, false);
    }

    void AppRunner::_applicationWillResignActive(UIApplication *application)
    {
        bdn::platformEntryWrapper([&]() { ApplicationController::get()->onDeactivate(); }, false);
    }

    void AppRunner::_applicationDidEnterBackground(UIApplication *application) {}

    void AppRunner::_applicationWillEnterForeground(UIApplication *application) {}

    void AppRunner::_applicationWillTerminate(UIApplication *application)
    {
        bdn::platformEntryWrapper([&]() { ApplicationController::get()->onTerminate(); }, false);
    }

    void AppRunner::initiateExitIfPossible(int exitCode)
    {
        // ios apps cannot close themselves. So we do nothing here.
    }

    void AppRunner::disposeMainDispatcher()
    {
        std::dynamic_pointer_cast<bdn::fk::MainDispatcher>(_mainDispatcher)->dispose();
    }
}
