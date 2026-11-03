import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Debug web builds: ask the App Check JS SDK for a debug token (printed in the
/// browser console, to be registered in the Firebase console). Must run before
/// `activate`.
void enableWebAppCheckDebugToken() {
  globalContext.setProperty('FIREBASE_APPCHECK_DEBUG_TOKEN'.toJS, true.toJS);
}
