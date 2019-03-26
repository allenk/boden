#include <bdn/UIUtil.h>
#include <bdn/ViewCoreFactory.h>
#include <bdn/WebView.h>
#include <bdn/WebViewCore.h>

namespace bdn
{
    namespace webview::detail
    {
        VIEW_CORE_REGISTRY_IMPLEMENTATION(WebView)
    }

    WebView::WebView(std::shared_ptr<ViewCoreFactory> viewCoreFactory) : View(std::move(viewCoreFactory))
    {
        webview::detail::VIEW_CORE_REGISTER(WebView, View::viewCoreFactory());

        registerCoreCreatingProperties(this, &url);
        url.onChange() += [this](auto) { loadURL(url); };
    }

    void WebView::loadURL(const String &url)
    {
        auto webCore = core<WebViewCore>();
        webCore->loadURL(url);
    }

    String WebView::viewCoreTypeName() const { return String(static_cast<const char *>(coreTypeName)); }

    void WebView::bindViewCore()
    {
        View::bindViewCore();

        auto webViewCore = core<WebViewCore>();
        webViewCore->redirectHandler.bind(redirectHandler, BindMode::unidirectional);
        webViewCore->userAgent.bind(userAgent, BindMode::unidirectional);
    }
}
