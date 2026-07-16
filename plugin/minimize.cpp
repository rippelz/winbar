// hypr-minimize — emit IPC "minimized" when a client requests minimize
// (titlebar button). Only while windows-mode is active
// (~/.local/state/winmode/on). winbar-dock listens and moves the window
// to special:minimized.
//
// Games (e.g. Geometry Dash) often request minimize on focus-out. We only
// forward the request when the window is still the active one — that matches
// a real titlebar minimize click / Super+M, not "I lost focus, hide me".
//
// Build:  make -C ~/.local/src/hypr-minimize
// Load:   hyprctl plugin load ~/.local/lib/hypr-minimize.so

#include <cstdlib>
#include <filesystem>
#include <format>
#include <string>
#include <unistd.h>

#include <hyprland/src/plugins/PluginAPI.hpp>
#include <hyprland/src/Compositor.hpp>
#include <hyprland/src/desktop/view/Window.hpp>
#include <hyprland/src/managers/EventManager.hpp>
#include <hyprland/src/protocols/XDGShell.hpp>
#include <hyprland/src/xwayland/XSurface.hpp>

namespace fs = std::filesystem;
using Window = Desktop::View::CWindow;

inline HANDLE         PHANDLE = nullptr;
static CFunctionHook* g_pHook = nullptr;

using origOnUpdateState = void (*)(Window*);

static bool winmodeActive() {
    const char* home = getenv("HOME");
    if (!home)
        return false;
    return fs::exists(fs::path(home) / ".local/state/winmode/on");
}

static bool wantsMinimize(Window* w) {
    if (!w)
        return false;
    if (!w->m_isX11) {
        auto xdg = w->m_xdgSurface.lock();
        if (xdg && xdg->m_toplevel)
            return xdg->m_toplevel->m_state.requestsMinimize.value_or(false);
    } else {
        auto xw = w->m_xwaylandSurface.lock();
        if (xw)
            return xw->m_state.requestsMinimize.value_or(false);
    }
    return false;
}

static void hkOnUpdateState(Window* thisptr) {
    const bool minimize = wantsMinimize(thisptr);

    // original handler (maximize / fullscreen); ignores minimize
    ((origOnUpdateState)g_pHook->m_original)(thisptr);

    if (!minimize || !winmodeActive() || !thisptr)
        return;

    // Ignore unfocused minimize requests (focus-loss games).
    const auto self = thisptr->m_self.lock();
    if (!self || !g_pCompositor || !g_pCompositor->isWindowActive(self))
        return;

    // winbar-dock listens for minimized>>addr,1
    g_pEventManager->postEvent(SHyprIPCEvent{
        .event = "minimized",
        .data  = std::format("{:x},1", reinterpret_cast<uintptr_t>(thisptr)),
    });
}

APICALL EXPORT std::string PLUGIN_API_VERSION() {
    return HYPRLAND_API_VERSION;
}

APICALL EXPORT PLUGIN_DESCRIPTION_INFO PLUGIN_INIT(HANDLE handle) {
    PHANDLE = handle;

    const auto matches = HyprlandAPI::findFunctionsByName(PHANDLE, "onUpdateState");
    void*      target  = nullptr;
    for (const auto& m : matches) {
        // CWindow::onUpdateState
        if (m.demangled.find("CWindow") != std::string::npos &&
            m.demangled.find("onUpdateState") != std::string::npos) {
            target = m.address;
            break;
        }
    }
    if (!target && !matches.empty())
        target = matches[0].address;

    if (target) {
        g_pHook = HyprlandAPI::createFunctionHook(PHANDLE, target,
                                                  (void*)&hkOnUpdateState);
        if (g_pHook)
            g_pHook->hook();
    }

    return {"hypr-minimize",
            "Forward titlebar minimize requests as IPC while in winmode",
            "beebit", "0.1"};
}

APICALL EXPORT void PLUGIN_EXIT() {
    if (g_pHook) {
        HyprlandAPI::removeFunctionHook(PHANDLE, g_pHook);
        g_pHook = nullptr;
    }
}
