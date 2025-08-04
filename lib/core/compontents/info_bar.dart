


import 'package:fluent_ui/fluent_ui.dart';
import 'package:saveforge/core/router/router.dart';

void showInfoBar(String title, String content, InfoBarSeverity severity,{
  Widget? action,
}){
  var context = AppRouter.navigatorKey.currentContext;
  if(context == null) return;
  // displayInfoBar(
  //   context,
  //   builder: (context, close) {
  //     return InfoBar(
  //       title: Text(title),
  //       content: Text(content),
  //       severity: severity,
  //       action: action??IconButton(
  //         icon: const Icon(FluentIcons.clear),
  //         onPressed: close,
  //       ),
  //     );
  //   },
  // );

}