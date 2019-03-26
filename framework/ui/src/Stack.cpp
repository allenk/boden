#include <bdn/Stack.h>
#include <bdn/StackCore.h>

#include <utility>

namespace bdn
{
    namespace detail
    {
        VIEW_CORE_REGISTRY_IMPLEMENTATION(Stack)
    }

    Stack::Stack(std::shared_ptr<ViewCoreFactory> viewCoreFactory) : View(std::move(viewCoreFactory))
    {
        detail::VIEW_CORE_REGISTER(Stack, View::viewCoreFactory());
    }

    Stack::~Stack() = default;

    void Stack::pushView(std::shared_ptr<View> view, String title)
    {
        if (auto core = std::dynamic_pointer_cast<StackCore>(viewCore())) {
            core->pushView(std::move(view), std::move(title));
        }
    }

    void Stack::popView()
    {
        if (auto stackCore = core<StackCore>()) {
            stackCore->popView();
        }
    }

    std::list<std::shared_ptr<View>> Stack::childViews()
    {
        if (auto stackCore = core<StackCore>()) {
            return stackCore->childViews();
        }
        return {};
    }

    void Stack::bindViewCore() { View::bindViewCore(); }
}
