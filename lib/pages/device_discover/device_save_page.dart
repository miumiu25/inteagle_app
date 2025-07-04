import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inteagle_app/l10n/generated/l10n.dart';

import 'package:tdesign_flutter/tdesign_flutter.dart';

class DeviceSavePage extends HookConsumerWidget {
  const DeviceSavePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final identifierController = useTextEditingController();
    final nameController = useTextEditingController();
    final ipController = useTextEditingController();
    final loading = useState(false);

    void submitForm() {
      if (formKey.currentState!.validate()) {
        // 表单验证通过
        final deviceIdentifier = identifierController.text.trim();
        final deviceName = nameController.text.trim();
        final ipAddress = ipController.text.trim();

        // 清空表单
        formKey.currentState!.reset();
        TDMessage.showMessage(
          context: context,
          content: '添加成功',
          theme: MessageTheme.success,
          duration: 3000,
        );
        GoRouter.of(context).pop();
      } else {
        TDToast.showText('设备ID/序列号不能为空', context: context);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(T.of(context).addDevice),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            spacing: 12.0,
            children: <Widget>[
              TextFormField(
                  autofocus: true,
                  controller: identifierController,
                  decoration: InputDecoration(
                    labelText: '设备ID/序列号 *',
                    hintText: '例如: SN12345678 或 ABC123',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '设备ID/序列号不能为空';
                    }
                    return null;
                  }),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '设备名称(可选)',
                  hintText: '自定义设备名称',
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              TextFormField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP地址(可选)',
                  hintText: '例如: 192.168.1.100',
                  prefixIcon: Icon(Icons.lan),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints.expand(height: 55.0),
                  child: FilledButton(
                    onPressed: submitForm,
                    child: const Text('添加'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
