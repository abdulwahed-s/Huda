#include "windows_notification_activator.h"

#include <NotificationActivationCallback.h>

#include <atomic>
#include <mutex>
#include <new>

namespace {

// {a8c22b55-049e-422f-b30f-863694de08c8}
constexpr CLSID kActivator = {
    0xa8c22b55, 0x049e, 0x422f, {0xb3, 0x0f, 0x86, 0x36, 0x94, 0xde, 0x08, 0xc8}};

std::mutex mutex;
std::optional<std::string> pending;
HWND target = nullptr;
DWORD cookie = 0;

std::string Utf8(LPCWSTR text) {
  if (!text || !*text) return {};
  const int size = WideCharToMultiByte(CP_UTF8, 0, text, -1, nullptr, 0, nullptr, nullptr);
  if (size <= 1) return {};
  std::string result(static_cast<size_t>(size - 1), '\0');
  WideCharToMultiByte(CP_UTF8, 0, text, -1, result.data(), size, nullptr, nullptr);
  return result;
}

class Activator final : public INotificationActivationCallback {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** object) override {
    if (!object) return E_POINTER;
    if (iid == IID_IUnknown || iid == __uuidof(INotificationActivationCallback)) {
      *object = static_cast<INotificationActivationCallback*>(this);
      AddRef();
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return ++references_; }
  ULONG STDMETHODCALLTYPE Release() override {
    const ULONG left = --references_;
    if (left == 0) delete this;
    return left;
  }
  // The arguments are the toast's launch attribute: Huda's payload.
  HRESULT STDMETHODCALLTYPE Activate(LPCWSTR, LPCWSTR arguments,
                                     const NOTIFICATION_USER_INPUT_DATA*,
                                     ULONG) override {
    HWND window;
    {
      std::lock_guard<std::mutex> lock(mutex);
      pending = Utf8(arguments);
      window = target;
    }
    if (window) PostMessageW(window, WindowsNotificationActivator::kMessage, 0, 0);
    return S_OK;
  }

 private:
  std::atomic<ULONG> references_{1};
};

// One static factory for the process lifetime.
class Factory final : public IClassFactory {
 public:
  HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** object) override {
    if (!object) return E_POINTER;
    if (iid == IID_IUnknown || iid == IID_IClassFactory) {
      *object = static_cast<IClassFactory*>(this);
      return S_OK;
    }
    *object = nullptr;
    return E_NOINTERFACE;
  }
  ULONG STDMETHODCALLTYPE AddRef() override { return 2; }
  ULONG STDMETHODCALLTYPE Release() override { return 1; }
  HRESULT STDMETHODCALLTYPE CreateInstance(IUnknown* outer, REFIID iid,
                                           void** object) override {
    if (!object) return E_POINTER;
    *object = nullptr;
    if (outer) return CLASS_E_NOAGGREGATION;
    auto* activator = new (std::nothrow) Activator();
    if (!activator) return E_OUTOFMEMORY;
    const HRESULT result = activator->QueryInterface(iid, object);
    activator->Release();
    return result;
  }
  HRESULT STDMETHODCALLTYPE LockServer(BOOL) override { return S_OK; }
};

Factory factory;

}  // namespace

namespace WindowsNotificationActivator {

bool Register() {
  if (cookie) return true;
  return SUCCEEDED(CoRegisterClassObject(kActivator, &factory, CLSCTX_LOCAL_SERVER,
                                         REGCLS_MULTIPLEUSE, &cookie));
}

void Unregister() {
  if (!cookie) return;
  CoRevokeClassObject(cookie);
  cookie = 0;
}

void SetWindow(HWND window) {
  bool post;
  {
    std::lock_guard<std::mutex> lock(mutex);
    target = window;
    post = window && pending.has_value();
  }
  if (post) PostMessageW(window, kMessage, 0, 0);
}

std::optional<std::string> TakePayload() {
  std::lock_guard<std::mutex> lock(mutex);
  auto payload = std::move(pending);
  pending.reset();
  return payload;
}

}  // namespace WindowsNotificationActivator
