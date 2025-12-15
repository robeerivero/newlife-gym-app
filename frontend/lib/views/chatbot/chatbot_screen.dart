import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/chatbot_viewmodel.dart';

class ChatBotScreen extends StatefulWidget {
  final String section;
  const ChatBotScreen({Key? key, required this.section}) : super(key: key);

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return ChangeNotifierProvider(
      create: (_) => ChatBotViewModel(widget.section),
      child: Consumer<ChatBotViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Asistente NewLife - ${widget.section}'),
            ),
            body: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: vm.chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = vm.chatHistory[index];
                      return _buildChatBubble(context, message['text'], 
                          timestamp: message['timestamp'], isBot: message['isBot']);
                    },
                  ),
                ),
                _buildQuickActions(vm),
                _buildInputField(context, vm),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActions(ChatBotViewModel vm) {
    return Container(
      height: 50.h,
      margin: EdgeInsets.only(bottom: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: vm.quickOptions.length,
        itemBuilder: (context, index) {
          final option = vm.quickOptions[index];
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: ActionChip(
              label: Text(option),
              labelStyle: TextStyle(
                fontSize: 12.sp, 
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold
              ),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              onPressed: () {
                vm.processInput(option, () {
                  setState(() {});
                  _scrollToBottom();
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatBubble(BuildContext context, String text,
      {required DateTime timestamp, required bool isBot}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary,
              child: const Icon(Icons.bolt, size: 18, color: Colors.white), 
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : colorScheme.secondary,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isBot ? Radius.zero : const Radius.circular(18),
                  bottomRight: isBot ? const Radius.circular(18) : Radius.zero,
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      color: isBot ? Colors.black87 : Colors.white,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('HH:mm').format(timestamp),
                    style: TextStyle(
                      color: isBot ? Colors.grey[400] : Colors.white70,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isBot) SizedBox(width: 8.w),
        ],
      ),
    );
  }

  Widget _buildInputField(BuildContext context, ChatBotViewModel vm) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 34.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: vm.questionController,
              decoration: InputDecoration(
                hintText: 'Escribe tu duda...',
                filled: true,
                fillColor: colorScheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              ),
              onSubmitted: (_) => _sendMessage(vm),
            ),
          ),
          SizedBox(width: 10.w),
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(vm),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(ChatBotViewModel vm) {
    vm.processInput(vm.questionController.text, () {
      setState(() {});
      _scrollToBottom();
    });
  }
}