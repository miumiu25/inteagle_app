import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/models/discovered_device.dart';
import 'package:inteagle_app/router/routes.dart';
import 'package:tdesign_flutter/tdesign_flutter.dart';

class DeviceItem extends HookConsumerWidget {
  final DiscoveredDevice device;
  const DeviceItem({super.key, required this.device});

  // 是否手动添加

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    bool isManuallyAdded = device.id.startsWith('manual_');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
          onTap: () {
            AppRoute.deviceDetailPage.go(context);
            GoRouter.of(context).push("/device_detail/1");
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 12,
                  children: [
                    TDAvatar(
                      size: TDAvatarSize.medium,
                      type: TDAvatarType.customText,
                      text: 'A',
                    ),
                    if (isManuallyAdded)
                      const TDTag(
                        '手动添加',
                        isLight: true,
                        theme: TDTagTheme.warning,
                      ),
                    Expanded(
                      child: TDText(
                        '设备名称',
                        font: TDTheme.of(context).fontTitleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TDText(
                        '类型：视觉位移计',
                        font: TDTheme.of(context).fontBodyMedium,
                        textColor: TDTheme.of(context).fontGyColor2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: TDText(
                        '地址：192.168.1.150',
                        font: TDTheme.of(context).fontBodyMedium,
                        textColor: TDTheme.of(context).fontGyColor2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  ],
                ),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //   IconButton(
                      //   onPressed: () {
                      //     print('点击了保存');
                      //   },
                      //   tooltip: '保存',
                      //   splashRadius: 16,
                      //   padding: EdgeInsets.all(6),
                      //   constraints: const BoxConstraints(),
                      //   icon: Icon(TDIcons.save, size: 16),
                      // ),
                      IconButton(
                        onPressed: () {
                          GoRouter.of(context)
                              .push("/device_detail/${device.id}");
                        },
                        tooltip: '连接设备',
                        color: TDTheme.of(context).brandNormalColor,
                        icon: const Icon(TDIcons.map_connection, size: 18),
                      ),
                      IconButton(
                          icon: const Icon(TDIcons.delete, size: 18),
                          color: TDTheme.of(context).errorNormalColor,
                          tooltip: '删除设备',
                          onPressed: () => {
                                showGeneralDialog(
                                  context: context,
                                  pageBuilder: (BuildContext buildContext,
                                      Animation<double> animation,
                                      Animation<double> secondaryAnimation) {
                                    return TDAlertDialog(
                                      title: '删除',
                                      content: '请确认是否删除?',
                                      buttonStyle: TDDialogButtonStyle.text,
                                      rightBtn: TDDialogButtonOptions(
                                          title: '删除',
                                          action: () {
                                            print('确认删除');
                                            Navigator.of(buildContext).pop();
                                          }),
                                    );
                                  },
                                )
                              }),
                    ],
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
