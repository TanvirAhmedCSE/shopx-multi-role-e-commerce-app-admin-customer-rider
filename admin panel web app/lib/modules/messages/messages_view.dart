import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../app/app_colors.dart';
import '../../data/services/firestore_service.dart';
import '../../data/services/cloudinary_service.dart';
import 'messages_controller.dart';

class MessagesView extends StatelessWidget {
  const MessagesView({super.key});

  static const _breakpoint = 700.0;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.isRegistered<MessagesController>()
        ? Get.find<MessagesController>()
        : Get.put(MessagesController());

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _breakpoint;

        if (isWide) {
          return Row(
            children: [
              _ConversationList(
                ctrl: ctrl,
                width: 320,
                onSelect: ctrl.selectConversation,
              ),
              Container(width: 1, color: AppColors.border),
              Expanded(
                child: Obx(
                  () => ctrl.selectedUid.value == null
                      ? const Center(
                          child: Text(
                            'Select a conversation',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : _ConversationPanel(
                          key: ValueKey(ctrl.selectedUid.value),
                          uid: ctrl.selectedUid.value!,
                          name: ctrl.nameFor(ctrl.selectedUid.value!),
                          email: ctrl.emailFor(ctrl.selectedUid.value!),
                        ),
                ),
              ),
            ],
          );
        }

        return _ConversationList(
          ctrl: ctrl,
          width: double.infinity,
          onSelect: (uid) {
            ctrl.selectConversation(uid);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ConversationScreen(
                  uid: uid,
                  name: ctrl.nameFor(uid),
                  email: ctrl.emailFor(uid),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ConversationList extends StatelessWidget {
  final MessagesController ctrl;
  final double width;
  final void Function(String uid) onSelect;
  const _ConversationList({
    required this.ctrl,
    required this.width,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 16),
            child: Text(
              'Messages',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: TextField(
              onChanged: (v) => ctrl.searchQuery.value = v,
              decoration: InputDecoration(
                hintText: 'Search by name or email',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final query = ctrl.searchQuery.value.trim().toLowerCase();
              final names = ctrl.customerNames;
              final emails = ctrl.customerEmails;
              final all = ctrl.conversations;
              final list = query.isEmpty
                  ? all
                  : all.where((c) {
                      final name = (names[c.uid] ?? '').toLowerCase();
                      final email = (emails[c.uid] ?? '').toLowerCase();
                      return name.contains(query) || email.contains(query);
                    }).toList();
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    query.isEmpty
                        ? 'No conversations yet'
                        : 'No conversations match "${ctrl.searchQuery.value}"',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.border),
                itemBuilder: (_, i) {
                  final c = list[i];
                  return Obx(() {
                    final selected = ctrl.selectedUid.value == c.uid;
                    final unread = c.unreadForAdmin;
                    final isUnread = unread > 0;
                    final preview = unread <= 1
                        ? c.lastMessage
                        : '${unread > 99 ? '99+' : unread} new messages';
                    final email = ctrl.emailFor(c.uid);
                    final isImageMsg =
                        c.lastMessageType == 'image' && unread <= 1;
                    return ListTile(
                      selected: selected,
                      selectedTileColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      title: Text(
                        ctrl.nameFor(c.uid),
                        style: TextStyle(
                          fontWeight: isUnread
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isUnread
                              ? AppColors.error
                              : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty)
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          const SizedBox(height: 7),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isImageMsg) ...[
                                Icon(
                                  Icons.image_outlined,
                                  size: 14,
                                  color: isUnread
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(
                                  preview,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isUnread
                                        ? FontWeight.w700
                                        : FontWeight.normal,
                                    color: isUnread ? AppColors.error : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Text(
                        _formatTime(c.lastTime),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isUnread
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: isUnread
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                      onTap: () => onSelect(c.uid),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// Full-screen wrapper used only in the narrow (single-pane) layout, so the
// conversation panel gets an AppBar + back button instead of living inline.
class _ConversationScreen extends StatelessWidget {
  final String uid;
  final String name;
  final String email;
  const _ConversationScreen({
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const BackButton(), title: Text(name)),
      body: _ConversationPanel(uid: uid, name: name, email: email),
    );
  }
}

class _ConversationPanel extends StatefulWidget {
  final String uid;
  final String name;
  final String email;
  const _ConversationPanel({
    super.key,
    required this.uid,
    required this.name,
    required this.email,
  });

  @override
  State<_ConversationPanel> createState() => _ConversationPanelState();
}

class _ConversationPanelState extends State<_ConversationPanel> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _uploadingImages = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await FirestoreService.sendChatReply(widget.uid, text);
    _scrollToBottom();
  }

  Future<void> _pickAndSendImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;

    setState(() => _uploadingImages = true);
    try {
      final urls = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        urls.add(await CloudinaryService.uploadImage(bytes, file.name));
      }
      await FirestoreService.sendChatImages(widget.uid, urls);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingImages = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.email.isNotEmpty)
                Text(
                  widget.email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirestoreService.chatMessagesStream(widget.uid),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _scrollToBottom(),
              );
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final sender = data['sender'] as String? ?? 'customer';
                  final isMe = sender == 'employee';
                  final type = data['type'] as String? ?? 'text';
                  final text = data['text'] ?? '';
                  final imageUrls =
                      (data['imageUrls'] as List?)?.cast<String>() ?? const [];
                  final ts = data['timestamp'] as Timestamp?;
                  return LayoutBuilder(
                    builder: (context, msgConstraints) {
                      final maxBubbleWidth = (msgConstraints.maxWidth * 0.75)
                          .clamp(160.0, 480.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              const CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.border,
                                child: Icon(
                                  Icons.person_outline,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: maxBubbleWidth,
                              ),
                              child: Transform.translate(
                                offset: const Offset(0, -6),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    type == 'image'
                                        ? _ImageGrid(urls: imageUrls)
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isMe
                                                  ? AppColors.primary
                                                  : Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Text(
                                              text,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : AppColors.textPrimary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                    if (ts != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '${ts.toDate().hour}:${ts.toDate().minute.toString().padLeft(2, '0')}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 16, 16),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: _uploadingImages
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.image_outlined,
                        color: AppColors.primary,
                      ),
                onPressed: _uploadingImages ? null : _pickAndSendImages,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Type a reply...',
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _send,
                  child: const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<String> urls;
  const _ImageGrid({required this.urls});

  void _openViewer(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: SafeArea(
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: urls.length,
                itemBuilder: (_, i) => InteractiveViewer(
                  child: Image.network(urls[i], fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 20,
                right: 15,
                child: GestureDetector(
                  onTap: () => Navigator.of(dialogContext).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(urls.length, (i) {
        return GestureDetector(
          onTap: () => _openViewer(context, i),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              urls[i],
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const SizedBox(
                      width: 120,
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
