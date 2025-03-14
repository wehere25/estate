
import 'package:flutter/material.dart';
import 'debug_logger.dart';

enum NavigationEventType {
  push,
  pop,
  replace,
  removeUntil,
  routeChange,
  providerAccess,
  providerError,
  routeOverride,
  routeGeneration,
  error,
}

class NavigationLogger {
  static bool enableNavLogs = true;
  static List<Map<String, dynamic>> _navigationHistory = [];
  static int _stackDepth = 0;
  
  // Log a navigation event
  static void log(NavigationEventType type, String message, {Object? data, StackTrace? stackTrace}) {
    if (!enableNavLogs) return;
    
    final timestamp = DateTime.now();
    final event = {
      'timestamp': timestamp,
      'type': type.toString(),
      'message': message,
      'data': data?.toString(),
      'stackDepth': _stackDepth,
    };
    
    _navigationHistory.add(event);
    
    // Update stack depth based on event type
    if (type == NavigationEventType.push) _stackDepth++;
    if (type == NavigationEventType.pop) _stackDepth = _stackDepth > 0 ? _stackDepth - 1 : 0;
    
    // Print to console with visual formatting
    final prefix = '🧭 NAV [${timestamp.hour}:${timestamp.minute}:${timestamp.second}.${timestamp.millisecond}]';
    final stackSpace = '  ' * _stackDepth;
    
    switch (type) {
      case NavigationEventType.push:
        debugPrint('$prefix $stackSpace➡️ PUSH: $message');
        break;
      case NavigationEventType.pop:
        debugPrint('$prefix $stackSpace⬅️ POP: $message');
        break;
      case NavigationEventType.replace:
        debugPrint('$prefix $stackSpace🔄 REPLACE: $message');
        break;
      case NavigationEventType.removeUntil:
        debugPrint('$prefix $stackSpace🏠 REMOVE UNTIL: $message');
        break;
      case NavigationEventType.routeChange:
        debugPrint('$prefix $stackSpace🛣️ ROUTE CHANGE: $message');
        break;
      case NavigationEventType.providerAccess:
        debugPrint('$prefix $stackSpace✅ PROVIDER: $message');
        break;
      case NavigationEventType.providerError:
        debugPrint('$prefix $stackSpace❌ PROVIDER ERROR: $message');
        if (data != null) debugPrint('$prefix $stackSpace  Error: ${data.toString()}');
        break;
      case NavigationEventType.routeOverride:
        debugPrint('$prefix $stackSpace⚠️ ROUTE OVERRIDE: $message');
        break;
      case NavigationEventType.routeGeneration:
        debugPrint('$prefix $stackSpace🏗️ ROUTE GENERATION: $message');
        break;
      case NavigationEventType.error:
        debugPrint('$prefix $stackSpace🔥 ERROR: $message');
        if (data != null) debugPrint('$prefix $stackSpace  Details: ${data.toString()}');
        if (stackTrace != null) debugPrint('$prefix $stackSpace  Stack: $stackTrace');
        break;
    }
  }
  
  // Get a history of navigation events for analysis
  static List<Map<String, dynamic>> getNavigationHistory() {
    return List.from(_navigationHistory);
  }
  
  // Clear the navigation history
  static void clearNavigationHistory() {
    _navigationHistory.clear();
    _stackDepth = 0;
  }
  
  // Print the current widget tree (call this when an error occurs)
  static void dumpWidgetTree(BuildContext context) {
    debugPrint('\n🌲 WIDGET TREE DUMP 🌲');
    debugPrint('This is an approximation of the widget tree:');
    
    // Get the Element for the context
    final Element? element = context as Element?;
    if (element == null) {
      debugPrint('  Context is not an Element');
      return;
    }
    
    // Function to recursively print the widget tree
    void printWidgetTree(Element element, int depth) {
      final Widget widget = element.widget;
      final String indent = '  ' * depth;
      final String widgetName = widget.runtimeType.toString();
      
      debugPrint('$indent$widgetName');
      
      // Special handling for providers
      if (widgetName.contains('Provider') || 
          widgetName.contains('ChangeNotifier') || 
          widgetName.contains('Consumer')) {
        debugPrint('$indent  ⚠️ Provider found: $widgetName');
      }
      
      element.visitChildren((child) {
        printWidgetTree(child, depth + 1);
      });
    }
    
    // Start the recursive traversal
    debugPrint('\n');
    printWidgetTree(element, 0);
    debugPrint('\n🌲 END WIDGET TREE DUMP 🌲\n');
  }
}
