
#import <bdn/mac/ScrollViewCore.hh>

#import <bdn/mac/util.hh>

#import <Cocoa/Cocoa.h>

/** NSView implementation that is used internally by bdn::mac::ScrollViewCore.

 Sets the flipped property so that the coordinate system has its origin in the
 top left, rather than the bottom left.
 */
@interface BdnMacScrollView_ : NSScrollView

@end

@implementation BdnMacScrollView_

- (BOOL)isFlipped { return YES; }

@end

@interface BdnMacScrollViewContentViewParent_ : NSView

@end

@implementation BdnMacScrollViewContentViewParent_

- (BOOL)isFlipped { return YES; }

@end

@interface BdnMacScrollViewCoreEventForwarder_ : NSObject

@property std::weak_ptr<bdn::ui::mac::ScrollViewCore> scrollViewCore;

@end

@implementation BdnMacScrollViewCoreEventForwarder_

- (void)contentViewBoundsDidChange
{
    if (auto scrollViewCore = _scrollViewCore.lock()) {
        scrollViewCore->_contentViewBoundsDidChange();
    }
}

@end

namespace bdn::ui::detail
{
    CORE_REGISTER(ScrollView, bdn::ui::mac::ScrollViewCore, ScrollView)
}

namespace bdn::ui::mac
{
    ScrollViewCore::ScrollViewCore(const std::shared_ptr<ViewCoreFactory> &viewCoreFactory)
        : mac::ViewCore(viewCoreFactory, _createScrollView())
    {}

    ScrollViewCore::~ScrollViewCore()
    {
        [[NSNotificationCenter defaultCenter] removeObserver:_eventForwarder
                                                        name:NSViewBoundsDidChangeNotification
                                                      object:_nsScrollView.contentView];
    }

    void ScrollViewCore::init()
    {
        mac::ViewCore::init();

        _nsScrollView = (NSScrollView *)nsView();

        // we add a custom view as the document view so that we have better
        // control over the positioning of the content view
        _nsContentViewParent = [[BdnMacScrollViewContentViewParent_ alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];

        _nsScrollView.documentView = _nsContentViewParent;

        _nsScrollView.autohidesScrollers = YES;

        _nsScrollView.contentView.postsBoundsChangedNotifications = YES;

        BdnMacScrollViewCoreEventForwarder_ *eventForwarder = [BdnMacScrollViewCoreEventForwarder_ alloc];
        [eventForwarder setScrollViewCore:shared_from_this<ScrollViewCore>()];
        _eventForwarder = eventForwarder;

        [[NSNotificationCenter defaultCenter] addObserver:eventForwarder
                                                 selector:@selector(contentViewBoundsDidChange)
                                                     name:NSViewBoundsDidChangeNotification
                                                   object:_nsScrollView.contentView];

        horizontalScrollingEnabled.onChange() +=
            [=](auto &property) { _nsScrollView.hasHorizontalScroller = property.get() ? YES : NO; };
        verticalScrollingEnabled.onChange() +=
            [=](auto &property) { _nsScrollView.hasVerticalScroller = property.get() ? YES : NO; };

        contentView.onChange() += [=](auto &property) { updateContent(property.get()); };
    }

    NSScrollView *ScrollViewCore::_createScrollView()
    {
        NSScrollView *scrollView = [[BdnMacScrollView_ alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];

        return scrollView;
    }

    void ScrollViewCore::updateContent(const std::shared_ptr<View> &content)
    {
        for (id oldViewObject in _nsScrollView.documentView.subviews) {
            auto oldView = (NSView *)oldViewObject;
            [oldView removeFromSuperview];
        }
        if (content) {
            if (auto childCore = content->core<ViewCore>()) {
                _nsScrollView.documentView = childCore->nsView();
            } else {
                throw std::runtime_error("Cannot add this type of View");
            }
        }
    }

    void ScrollViewCore::scrollClientRectToVisible(const Rect &clientRect)
    {
        if (_nsScrollView.contentView != nil) {
            [_nsScrollView.contentView scrollRectToVisible:rectToMacRect(clientRect, -1)];
        }
    }

    void ScrollViewCore::_contentViewBoundsDidChange()
    {
        // when the view scrolls then the bounds of the content view (not
        // the document view) change.
        updateVisibleClientRect();
    }

    void ScrollViewCore::updateVisibleClientRect()
    {
        visibleClientRect = macRectToRect(_nsScrollView.documentVisibleRect, -1);
    }
}
